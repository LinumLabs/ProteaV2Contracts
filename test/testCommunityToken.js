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
    beforeEach('Init', async () => {
        rewardManager = await RewardManager.new({
            from: tokenOwnerAddress,
            gas: 6721975
        });

        communityToken = await CommunityToken.new({
            from: tokenOwnerAddress,
            gas: 6721975
        })

        eventManager = await EventManager.new({
            from: tokenOwnerAddress
        })
    })

    describe("Protea Token Functions", () => {


        it("Encode and Call event manager properly", async () => {

            // https://beresnev.pro/test-overloaded-solidity-functions-via-truffle/
            // Truffle unable to use overloaded functions, assuming target overload is last entry to the contract
            // Possible upgrade, include lodash to dynamically load abi function
            // console.log('ABI code', communityToken.contract.abi);
            // console.log('ABI code', eventManager.contract.abi);
            let transferAbi, rsvpAbi, createAbi;
            communityToken.contract.abi.find((abiObj) => {
                if(abiObj.name == 'transfer' && abiObj.type == 'function' && abiObj.inputs.length == 3){
                    transferAbi = abiObj;
                }
            })
            // Cant get abi for internal or private functions
            // eventManager.contract.abi.find((abiObj) => {
            //     if(abiObj.name == 'rsvp' && abiObj.type == 'function'){
            //         rsvpAbi = abiObj;
            //     }
            //     if(abiObj.name == 'createEvent' && abiObj.type == 'function'){
            //         createAbi = abiObj;
            //     }
            // });

            // console.log(transferAbi);
            rsvpAbi = {"constant":false,"inputs":[{"name":"_index","type":"uint256"},{"name":"_member","type":"address"}],"name":"rsvp","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
            createAbi = {"constant":false,"inputs":[{"name":"_name","type":"string"},{"name":"_date","type":"string"},{"name":"_location","type":"string"},{"name":"_participantLimit","type":"uint24"},{"name":"_organiser","type":"address"},{"name":"_requiredStake","type":"uint256"}],"name":"createEvent","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
            // let transferAbi = communityToken.contract.abi[communityToken.contract.abi.length - 1];
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


// ABI code [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
//   { constant: false,
//     inputs: [ [Object], [Object], [Object] ],
//     name: 'transfer',
//     outputs: [],
//     payable: false,
//     stateMutability: 'nonpayable',
//     type: 'function' } ]






    
// ABI code [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,
//   { constant: false,
//     inputs: [ [Object], [Object], [Object] ],
//     name: 'tokenFallback',
//     outputs: [],
//     payable: false,
//     stateMutability: 'nonpayable',
//     type: 'function' },
//   { constant: true,
//     inputs: [ [Object], [Object] ],
//     name: 'payout',
//     outputs: [ [Object] ],
//     payable: false,
//     stateMutability: 'view',
//     type: 'function' } ]