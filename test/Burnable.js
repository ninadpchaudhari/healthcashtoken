'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashToken = artifacts.require("./HealthCashToken.sol")

contract('HealthCash Token :: Burnable', function(accounts) {

  beforeEach(async function() {
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _totalSupply = 100
    let _decimals = 18
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)
  })

  it('should return the correct token total after burning', async function() {
    await this.token.burn(10, { from: accounts[0] })
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(90)
  })

  it('should return the correct balance after burning', async function() {
    await this.token.burn(10, { from: accounts[0] })
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(90)
  })

  it('should be unable to burn too many tokens', async function() {
    await this.token.burn(900, { from: accounts[0] })
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)
  })

})
