'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var FlatPricing = artifacts.require("./FlatPricing.sol")

contract('PricingStrategy :: Flat', function(accounts) {

  beforeEach(async function() {
    let oneTokenInWei = 1000000000000000000
    this.pricing = await FlatPricing.new(oneTokenInWei)
  })

  it('non-owner should not be able to adjust price', async function() {

    let tokens = await this.pricing.calculatePrice(50000000000000, 0, 0, accounts[0], 18)
    tokens.should.be.bignumber.equal(50000000000000)

  })

  it('non-owner should not be able to adjust price', async function() {

    await this.pricing.setTokenPrice(3000000000000000000, {from: accounts[1]})
    let tokens = await this.pricing.calculatePrice(5000000000000, 0, 0, accounts[0], 18)
    tokens.should.be.bignumber.equal(5000000000000)

  })

  it('owner should be able to adjust price', async function() {

    await this.pricing.setTokenPrice(3000000000000000000)
    let tokens = await this.pricing.calculatePrice(5000000000000, 0, 0, accounts[0], 18)
    tokens.should.be.bignumber.equal(1666666666666)

  })

})
