'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var PricingStrategy = artifacts.require("./TokenTranchePricing.sol")

contract('PricingStrategy :: Tranche', function(accounts) {

  beforeEach(async function() {
    let tranches = [0, 500000, 1000000, 700000, 2000000, 0]
    this.pricing = await PricingStrategy.new(tranches)
  })

  it('should be able to access multiple prices based on tokens purchased', async function() {

    let tokens = await this.pricing.calculatePrice(1000000, 0, 0, accounts[0], 5)
    tokens.should.be.bignumber.equal(200000)

    tokens = await this.pricing.calculatePrice(350000, 0, 1000001, accounts[0], 5)
    tokens.should.be.bignumber.equal(50000)

    tokens = await this.pricing.calculatePrice(1350000, 0, 2000001, accounts[0], 5)
    tokens.should.be.bignumber.equal(0)

  })

  it('should be able to specify specific price by address', async function() {

    await this.pricing.setPreicoAddress(accounts[0], 10); 
    let tokens = await this.pricing.calculatePrice(1000, 0, 0, accounts[0], 5)
    tokens.should.be.bignumber.equal(10000000)

  })

})
