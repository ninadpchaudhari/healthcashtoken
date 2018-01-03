var sale = artifacts.require("./AllocatedCrowdsaleMixin.sol")
var sale2 = artifacts.require("./Crowdsale.sol")
var hlth = artifacts.require("./HealthCashToken.sol")
var whitelist = artifacts.require("./Whitelist.sol")
var pricing = artifacts.require("./TokenTranchePricing.sol")

module.exports = function(deployer) {

  let gasLimit = web3.eth.getBlock("pending").gasLimit;
  
  deployer.deploy(sale2, 
                   hlth.address,
                   pricing.address,
                   web3.eth.accounts[0],
                   1517486400,
                   1518696000,
                   600000000000000000000,
                   web3.eth.accounts[0]);

};
