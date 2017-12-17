'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashToken = artifacts.require("./HealthCashToken.sol")

contract('HealthCash :: ReleasableToken', function(accounts) {

  beforeEach(async function() {
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _totalSupply = 100
    let _decimals = 18
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)
  })

  it('should return the correct totalSupply after construction', async function() {
    let totalSupply = await this.token.totalSupply()
    totalSupply.should.be.bignumber.equal(100)
  })

  it('should return the correct allowance amount after approval', async function() {
    await this.token.approve(accounts[1], 100)
    let allowance = await this.token.allowance(accounts[0], accounts[1])
    allowance.should.be.bignumber.equal(100)
  })

  it('should be unable to transfer due to lock', async function() {
    
    //transfer from valid agent
    await this.token.transfer(accounts[1], 20) 

    //try transfer from non-trasnfer agent
    await this.token.transfer(accounts[0], 20, {from: accounts[1]}) 

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(80)

  })

  it('should let transfer agents transfer', async function() {

    await this.token.transfer(accounts[1], 20)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(80)

    balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(20)
  })

  it('transfer agents should be unable to transfer more than balance', async function() {
 
    await this.token.transfer(accounts[1], 101)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100,'Should have failed to transfer tokens.')
  })

  it('should return correct balances after transfering from another account', async function() {

    await this.token.approve(accounts[1], 100)
    await this.token.transferFrom(accounts[0], accounts[1], 100, {from: accounts[1]})

    let balance0 = await this.token.balanceOf(accounts[0])
    balance0.should.be.bignumber.equal(0)

    let balance1 = await this.token.balanceOf(accounts[1])
    balance1.should.be.bignumber.equal(100)

  })

  it('should not allow transfering more than allowed', async function() {

    await this.token.approve(accounts[1], 99)
    await this.token.transferFrom(accounts[0], accounts[1], 100, {from: accounts[1]})

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)
  })

  it('should let everyone transfer after release', async function() {
    
    //Release the token
    await this.token.setReleaseAgent(accounts[0]) 
    await this.token.releaseTokenTransfer()

    await this.token.transfer(accounts[1], 20)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(80)

    balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(20)
  })


})
