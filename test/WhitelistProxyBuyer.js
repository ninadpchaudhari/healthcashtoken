'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var Whitelist = artifacts.require("./Whitelist.sol")  
var WhitelistProxyBuyer = artifacts.require("./WhitelistProxyBuyer.sol")
var Crowdsale = artifacts.require("./Crowdsale.sol")
var PricingStrategy = artifacts.require("./TokenTranchePricing.sol")
var ReleasingAgent = artifacts.require("./ReleasingFinalizeAgent.sol")
var HealthCashToken = artifacts.require("./HealthCashToken.sol")

contract('WhitelistProxyBuyer', function(accounts) {

    before(async function() {

    let owner = accounts[0]
    let freezeEndsAt = 1521720000
    let weiMinimumLimit = 1000000000000000000
    let weiMaximumLimit = 5000000000000000000
    let weiCap = 400000000000000000000

    this.whitelist = await Whitelist.new()
    this.proxybuyer = await WhitelistProxyBuyer.new(owner, freezeEndsAt, weiMinimumLimit, weiMaximumLimit, weiCap)

    //need token, crowdsale, pricing agent
    let tranches = [0, web3.toWei('1', 'gwei'), 500000000000000000000, 0]
    this.pricing = await PricingStrategy.new(tranches)

    //token
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _decimals = 18
    let _totalSupply = 1000 * 10 ** _decimals //1000 tokens
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)

    let wallet = accounts[1]
    let start = 1517908400
    let end = 1517918400
    let minimumFundingGoal = web3.toWei('250', 'gwei')
    let tokenOwner = accounts[0]
    this.sale = await Crowdsale.new(this.token.address, this.pricing.address, wallet, start, end, minimumFundingGoal, tokenOwner)

    //approve our crowdsale contract to sell half our tokens
    await this.token.approve(this.sale.address, 500 * 10 ** _decimals)

    //set whitelist
    await this.sale.setWhitelist(this.whitelist.address) 
    this.finalizer = await ReleasingAgent.new(this.token.address, this.sale.address)    
    await this.token.setReleaseAgent(this.finalizer.address)
    await this.sale.setFinalizeAgent(this.finalizer.address)

    await this.proxybuyer.setWhitelist(this.whitelist.address) 

  })

  it('should start in state Funding', async function() {

    let state = await this.proxybuyer.getState() 
    state.should.be.bignumber.equal(1)

  })


  it('should allow owner to change the WeiMinimumLimit', async function() {

    await this.proxybuyer.setWeiMinimumLimit(1000)
    let minLimit = await this.proxybuyer.weiMinimumLimit()
    minLimit.should.be.bignumber.equal(1000)

  })

  it('should allow owner to add to whitelist', async function() {

      let addresses = [accounts[0], accounts[1]]
      await this.whitelist.addToWhitelist(addresses)

      let isListed = await this.whitelist.verify(accounts[0])  
      isListed.should.be.equal(true)
  })

  it('should allow whitelisted address to contribute', async function() {

    let min = 100000;
    await this.proxybuyer.buy({from: accounts[1], value: min})
    let balance = await this.proxybuyer.balances(accounts[1])
    balance.should.be.bignumber.equal(min)

})

it('should allow owner to add crowdsale contract', async function() {

    //adding the crowdsale contract enables - buyForEverybody
    //don't add it until you're ready to buy the tokens
    await this.proxybuyer.setCrowdsale(this.sale.address)
    
    let wlpbCrowdsale = await this.proxybuyer.crowdsale();
    wlpbCrowdsale.should.equal(this.sale.address)
    
})

it('should allow anyone to call buyForEverybody()', async function() {


    //whitelist this contract
    await this.whitelist.addToWhitelist([this.proxybuyer.address])
    
    //set our price for whitelist purchase
    await this.pricing.setPreicoAddress(this.proxybuyer.address, 10000)

    //buy our tokens for everyone
    await this.proxybuyer.buyForEverybody()
    
    let state = await this.proxybuyer.getState()
    state.should.be.bignumber.equal(2)
    
})


it('contributors should be able to claim their tokens after the buy', async function() {

    //unlock freeze period
    await this.proxybuyer.setTimeLock(Math.round((new Date()).getTime() / 1000) - 10) //in the past
   
    //allow this contract to transfer tokens despite them being locked up 
    await this.token.setTransferAgent(this.proxybuyer.address, true) 

    //get our claimed amount
    let claim = await this.proxybuyer.getClaimLeft(accounts[1])
    await this.proxybuyer.claimAll({from: accounts[1]})

    //check out balance
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(claim)

})

})
