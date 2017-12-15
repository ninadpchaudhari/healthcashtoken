var hlth = artifacts.require("./HealthCashToken.sol")

module.exports = function(deployer) {
    let name = 'Health Cash'
    let symbol = 'HLTH'    
    let tokensupply = 200000000000000000000000000
    let decimals = 18
    deployer.deploy(hlth, name, symbol, tokensupply, decimals)
};
