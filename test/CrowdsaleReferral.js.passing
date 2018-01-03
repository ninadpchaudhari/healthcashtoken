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


contract('Crowdsale :: Referrals', function(accounts) {

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

  it('should start in State.Preparing', async function() {

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(1)  //preparing

  })

  it('adding a valid finalization agent should put it in State.Funding', async function() {

    await this.token.setReleaseAgent(this.finalizer.address)
    await this.sale.setFinalizeAgent(this.finalizer.address)

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(3)  //Funding

  })

  it('while in State.Funding, non-whitelisted addresses should not be able to purchase tokens', async function() {

    await this.sale.buy({from: accounts[1], value: web3.toWei('1', 'gwei')})
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(0)

  })

  it('while in State.Funding whitelisted addresses should be able to purchase tokens with referral ids', async function() {

    //approve our purchaser
    await this.whitelist.addToWhitelist([accounts[1]])

    //purchase some tokens
    await this.sale.buyWithReferral(7741, {from: accounts[1], value: web3.toWei('200', 'gwei')})
    
    let referrerCount = await this.sale.getReferrersCount()
    referrerCount.should.be.bignumber.equal(1)

    let referrerID = await this.sale.referrers(0)
    referrerID.should.be.bignumber.equal(7741)
   
    let totalReferred = await this.sale.referrals(7741)
    totalReferred.should.be.bignumber.equal(web3.toWei('200', 'gwei'))

    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(200000000000000000000)

    //purchase again, to test incrementing referral counter
    await this.sale.buyWithReferral(7741, {from: accounts[1], value: web3.toWei('300', 'gwei')})

    referrerCount = await this.sale.getReferrersCount()
    referrerCount.should.be.bignumber.equal(1)

    totalReferred = await this.sale.referrals(7741)
    totalReferred.should.be.bignumber.equal(web3.toWei('500', 'gwei'))

    mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(500000000000000000000)


  })


})
