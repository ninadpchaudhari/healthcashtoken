'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashToken = artifacts.require("./HealthCashToken.sol")
var Issuer = artifacts.require("./Issuer.sol")

contract('Issuer :: Token Distribution', function(accounts) {

  beforeEach(async function() {
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _totalSupply = 100
    let _decimals = 18
    this.token = await HealthCashToken.new(_name, _symbol, _totalSupply, _decimals)
    this.issuer = await  Issuer.new(accounts[0], accounts[0], this.token.address)
  })

  it('should allow issuer to issue some tokens', async function() {

    await this.token.setTransferAgent(accounts[0], true) 
    await this.token.approve(this.issuer.address, 100)
    await this.issuer.issue(accounts[1], 20)

    let balance0 = await this.token.balanceOf(accounts[0])
    balance0.should.be.bignumber.equal(80)

    let balance1 = await this.token.balanceOf(accounts[1])
    balance1.should.be.bignumber.equal(20)

  })

  it('should not allow issuer to issue more tokens than allowed', async function() {

    await this.token.setTransferAgent(accounts[0], true)
    await this.token.approve(this.issuer.address, 20)
    await this.issuer.issue(accounts[1], 100)

    let balance0 = await this.token.balanceOf(accounts[0])
    balance0.should.be.bignumber.equal(100)

    let balance1 = await this.token.balanceOf(accounts[1])
    balance1.should.be.bignumber.equal(0)

  })  

})
