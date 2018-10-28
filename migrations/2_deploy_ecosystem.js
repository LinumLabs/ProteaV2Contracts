var CommunityToken = artifacts.require("./CommunityToken.sol");
var EventManager = artifacts.require("./EventManager.sol");
var RewardManager = artifacts.require("./RewardManager.sol");


module.exports = async function (deployer, network, accounts) {
    await Promise.all([
        deployer.deploy(RewardManager),
        deployer.deploy(EventManager),
    ])   

    await deployer.deploy(CommunityToken, RewardManager.address, taxRate, 'CryptoLife', 18, 'xCL', 2,);
}
