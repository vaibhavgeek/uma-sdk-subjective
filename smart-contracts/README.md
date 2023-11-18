### What does initializeContent do?

Initalize Content is to be called by content creator (poster of the content), these are the values it takes. 

```
struct Content {
        bool resolved; // True if the content is in line with the criteria posted.
        bytes32 assertedOutcomeId; // Hash of asserted outcome (outcome1, outcome2 or unresolvable).
        ExpandedIERC20 outcome1Token; // ERC20 token representing the value of default Negation (Criteria)
        ExpandedIERC20 outcome2Token; // ERC20 token representing the value of default Tautology (Criteria)
        uint256 reward; // Reward available for voting right.
        uint256 requiredBond; // Expected bond to ensure criteria by poster.
        bytes outcome1; // Short name of the first outcome.
        bytes outcome2; // Short name of the second outcome.
        bytes criteria; // Criteria of the content.
        uint256 assertTreshold; // The treshold for the assertion. 
        uint256 valueTreshold; // Current value of Negation(Criteria)
        address[] token1yes; // All the people asserted Yes for the token
        address[] token2yes; // All the people asserted No for the token
    }

```

### What does assertContent do?
Any user can assertContent if they think it matches the criteria or not. They go for outcome1Token if they think
it does not matches the criteria. This increases valueTreshold by 1. If the assertContent increases by pre defined treshold, this gets escalated to the UMA holders for resolution, where they settleclaim and reward parties apporpiately. 

```
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
```


### What does assertionResolvedCallback do? 
It checks if the 


# Quickstart for Integrating with UMA Optimistic Oracle V3
<a href="https://docs.uma.xyz/developers/optimistic-oracle"><img alt="OO" src="https://miro.medium.com/v2/resize:fit:1400/1*hLSl9M87P80A1pZ9vuTvyA.gif" width=600></a>

This repository contains example contracts and tests for integrating with the UMA Optimistic Oracle V3.

## Documentation 📚

Full documentation on how to build, test, deploy and interact with the example contracts in this repository are
 documented [here](https://docs.uma.xyz/developers/optimistic-oracle).

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html)
 for instructions on how to install and use Foundry.

## Getting Started 👩‍💻

### Install dependencies 👷‍♂️

On Linux and macOS Foundry toolchain can be installed with:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

In case there was a prior version of Foundry installed, it is advised to update it with `foundryup` command.

Other installation methods are documented [here](https://book.getfoundry.sh/getting-started/installation).

Forge manages dependencies using [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) by default, which
 is also the method used in this repository. To install dependencies, run:

```bash
forge install
```

### Compile the contracts 🏗

Compile the contracts with:

```bash
forge build
```

## Sandboxed Optimistic Oracle environment 🚀

In order to experiment with the dispute flow on deployed example contracts, it might be useful to deploy a sandboxed
 Optimistic Oracle environment where dispute resolution is handled by a mock Oracle. This requires exporting following
 environment variables:
- `ETH_RPC_URL`: URL of the RPC node to use for broadcasting deployment transactions.
- `MNEMONIC`: Mnemonic of the account to use for deployment.
- `ETHERSCAN_API_KEY`: API key for Etherscan, used for verifying deployed contracts.
- `DEFAULT_IDENTIFIER`: Default identifier used by Optimistic Oracle V3 when resolving disputes. If not provided, this
 defaults to `ASSERT_TRUTH` identifier.
- `DEFAULT_LIVENESS`: Default liveness in seconds used by Optimistic Oracle V3 when settling assertions. If not
 provided, this defaults to `7200` seconds.
- `DEFAULT_CURRENCY`: Default currency used by Optimistic Oracle V3 when bonding assertions and disputes. If not
 provided, the script would also deploy a mintable ERC20 token and use it as the default currency based on following
 parameters:
  - `DEFAULT_CURRENCY_NAME`: Name of the new token. If not provided, this defaults to `Default Bond Token`.
  - `DEFAULT_CURRENCY_SYMBOL`: Symbol of the new token. If not provided, this defaults to `DBT`.
  - `DEFAULT_CURRENCY_DECIMALS`: Number of decimals of the new token. If not provided, this defaults to `18`.
- `MINIMUM_BOND`: Minimum bond amount in Wei of default currency required by Optimistic Oracle V3 when accepting new
 assertions. If not provided, this defaults to `100e18` Wei.

The sandboxed environment can be deployed and verified with:

```bash
forge script \
--broadcast \
--fork-url $ETH_RPC_URL \
--mnemonics "$MNEMONIC" \
--sender $(cast wallet address --mnemonic "$MNEMONIC") \
--verify \
script/OracleSandbox.s.sol
```

On other networks than Ethereum the verification might require additional `--verifier-url` parameter with URL of the
 verification API endpoint.

At the top of the script output the addresses of the deployed contracts should be logged. These will be required when
 deploying example contracts. Please see the [documentation](https://docs.uma.xyz/developers/optimistic-oracle)
 for more details on how to use this sandboxed environment.