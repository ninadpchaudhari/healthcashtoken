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


contract('Crowdsale :: Refunding', function(accounts) {

  before(async function() {

    //whitelist
    this.whitelist = await Whitelist.new()

    //pricing strategy
    let tranches = [0, web3.toWei('1', 'gwei'), 500000000000000000000, 0]
    this.pricing = await PricingStrategy.new(tranches)

    //token
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _decimals = 18
    let _totalSupply = 200000000 * 10 ** _decimals  //200 Million tokens
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)
    
    let wallet = accounts[1] //will be team multisig address at first
    let start = Math.round((new Date()).getTime() / 1000) + 6 //some date in the future 
    let end = 1517918400 // some date in the future beyond the start date
    let minimumFundingGoal = web3.toWei('1000', 'gwei') //set higher than needed to trigger refund
    let tokenOwner = accounts[0] //the tokens owner, in production will be the multisig wallet
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
   
    //This is because we set our start date only a few seconds into the future

    await this.token.setReleaseAgent(this.finalizer.address)
    await this.sale.setFinalizeAgent(this.finalizer.address)

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(3)  //Funding

  })

  it('while in State.Funding whitelisted addresses should be able to purchase tokens', async function() {

    //approve our purchaser
    await this.whitelist.addToWhitelist([accounts[1]])
    //purchase some tokens
    await this.sale.buy({from: accounts[1], value: web3.toWei('500', 'gwei')})
    
    let mytokens = await this.token.balanceOf(accounts[1])
    mytokens.should.be.bignumber.equal(500000000000000000000)

  })

  it('when tokens are all sold, but mimimum is not reached it should be in State.Failure', async function() {

    let tokensLeft = await this.sale.getTokensLeft()
    tokensLeft.should.be.bignumber.equal(0)

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(5)  //State.Failure
    
  })

  it('in State.Failure should have no balance, but accept refund deposits', async function() {

      let balance = await web3.eth.getBalance(this.sale.address)
      balance.should.be.bignumber.equal(0)

      let weiRaised = await this.sale.weiRaised()
      await this.sale.loadRefund({value: weiRaised})

      balance = await web3.eth.getBalance(this.sale.address)
      balance.should.be.bignumber.equal(weiRaised)
          
  })  

  it('once refunds are loaded it should be in State.Refunding', async function() {

    let state = await this.sale.getState() 
    state.should.be.bignumber.equal(7)  //State.Refunding
    
 })  

 it('When in State.Refunding contributors should be able to get a refund', async function() {

    let tx = await this.sale.refund({from: accounts[1]})
    tx.logs[0].args.weiAmount.should.be.bignumber.equal(web3.toWei('500', 'gwei'))
    
  })

})
