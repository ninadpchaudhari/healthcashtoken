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


contract('Crowdsale', function(accounts) {

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

  it('while in State.Funding whitelisted addresses should be able to purchase tokens', async function() {

    //approve our purchaser
    await this.whitelist.addToWhitelist([accounts[1]])
    //purchase some tokens
    await this.sale.buy({from: accounts[1], value: web3.toWei('500', 'gwei')})
    
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(500000000000000000000)

  })

  it('when tokens are all sold and minimum reached should be in State.Success', async function() {

    let tokensLeft = await this.sale.getTokensLeft()
    tokensLeft.should.be.bignumber.equal(0)

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(4)  //State.Success
    
  })

  it('When in State.Success tokens can not be traded', async function() {

    await this.token.transfer(accounts[0], 10000, {from: accounts[1]})

    //should not allow transfer
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(500000000000000000000)
    
  })

  it('After sale finalized tokens can be traded', async function() {

    await this.sale.finalize()
    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(6)  //State.Finalized
    
    await this.token.transfer(accounts[0], 500000000000000000000, {from: accounts[1]})

    //should allow transfer
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(0)
    
  })


})
