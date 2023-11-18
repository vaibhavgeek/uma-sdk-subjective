// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uma/core/contracts/common/implementation/AddressWhitelist.sol";
import "@uma/core/contracts/common/implementation/ExpandedERC20.sol";
import "@uma/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "@uma/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3CallbackRecipientInterface.sol";

// This contract allows to initialize prediction markets each having a pair of binary outcome tokens. Anyone can mint
// and burn the same amount of paired outcome tokens for the default payout currency. Trading of outcome tokens is
// outside the scope of this contract. Anyone can assert 3 possible outcomes (outcome 1, outcome 2 or split) that is
// verified through Optimistic Oracle V3. If the assertion is resolved true then holders of outcome tokens can settle
// them for the payout currency based on resolved market outcome.
contract UMASubjectiveSDK is OptimisticOracleV3CallbackRecipientInterface {
    using SafeERC20 for IERC20;

    struct Content {
        bool resolved; // True if the market has been resolved and payouts can be settled.
        bytes32 assertedOutcomeId; // Hash of asserted outcome (outcome1, outcome2 or unresolvable).
        ExpandedIERC20 outcome1Token; // ERC20 token representing the value of the first outcome.
        ExpandedIERC20 outcome2Token; // ERC20 token representing the value of the second outcome.
        uint256 reward; // Reward available for asserting true market outcome.
        uint256 requiredBond; // Expected bond to assert market outcome (OOv3 can require higher bond).
        bytes outcome1; // Short name of the first outcome.
        bytes outcome2; // Short name of the second outcome.
        bytes criteria; // Criteria of the content.
        uint256 assertTreshold; // The treshold for the assertion. 
        uint256 valueTreshold; // Current value of Negation
    }

    struct assertedContent {
        address asserter; // Address of the asserter used for reward payout.
        bytes32 contentId; // Identifier for markets mapping.
    }

    mapping(bytes32 => Content) public contents; // Maps marketId to Market struct.

    mapping(bytes32 => assertedContent) public asserts; // Maps assertionId to AssertedMarket.

    FinderInterface public immutable finder; // UMA protocol Finder used to discover other protocol contracts.
    IERC20 public immutable currency; // Currency used for all prediction markets.
    OptimisticOracleV3Interface public immutable oo;
    uint64 public constant assertionLiveness = 7200; // 2 hours.
    bytes32 public immutable defaultIdentifier; // Identifier used for all prediction markets.
    bytes public constant unresolvable = "Unresolvable"; // Name of the unresolvable outcome where payouts are split.

    event contentInitialized(
        bytes32 indexed contentId,
        string outcome1,
        string outcome2,
        string criteria,
        address outcome1Token,
        address outcome2Token,
        uint256 reward,
        uint256 requiredBond,
        uint256 disputeTreshold
    );
    event contentAsserted(bytes32 indexed marketId, string assertedOutcome, bytes32 indexed assertionId);
    event contentResolved(bytes32 indexed marketId);
    event TokensCreated(bytes32 indexed marketId, address indexed account, uint256 tokensCreated);
    event TokensRedeemed(bytes32 indexed marketId, address indexed account, uint256 tokensRedeemed);
    event TokensSettled(
        bytes32 indexed marketId,
        address indexed account,
        uint256 payout,
        uint256 outcome1Tokens,
        uint256 outcome2Tokens
    );

    constructor(
        address _finder,
        address _currency,
        address _optimisticOracleV3
    ) {
        finder = FinderInterface(_finder);
        require(_getCollateralWhitelist().isOnWhitelist(_currency), "Unsupported currency");
        currency = IERC20(_currency);
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
        defaultIdentifier = oo.defaultIdentifier();
    }

    function getMarket(bytes32 marketId) public view returns (Content memory) {
        return contents[marketId];
    }

    function initializeContent(
        string memory outcome1, // Short name of the first outcome.
        string memory outcome2, // Short name of the second outcome.
        string memory criteria, // Criteria to judge the post.
        uint256 reward, // Reward available for asserting true market outcome.
        uint256 requiredBond, // Bond from the contentCreator, this is a must. 
        uint256 disputeTreshold // Expected bond to assert market outcome (OOv3 can require higher bond).
    ) public returns (bytes32 contentId) {
        require(bytes(outcome1).length > 0, "Empty first outcome");
        require(bytes(outcome2).length > 0, "Empty second outcome");
        require(keccak256(bytes(outcome1)) != keccak256(bytes(outcome2)), "Outcomes are the same");
        require(bytes(criteria).length > 0, "Empty description");
        contentId = keccak256(abi.encode(block.number, criteria));
        require(contents[contentId].outcome1Token == ExpandedIERC20(address(0)), "Market already exists");
        // Create position tokens with this contract having minter and burner roles.
        ExpandedIERC20 outcome1Token = new ExpandedERC20(string(abi.encodePacked(outcome1, " Token")), "O1T", 18);
        ExpandedIERC20 outcome2Token = new ExpandedERC20(string(abi.encodePacked(outcome2, " Token")), "O2T", 18);
        outcome1Token.addMinter(address(this));
        outcome2Token.addMinter(address(this));
        outcome1Token.addBurner(address(this));
        outcome2Token.addBurner(address(this));

        contents[contentId] = Content({
            resolved: false,
            assertedOutcomeId: bytes32(0),
            outcome1Token: outcome1Token,
            outcome2Token: outcome2Token,
            reward: reward,
            requiredBond: requiredBond,
            outcome1: bytes(outcome1),
            outcome2: bytes(outcome2),
            criteria: bytes(criteria),
            assertTreshold: disputeTreshold,
            valueTreshold: uint256(0)
        });
        if (reward > 0) currency.safeTransferFrom(msg.sender, address(this), reward); // Pull bond from creator.

        emit contentInitialized(
            contentId,
            outcome1,
            outcome2,
            criteria,
            address(outcome1Token),
            address(outcome2Token),
            reward,
            requiredBond,
            disputeTreshold
        );
    }

    // Assert the market with any of 3 possible outcomes: names of outcome1, outcome2 or unresolvable.
    // Only one concurrent assertion per market is allowed.
    function assertContent(bytes32 contentId, string memory assertedOutcome) public returns (bytes32 assertionId) {
        Content storage content = contents[contentId];
        require(content.outcome1Token != ExpandedIERC20(address(0)), "Content does not exist");
        bytes32 assertedOutcomeId = keccak256(bytes(assertedOutcome));
        require(content.assertedOutcomeId == bytes32(0), "Assertion active or resolved");
        require(
            assertedOutcomeId == keccak256(content.outcome1) ||
                assertedOutcomeId == keccak256(content.outcome2) ||
                assertedOutcomeId == keccak256(unresolvable),
            "Invalid asserted outcome"
        );
        // Increase Counter for Treshold if asserted as OutCome1, Outcome1 is default for Negation of  
        // what criteria is being proposed
        if(assertedOutcomeId  == keccak256(content.outcome1)){
            content.valueTreshold = content.valueTreshold + 1;
        }

        if(content.valueTreshold > content.assertTreshold){
            content.assertedOutcomeId = assertedOutcomeId;
            uint256 minimumBond = oo.getMinimumBond(address(currency)); // OOv3 might require higher bond.
            uint256 bond = content.requiredBond > minimumBond ? content.requiredBond : minimumBond;
            bytes memory claim = _composeClaim(assertedOutcome, content.criteria);

            // Pull bond and make the assertion.
            currency.safeTransferFrom(msg.sender, address(this), bond);
            currency.safeApprove(address(oo), bond);
            assertionId = _assertTruthWithDefaults(claim, bond);

            // Store the asserter and contentId for the assertionResolvedCallback.
            asserts[assertionId] = assertedContent({ asserter: msg.sender, contentId: contentId });

            emit contentAsserted(contentId, assertedOutcome, assertionId);
        }
    }

    // Callback from settled assertion.
    // If the assertion was resolved true, then the asserter gets the reward and the market is marked as resolved.
    // Otherwise, assertedOutcomeId is reset and the market can be asserted again.
    function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) public {
        require(msg.sender == address(oo), "Not authorized");
        Content storage content = contents[asserts[assertionId].contentId];

        if (assertedTruthfully) {
            content.resolved = true;
            if (content.reward > 0) currency.safeTransfer(asserts[assertionId].asserter, content.reward);
            emit contentResolved(asserts[assertionId].contentId);
        } else content.assertedOutcomeId = bytes32(0);
        delete asserts[assertionId];
    }

    // Dispute callback does nothing.
    function assertionDisputedCallback(bytes32 assertionId) public {}

    // Mints pair of tokens representing the value of outcome1 and outcome2. Trading of outcome tokens is outside of the
    // scope of this contract. The caller must approve this contract to spend the currency tokens.
    function createOutcomeTokens(bytes32 marketId, uint256 tokensToCreate) public {
        Content storage market = contents[marketId];
        require(market.outcome1Token != ExpandedIERC20(address(0)), "Market does not exist");

        currency.safeTransferFrom(msg.sender, address(this), tokensToCreate);

        market.outcome1Token.mint(msg.sender, tokensToCreate);
        market.outcome2Token.mint(msg.sender, tokensToCreate);

        emit TokensCreated(marketId, msg.sender, tokensToCreate);
    }

    // Burns equal amount of outcome1 and outcome2 tokens returning settlement currency tokens.
    function redeemOutcomeTokens(bytes32 contentId, uint256 tokensToRedeem) public {
        Content storage content = contents[contentId];
        require(content.outcome1Token != ExpandedIERC20(address(0)), "Content does not exist");

        content.outcome1Token.burnFrom(msg.sender, tokensToRedeem);
        content.outcome2Token.burnFrom(msg.sender, tokensToRedeem);

        currency.safeTransfer(msg.sender, tokensToRedeem);

        emit TokensRedeemed(contentId, msg.sender, tokensToRedeem);
    }

    // If the market is resolved, then all of caller's outcome tokens are burned and currency payout is made depending
    // on the resolved market outcome and the amount of outcome tokens burned. If the market was resolved to the first
    // outcome, then the payout equals balance of outcome1Token while outcome2Token provides nothing. If the market was
    // resolved to the second outcome, then the payout equals balance of outcome2Token while outcome1Token provides
    // nothing. If the market was resolved to the split outcome, then both outcome tokens provides half of their balance
    // as currency payout.
    function settleOutcomeTokens(bytes32 contentId) public returns (uint256 payout) {
        Content storage content = contents[contentId];
        require(content.resolved, "Content not resolved");

        uint256 outcome1Balance = content.outcome1Token.balanceOf(msg.sender);
        uint256 outcome2Balance = content.outcome2Token.balanceOf(msg.sender);

        if (content.assertedOutcomeId == keccak256(content.outcome1)) payout = outcome1Balance;
        else if (content.assertedOutcomeId == keccak256(content.outcome2)) payout = outcome2Balance;
        else payout = (outcome1Balance + outcome2Balance) / 2;

        content.outcome1Token.burnFrom(msg.sender, outcome1Balance);
        content.outcome2Token.burnFrom(msg.sender, outcome2Balance);
        currency.safeTransfer(msg.sender, payout);

        emit TokensSettled(contentId, msg.sender, payout, outcome1Balance, outcome2Balance);
    }

    function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
        return AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
    }

    function _composeClaim(string memory outcome, bytes memory description) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "As of assertion timestamp ",
                ClaimData.toUtf8BytesUint(block.timestamp),
                ", the described prediction market outcome is: ",
                outcome,
                ". The market description is: ",
                description
            );
    }

    function _assertTruthWithDefaults(bytes memory claim, uint256 bond) internal returns (bytes32 assertionId) {
        assertionId = oo.assertTruth(
            claim,
            msg.sender, // Asserter
            address(this), // Receive callback in this contract.
            address(0), // No sovereign security.
            assertionLiveness,
            currency,
            bond,
            defaultIdentifier,
            bytes32(0) // No domain.
        );
    }
}
