const web3Abi = require('web3-eth-abi');

var EventManager = artifacts.require('./EventManager.sol');
var CommunityToken = artifacts.require('./CommunityToken.sol');
var RewardManager = artifacts.require('./RewardManager.sol');
const web3 = EventManager.web3;


contract('CommunityToken', accounts => {
  let polyBondToken1
      let communityToken,
        eventManager,
        rewardManager,
        tokenOwnerAddress,
        adminAddress,
        userAddress;

    tokenOwnerAddress = accounts[0];
    adminAddress = accounts[1];
    userAddress = accounts[2];
    before('Init', async () => {
        rewardManager = await RewardManager.new({
            from: tokenOwnerAddress,
            gas: 6721975
        });

        
        eventManager = await EventManager.new({
            from: tokenOwnerAddress
        })

        communityToken = await CommunityToken.new(rewardManager.address, 10, 'CryptoLife', 18, 'xCL', 1000, 2, {
            from: tokenOwnerAddress
        })

    })

  it('Is initiated correcly', async () => {
    const poolBalance = await communityToken.poolBalance.call()
    assert.equal(poolBalance, 0)
    const totalSupply = await communityToken.totalSupply.call()
    assert.equal(totalSupply, 0)
    const exponent = await communityToken.exponent.call()
    assert.equal(exponent, 2)
  })

  describe('Curve integral calulations', async () => {
    // priceToMint is the same as the internal function curveIntegral if
    // totalSupply and poolBalance is zero
    const testWithExponent = async exponent => {
      const tmpPolyToken = await EthPolynomialCurvedToken.new( 'oed curve', 18, 'OCU', exponent)
      let res
      let jsres
      let last = 0
      for (let i = 50000; i < 5000000; i += 50000) {
        res = (await communityToken.priceToMint.call(i)).toNumber()
        assert.isAbove(res, last, 'should calculate curveIntegral correcly ' + i)
        last = res
      }
    }
    it('works with exponent = 1', async () => {
      await testWithExponent(1)
    })
    it('works with exponent = 2', async () => {
      await testWithExponent(2)
    })
    it('works with exponent = 3', async () => {
      await testWithExponent(3)
    })
    it('works with exponent = 4', async () => {
      await testWithExponent(4)
    })
  })

  it('Can mint tokens with ether', async function() {
    let balance = await communityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const priceToMint1 = await communityToken.priceToMint.call(50)
    let tx = await communityToken.mint(50, {value: priceToMint1, from: user1})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    balance = await communityToken.balanceOf(user1)
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint1)
    const poolBalance1 = await communityToken.poolBalance.call()
    assert.equal(poolBalance1.toNumber(), priceToMint1.toNumber(), 'poolBalance should be correct')

    const priceToMint2 = await communityToken.priceToMint.call(50)
    assert.isAbove(priceToMint2.toNumber(), priceToMint1)
    tx = await communityToken.mint(50, {value: priceToMint2, from: user2})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount minted should be 50')
    assert.equal(tx.logs[0].args.totalCost.toNumber(), priceToMint2)
    const poolBalance2 = await communityToken.poolBalance.call()
    assert.equal(poolBalance2.toNumber(), priceToMint1.toNumber() + priceToMint2.toNumber(), 'poolBalance should be correct')

    const totalSupply = await communityToken.totalSupply.call()
    assert.equal(totalSupply.toNumber(), 100)

    let didThrow = false
    const priceToMint3 = await communityToken.priceToMint.call(50)
    try {
      tx = await communityToken.mint(50, {value: priceToMint3.toNumber() - 1, from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('should not be able to burn tokens user dont have', async () => {
    let didThrow = false
    try {
      tx = await communityToken.burn(80, {from: user2})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('Can burn tokens and receive ether', async () => {
    const poolBalance1 = await communityToken.poolBalance.call()
    const totalSupply1 = await communityToken.totalSupply.call()

    let reward1 = await communityToken.rewardForBurn.call(50)
    let tx = await communityToken.burn(50, {from: user1})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[0].args.reward.toNumber(), reward1)
    let balance = await communityToken.balanceOf(user1)
    assert.equal(balance.toNumber(), 0)

    const poolBalance2 = await communityToken.poolBalance.call()
    assert.equal(poolBalance2.toNumber(), poolBalance1.toNumber() - reward1.toNumber())
    const totalSupply2 = await communityToken.totalSupply.call()
    assert.equal(totalSupply2.toNumber(), totalSupply1.toNumber() - 50)

    let reward2 = await communityToken.rewardForBurn.call(50)
    tx = await communityToken.burn(50, {from: user2})
    assert.equal(tx.logs[0].args.amount.toNumber(), 50, 'amount burned should be 50')
    assert.equal(tx.logs[0].args.reward.toNumber(), reward2)
    balance = await communityToken.balanceOf(user2)
    assert.equal(balance.toNumber(), 0)
    assert.isBelow(reward2.toNumber(), reward1.toNumber())

    const poolBalance3 = await communityToken.poolBalance.call()
    assert.equal(poolBalance3.toNumber(), 0)
    const totalSupply3 = await communityToken.totalSupply.call()
    assert.equal(totalSupply3.toNumber(), 0)
  })
})


// contract('CommunityToken', (accounts) => {
//     let communityToken,
//         eventManager,
//         rewardManager,
//         tokenOwnerAddress,
//         adminAddress,
//         userAddress;

//     tokenOwnerAddress = accounts[0];
//     adminAddress = accounts[1];
//     userAddress = accounts[2];
//     beforeEach('Init', async () => {
//         rewardManager = await RewardManager.new({
//             from: tokenOwnerAddress,
//             gas: 6721975
//         });

//         communityToken = await CommunityToken.new({
//             from: tokenOwnerAddress,
//             gas: 6721975
//         })

//         eventManager = await EventManager.new({
//             from: tokenOwnerAddress
//         })

//         await communityToken.init(rewardManager.address, 10, 'CryptoLife', 18, 'xCL', 1000, 2)
//     })

//     describe("Protea Token Functions", () => {


//         it("Encode and Call event manager properly", async () => {

//             // https://beresnev.pro/test-overloaded-solidity-functions-via-truffle/
//             // Truffle unable to use overloaded functions, assuming target overload is last entry to the contract
//             // Possible upgrade, include lodash to dynamically load abi function
//             // console.log('ABI code', communityToken.contract.abi);
//             // console.log('ABI code', eventManager.contract.abi);
//             let transferAbi, rsvpAbi, createAbi;
//             communityToken.contract.abi.find((abiObj) => {
//                 if(abiObj.name == 'transfer' && abiObj.type == 'function' && abiObj.inputs.length == 3){
//                     transferAbi = abiObj;
//                 }
//             })
//             // Cant get abi for internal or private functions
//             // eventManager.contract.abi.find((abiObj) => {
//             //     if(abiObj.name == 'rsvp' && abiObj.type == 'function'){
//             //         rsvpAbi = abiObj;
//             //     }
//             //     if(abiObj.name == 'createEvent' && abiObj.type == 'function'){
//             //         createAbi = abiObj;
//             //     }
//             // });

//             // console.log(transferAbi);
//             rsvpAbi = {"constant":false,"inputs":[{"name":"_index","type":"uint256"},{"name":"_member","type":"address"}],"name":"rsvp","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
//             createAbi = {"constant":false,"inputs":[{"name":"_name","type":"string"},{"name":"_date","type":"string"},{"name":"_location","type":"string"},{"name":"_participantLimit","type":"uint24"},{"name":"_organiser","type":"address"},{"name":"_requiredStake","type":"uint256"}],"name":"createEvent","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
//             const transferMethodTransactionData = web3Abi.encodeFunctionCall(
//                 transferAbi, [
//                     eventManager.address,
//                     issuingAmount,
//                     web3.toHex("0x00aaff") // Need the Create event call here
//                 ]
//             );
            
//             // Begin creating custom transaction call
//             const transferMethodTransactionData = web3Abi.encodeFunctionCall(
//                 transferAbi, [
//                     eventManager.address,
//                     issuingAmount,
//                     web3.toHex("0x00aaff") // Need the Create event call here
//                 ]
//             );

//             console.log(transferMethodTransactionData);
          
//             await web3.eth.sendTransaction({
//                 from: userAddress,
//                 gas: 170000,
//                 to: erc223Contract.address,
//                 data: transferMethodTransactionData,
//                 value: 0
//             });

//         });
//     })
   

// });


// // ABI code [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
// //   { constant: false,
// //     inputs: [ [Object], [Object], [Object] ],
// //     name: 'transfer',
// //     outputs: [],
// //     payable: false,
// //     stateMutability: 'nonpayable',
// //     type: 'function' } ]






    
// // ABI code [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,
// //   { constant: false,
// //     inputs: [ [Object], [Object], [Object] ],
// //     name: 'tokenFallback',
// //     outputs: [],
// //     payable: false,
// //     stateMutability: 'nonpayable',
// //     type: 'function' },
// //   { constant: true,
// //     inputs: [ [Object], [Object] ],
// //     name: 'payout',
// //     outputs: [ [Object] ],
// //     payable: false,
// //     stateMutability: 'view',
// //     type: 'function' } ]