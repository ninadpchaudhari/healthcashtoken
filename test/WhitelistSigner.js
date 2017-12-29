'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var Whitelist = artifacts.require("./Whitelist.sol")  

contract('Whitelist :: Signer', function(accounts) {

  beforeEach(async function() {
    let owner = accounts[0]
    let freezeEndsAt = 1521720000
    let weiMinimumLimit = 1000000000000000000
    let weiMaximumLimit = 5000000000000000000
    let weiCap = 400000000000000000000

    this.whitelist = await Whitelist.new()

  })

  it('should verify signed address', async function() {


      await this.whitelist.setRequireSignedAddress(true, accounts[0])

      let msg = web3.sha3(accounts[1])
      let signature = web3.eth.sign(web3.eth.accounts[0], msg)
      console.log(signature);

      //await this.whitelist.verifyWithSignature(address _address, uint8 v, bytes32 r, bytes32 s); 
      //let isListed = await this.whitelist.verify(accounts[0])  
      //isListed.should.be.equal(true)
  })


})
