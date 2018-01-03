'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var Whitelist = artifacts.require("./Whitelist.sol")  
var Crowdsale = artifacts.require("./Crowdsale.sol")
var PricingStrategy = artifacts.require("./TokenTranchePricing.sol")
var ReleasingAgent = artifacts.require("./ReleasingFinalizeAgent.sol")
var HealthCashToken = artifacts.require("./HealthCashToken.sol")


contract('Crowdsale :: Presale Allocation', function(accounts) {

  before(async function() {

    //whitelist
    this.whitelist = await Whitelist.new()

    //pricing strategy
    let tranches = [0, web3.toWei('1', 'gwei'), 500000000000000000000, 0]
    this.pricing = await PricingStrategy.new(tranches)

    //token
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _totalSupply = 1000000000000000000000  //1000 tokens
    let _decimals = 18
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)

    let wallet = accounts[1]
    let start = Math.round((new Date()).getTime() / 1000) + 6
    let end = 1517918400
    let minimumFundingGoal = web3.toWei('250', 'gwei')
    let tokenOwner = accounts[0]
    this.sale = await Crowdsale.new(this.token.address, this.pricing.address, wallet, start, end, minimumFundingGoal, tokenOwner)

    //set whitelist
    await this.sale.setWhitelist(this.whitelist.address) 
    this.finalizer = await ReleasingAgent.new(this.token.address, this.sale.address)
    
    //approve our whitelist contract to sell half our tokens
    await this.token.approve(this.sale.address, 500000000000000000000)

  })

  it('Should be able to preallocate tokens for presale purchases', async function() {

    await this.sale.preallocate(accounts[1], 5, 600)
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(5 * 10 ** 18)


  })



  


})
