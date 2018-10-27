const web3Abi = require('web3-eth-abi');

var EventManager = artifacts.require('./EventManager.sol');
var CommunityToken = artifacts.require('./CommunityToken.sol');
var RewardManager = artifacts.require('./RewardManager.sol');
const web3 = EventManager.web3;


contract('CommunityToken', (accounts) => {
    let communityToken,
        eventManager,
        rewardManager,
        tokenOwnerAddress,
        adminAddress,
        userAddress;

    tokenOwnerAddress = accounts[0];
    adminAddress = accounts[1];
    userAddress = accounts[2];
    beforeEach('', async () => {
        communityToken = await CommunityToken.new({
            from: tokenOwnerAddress,
        })

        rewardManager = await RewardManager.new({
            from: tokenOwnerAddress
        });

        eventManager = await EventManager.new({
            from: tokenOwnerAddress
        })
    })

    describe("Protea Token Functions", () => {


        it("Encode and Call event manager properly", async () => {

            // https://beresnev.pro/test-overloaded-solidity-functions-via-truffle/
            // Truffle unable to use overloaded functions, assuming target overload is last entry to the contract
            // Possible upgrade, include lodash to dynamically load abi function
            console.log('ABI code', CommunityToken.contract.abi);
            console.log('ABI code', EventManager.contract.abi);
            let transferAbi = CommunityToken.contract.abi[communityToken.contract.abi.length - 1];
            // const transferMethodTransactionData = web3Abi.encodeFunctionCall(
            //     transferAbi, [
            //         eventManager.address,
            //         issuingAmount,
            //         web3.toHex("0x00aaff") // Need the Create event call here
            //     ]
            // );
            
            // Begin creating custom transaction call
            const transferMethodTransactionData = web3Abi.encodeFunctionCall(
                transferAbi, [
                    eventManager.address,
                    issuingAmount,
                    web3.toHex("0x00aaff") // Need the Create event call here
                ]
            );

            console.log(transferMethodTransactionData);
          
            await web3.eth.sendTransaction({
                from: userAddress,
                gas: 170000,
                to: erc223Contract.address,
                data: transferMethodTransactionData,
                value: 0
            });

        });
    })
   

});
