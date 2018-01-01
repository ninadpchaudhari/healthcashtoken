var hlth = artifacts.require("./HealthCashToken.sol")
var whitelistPB = artifacts.require("./WhitelistProxyBuyer.sol")
var whitelist = artifacts.require("./Whitelist.sol")

module.exports = function(deployer) {
    let name = 'Health Cash'
    let symbol = 'HLTH'    
    let tokensupply = 200000000000000000000000000
    let decimals = 18
    deployer.deploy(hlth, name, symbol, tokensupply, decimals)


    let owner = web3.eth.accounts[0]
    let freezeEndsAt = 1521720000
    let weiMinimumLimit = 1000000000000000000
    let weiMaximumLimit = 5000000000000000000
    let weiCap = 400000000000000000000
    deployer.deploy(whitelistPB, owner, freezeEndsAt, weiMinimumLimit, weiMaximumLimit, weiCap)

    deployer.deploy(whitelist)


};
