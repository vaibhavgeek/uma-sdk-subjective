### Deployed Contract Address
https://mumbai.polygonscan.com/address/0x99bda3309830ddC444D8Fc82423675b0613a446F#writeContract

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
It checks if the assertion in in tune with the criteria and if that is case then it awards the
people who voted according to the same criteria. 

```
 function assertionResolvedCallback(bytes32 assertionId, bool assertedTruthfully) public {
        require(msg.sender == address(oo), "Not authorized");
        Content storage content = contents[asserts[assertionId].contentId];

        if (assertedTruthfully) {
            content.resolved = true;
            if (content.reward > 0) {
                 uint256 rewardPerRecipient = content.reward / content.token1yes.length;
                 require(rewardPerRecipient > 0, "Reward too small to distribute");
                 // Transfer the reward to each recipient
                 for (uint256 i = 0; i < content.token1yes.length; i++) {
                    currency.safeTransfer(content.token1yes[i], rewardPerRecipient);
                    }
                }
            emit contentResolved(asserts[assertionId].contentId);
        } else content.assertedOutcomeId = bytes32(0);
        delete asserts[assertionId];
    }
```

### How do I deploy contracts? 
```
forge script \
--broadcast \
--fork-url  \
--private-key "" \
--verify \
script/OracleSandbox.s.sol
``` 

```
forge create --rpc-url   \
--private-key "" \
 src/UMASubjectiveDK.sol:UMASubjectiveSDK --constructor-args 
```

```
 forge verify-contract --chain-id 80001 --etherscan-api-key  UMASubjectiveSDK --compiler-version 0.8.16 --constructor-args-path constructor-args.txt --watch
```

### Transaction Hash (Mumbai Testnet)
Waiting for receipts.
⠠ [00:00:24] [###########################################] 15/15 receipts (0.0s)
##### mumbai
✅  [Success]Hash: 0xc950fd06148e48006e9b4b9b56a57f0043863be8aa6465bd4f244adfca8be1fa
Contract Address: 0x6193d0673b7Cd6771BC45D5aCfcb3342D0106bD5
Block: 42563744
Paid: 0.001341833540938484 ETH (285109 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xf033a4be0429118a49c6985faec72a8a13149872b24a409307c98b88857e4d08
Contract Address: 0x9b0514E47903077E722991c3f70128198EfEC990
Block: 42563744
Paid: 0.007345339566667092 ETH (1560717 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x74e21318fc420cd904ac67e5aa4705baf6166b79b6f7fb1bb9845e737651dfe1
Contract Address: 0x6E80a5855C1e35c340eC9f8eaC823001a47554e6
Block: 42563744
Paid: 0.002556872286109652 ETH (543277 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xb15d82d3e9bcbda57d8c52c441435fa6b33288d691dbd408d52aa6d34a42a436
Contract Address: 0x6e8edfc98316663be7a4eA3e049A90D88777D3fD
Block: 42563744
Paid: 0.001272969673536852 ETH (270477 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x6a2f7d70269bf6df8a25ba0391429062e1486db391efaf1d3d511d77424032b9
Contract Address: 0x995b3AEeE12dCB9AC703746442f9563A38298985
Block: 42563744
Paid: 0.00489127832370866 ETH (1039285 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x9eefb0a70ef1d909f672a0b987d164d40bffde89614d35ff7c02c192481f56b6
Contract Address: 0x88Deee994c937b2d2a9Fa4B3CdB96834471C0471
Block: 42563744
Paid: 0.003044943534402356 ETH (646981 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x868b15efc70972492337d66dfa95a2e2acd85266f5caec8f637b7b774318d197
Block: 42563744
Paid: 0.000225214779030228 ETH (47853 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xa44943870a05c7a77314b52dd8bbc7270a99a64d5d4e3094d808868ed2489e21
Block: 42563744
Paid: 0.000226005452193396 ETH (48021 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xe555aeb264d618fa68c9fe5b01a8a76079d1ca058d9a0ae4cb58f229687630f7
Block: 42563744
Paid: 0.000226005452193396 ETH (48021 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xba245097b576b788e57a151f02e613f13dec580aa25985b24250956f2108cf60
Block: 42563744
Paid: 0.00022527125568474 ETH (47865 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x715084a0906dff56004b0bba4eceb7b876093f3720d5bac544e851ca03e1bdac
Block: 42563744
Paid: 0.000436338632759712 ETH (92712 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0x2c225d7ee049c34bd39752407bfbe463122020c97634d323cc76140b45c85beb
Block: 42563744
Paid: 0.00022230623132286 ETH (47235 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xffc663d6eedbccffa08fd111c3a9b44b070b1c632cf4b442035259c3a0fcf0f6
Block: 42563744
Paid: 0.000234829929460896 ETH (49896 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xb47b859438f60d92de6f26bb3dbf30b63dc3f4a75f72e93d8240f7c10929f828
Contract Address: 0x76E6b6feB4871bF60b3BFcC5AE31fAba444c64BF
Block: 42563744
Paid: 0.015125643500834104 ETH (3213854 gas * 4.706387876 gwei)


##### mumbai
✅  [Success]Hash: 0xadb8d8f4fe63b852d240be97d4ac3dd11115a044156913bcc6e3c1b7f23e5ea9
Block: 42563744
Paid: 0.000225948975538884 ETH (48009 gas * 4.706387876 gwei)
