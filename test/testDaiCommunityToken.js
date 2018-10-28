const web3Abi = require('web3-eth-abi');

var EventManager = artifacts.require('./EventManager.sol');
var DaiCommunityToken = artifacts.require('./DaiCommunityToken.sol');
var PseudoDaiToken = artifacts.require('./PseudoDaiToken.sol');
var RewardManager = artifacts.require('./RewardManager.sol');
const web3 = EventManager.web3;


contract('DaiCommunityToken', accounts => {
  let polyBondToken1
      let daiCommunityToken,
        pseudoDaiToken,
        eventManager,
        rewardManager,
        tokenOwnerAddress,
        adminAddress,
        userAddress;
    let taxRate = 10;
    tokenOwnerAddress = accounts[0];
    adminAddress = accounts[1];
    userAddress = accounts[2];

    let creationStake = 20;
    before('Init', async () => {
        rewardManager = await RewardManager.new({
            from: tokenOwnerAddress,
            gas: 6721975
        });

        pseudoDaiToken = await PseudoDaiToken.new("PseudoDai", "pDai", 18, {
          from: tokenOwnerAddress
        })

        eventManager = await EventManager.new({
            from: tokenOwnerAddress
        })
        daiCommunityToken = await DaiCommunityToken.new(rewardManager.address, taxRate, 'CryptoLife', 18, 'xCL', 2, pseudoDaiToken.address, {
            from: tokenOwnerAddress
        })

        await eventManager.initContract(daiCommunityToken.address, rewardManager.address, 20, 5, {from: tokenOwnerAddress})

    })

  it('Is initiated correcly', async () => {
    const poolBalance = await daiCommunityToken.poolBalance.call()
    assert.equal(poolBalance, 0)
    const totalSupply = await daiCommunityToken.totalSupply.call()
    assert.equal(totalSupply, 0)
    const exponent = await daiCommunityToken.exponent.call()
    assert.equal(exponent, 2)
  })

  describe('Curve integral calulations', async () => {
    // priceToMint is the same as the internal function curveIntegral if
    // totalSupply and poolBalance is zero
    const testWithExponent = async exponent => {
      const tmpPolyToken = await DaiCommunityToken.new(rewardManager.address, taxRate, 'CryptoLife', 18, 'xCL', 2, pseudoDaiToken.address)
      let res
      let jsres
      let last = 0
      for (let i = 50000; i < 5000000; i += 50000) {
        res = (await tmpPolyToken.priceToMint.call(i)).toNumber()
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

  it('Can mint tokens with sorta-dai', async function() {
    let balance = await daiCommunityToken.balanceOf(tokenOwnerAddress)
    assert.equal(balance.toNumber(), 0)

    const priceToMint1 = await daiCommunityToken.priceToMint.call(50)
    let tx = await daiCommunityToken.mint(50, {from: tokenOwnerAddress})
    assert.equal(tx.logs[1].args.amount.toNumber(), 50, 'amount minted should be 50')
    balance = await daiCommunityToken.balanceOf(tokenOwnerAddress)
    assert.equal(tx.logs[1].args.totalCost.toNumber(), priceToMint1.toNumber())

    const poolBalance1 = await daiCommunityToken.poolBalance.call()
    assert.equal(poolBalance1.toNumber(), priceToMint1.toNumber(), 'poolBalance should be correct')

    const priceToMint2 = await daiCommunityToken.priceToMint.call(50)
    assert.isAbove(priceToMint2.toNumber(), priceToMint1.toNumber())
    tx = await daiCommunityToken.mint(50, {from: adminAddress})
    balance = await daiCommunityToken.balanceOf(adminAddress)
    assert.equal(tx.logs[1].args.amount.toNumber(), 50, 'amount minted should be 50')
    assert.equal(tx.logs[1].args.totalCost.toNumber(), priceToMint2.toNumber())
    const poolBalance2 = await daiCommunityToken.poolBalance.call()
    assert.equal(poolBalance2.toNumber(), priceToMint1.toNumber() + priceToMint2.toNumber(), 'poolBalance should be correct')

    const totalSupply = await daiCommunityToken.totalSupply.call()
    assert.equal(totalSupply.toNumber(), 100)
  })

  it('should not be able to burn tokens user dont have', async () => {
    let didThrow = false
    try {
      tx = await daiCommunityToken.burn(80, {from: tokenOwnerAddress})
    } catch (e) {
      didThrow = true
    }
    assert.isTrue(didThrow)
  })

  it('Can burn tokens and receive ether', async () => {
    const poolBalance1 = await daiCommunityToken.poolBalance.call()
    const totalSupply1 = await daiCommunityToken.totalSupply.call()
    let balance = await daiCommunityToken.balanceOf(tokenOwnerAddress)

    let reward1 = await daiCommunityToken.rewardForBurn.call(balance.toNumber())
    let tx = await daiCommunityToken.burn(balance.toNumber(), {from: tokenOwnerAddress})
    assert.equal(tx.logs[1].args.amount.toNumber(), balance.toNumber(), 'amount burned should be 45(CAT tax 10%)')
    assert.equal(tx.logs[1].args.reward.toNumber(), reward1.toNumber())
    balance = await daiCommunityToken.balanceOf(tokenOwnerAddress)
    assert.equal(balance.toNumber(), 0)

    const poolBalance2 = await daiCommunityToken.poolBalance.call()
    assert.equal(poolBalance2.toNumber(), poolBalance1.toNumber() - reward1.toNumber())
    const totalSupply2 = await daiCommunityToken.totalSupply.call()
    assert.equal(totalSupply2.toNumber(), totalSupply1.toNumber() - 45)

    balance = await daiCommunityToken.balanceOf(adminAddress)
    let reward2 = await daiCommunityToken.rewardForBurn.call(balance.toNumber())
    tx = await daiCommunityToken.burn(balance.toNumber(), {from: adminAddress})
    assert.equal(tx.logs[1].args.amount.toNumber(), balance.toNumber(), 'amount burned should be 45')
    assert.equal(tx.logs[1].args.reward.toNumber(), reward2.toNumber())
    balance = await daiCommunityToken.balanceOf(adminAddress)
    assert.equal(balance.toNumber(), 0)
    assert.isBelow(reward2.toNumber(), reward1.toNumber())

    const poolBalance3 = await daiCommunityToken.poolBalance.call()
    const totalSupply3 = await daiCommunityToken.totalSupply.call()
    rewardPotBalance = await daiCommunityToken.balanceOf(rewardManager.address)
    let potValue = await daiCommunityToken.rewardForBurn.call(rewardPotBalance.toNumber())
    assert.equal(poolBalance3.toNumber(), potValue)
    assert.equal(totalSupply3.toNumber(), rewardPotBalance.toNumber())
  })

  it("Encode and Call event manager properly", async () =>{
    const priceToMint1 = await daiCommunityToken.priceToMint.call(50)
    let tx = await daiCommunityToken.mint(50, {from: tokenOwnerAddress})
    assert.equal(tx.logs[1].args.amount.toNumber(), 50, 'amount minted should be 50')
    balance = await daiCommunityToken.balanceOf(tokenOwnerAddress)
    assert.equal(tx.logs[1].args.totalCost.toNumber(), priceToMint1.toNumber())

    // https://beresnev.pro/test-overloaded-solidity-functions-via-truffle/
    // Truffle unable to use overloaded functions, assuming target overload is last entry to the contract
    // Possible upgrade, include lodash to dynamically load abi function
    let transferAbi, rsvpAbi, createAbi;
    daiCommunityToken.contract.abi.find((abiObj) => {
        if(abiObj.name == 'transfer' && abiObj.type == 'function' && abiObj.inputs.length == 3){
            transferAbi = abiObj;
        }
    })
    // Cant get abi for internal or private functions
    eventManager.contract.abi.find((abiObj) => {
        if(abiObj.name == 'rsvp' && abiObj.type == 'function'){
            rsvpAbi = abiObj;
        }
        if(abiObj.name == 'createEvent' && abiObj.type == 'function'){
            createAbi = abiObj;
        }
    })
    console.log(transferAbi);
    rsvpAbi = {"constant":false,"inputs":[{"name":"_index","type":"uint256"},{"name":"_member","type":"address"}],"name":"rsvp","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
    createAbi = {"constant":false,"inputs":[{"name":"_name","type":"string"},{"name":"_date","type":"string"},{"name":"_location","type":"string"},{"name":"_participantLimit","type":"uint24"},{"name":"_organiser","type":"address"},{"name":"_requiredStake","type":"uint256"}],"name":"createEvent","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}
    const createEncoded = web3Abi.encodeFunctionCall(
      createAbi, [
            "Protea at Cryptolife",
            "28-10-2018",
            "Prague",
            creationStake,
            tokenOwnerAddress,
            2
        ]
    );
      
    // Begin creating custom transaction call
    const transferMethodTransactionData = web3Abi.encodeFunctionCall(
        transferAbi, [
            eventManager.address,
            creationStake,
            "0x9e764f3e00000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000140000000000000000000000008ead0a3b1d14dea1164d1ecb06ffbf047663e14e0000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000001550726f746561204461692043727970746f6c6966650000000000000000000000000000000000000000000000000000000000000000000000000000000000000a32382d31302d323031380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065072616775650000000000000000000000000000000000000000000000000000" // Need the Create event call here
        ]
    );


    await web3.eth.sendTransaction({
      from: userAddress,
      gas: 170000,
      to: daiCommunityToken.address,
      data: transferMethodTransactionData,
      value: 0
    })
  })
})
