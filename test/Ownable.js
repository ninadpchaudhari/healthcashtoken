const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCashToken.sol")

contract('HealthCash Token :: Ownable', function(accounts) {

  beforeEach(async function() {
    let _name = 'Health Cash'
    let _symbol = 'HLTH'
    let _totalSupply = 100
    let _decimals = 18
    this.ownable = await HealthCash.new(_name, _symbol, _totalSupply, _decimals)
  })

  it('should have an owner', async function() {
    let owner = await this.ownable.owner()
    owner.should.not.be.equal(0)    
  })

  it('changes owner after transfer', async function() {
    let other = accounts[1]
    await this.ownable.transferOwnership(other)
    let owner = await this.ownable.owner();

    owner.should.be.equal(other)    
  })

  it('should prevent non-owners from transfering', async function() {
    const other = accounts[1]
    let owner = await this.ownable.owner.call()
    owner.should.not.be.equal(other)    

    await this.ownable.transferOwnership(other, {from: other})
    owner = await this.ownable.owner.call()

    owner.should.not.be.equal(other)
  })

  it('should guard ownership against stuck state', async function() {
    let originalOwner = await this.ownable.owner()
    await this.ownable.transferOwnership(null, {from: originalOwner})
    let newOwner = await this.ownable.owner()

    newOwner.should.be.equal(originalOwner)
  })

})
