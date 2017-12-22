'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var WhitelistProxyBuyer = artifacts.require("./WhitelistProxyBuyer.sol")

contract('WhitelistProxyBuyer :: Basic', function(accounts) {

  beforeEach(async function() {
    let owner = accounts[0]
    let freezeEndsAt = 1521720000
    let weiMinimumLimit = 1000000000000000000
    let weiMaximumLimit = 5000000000000000000
    let weiCap = 400000000000000000000
    this.whitelist = await WhitelistProxyBuyer.new(owner, freezeEndsAt, weiMinimumLimit, weiMaximumLimit, weiCap)
  })

  it('should start in state Funding', async function() {

    let state = await this.whitelist.getState() 
    state.should.be.bignumber.equal(1)

  })


  it('should allow owner to change the WeiMinimumLimit', async function() {

    await this.whitelist.setWeiMinimumLimit(1000)
    let minLimit = await this.whitelist.weiMinimumLimit()
    minLimit.should.be.bignumber.equal(1000)

  })

  it('should allow owner to add to whitelist', async function() {

      let addresses = [accounts[0], accounts[1]]
      await this.whitelist.addToWhitelist(addresses)

      let isListed = await this.whitelist.isWhitelisted(accounts[0])  
      isListed.should.be.equal(true)
  })

  it('should allow whitelisted address to contribute', async function() {

    let min = 1000000000000000000;
    let addresses = [accounts[0], accounts[1]]
    await this.whitelist.addToWhitelist(addresses)
    await this.whitelist.buy({from: accounts[0], value: min})
    let balance = await this.whitelist.balances(accounts[0])
    balance.should.be.bignumber.equal(min)

})


})
