'use strict'
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const Web3EthAccounts = require('web3-eth-accounts')
const account = new Web3EthAccounts('ws://localhost:8546')
const ethUtil = require('ethereumjs-util') 

var Whitelist = artifacts.require("./Whitelist.sol")  

contract('Whitelist :: Signer', function(accounts) {

  beforeEach(async function() {
    
    this.signerAccount = account.create();
    this.whitelist = await Whitelist.new()

  })

  it('should verify signed address', async function() {

      await this.whitelist.setRequireSignedAddress(true, this.signerAccount.address)

      // Elliptic curve signature must be done on the Keccak256 Sha3 hash of a piece of data.
      let addressHash = await ethUtil.sha3(accounts[1]);    
      let sig = ethUtil.ecsign(addressHash, ethUtil.toBuffer(this.signerAccount.privateKey));

      let isListed = await this.whitelist.verifyWithSignature(accounts[1], sig.v, ethUtil.bufferToHex(sig.r), ethUtil.bufferToHex(sig.s)); 
      isListed.should.be.equal(true)
  })

  it('should not verify a mis-signed address', async function() {

    //set our signer address to be something different than what we will sign with
    await this.whitelist.setRequireSignedAddress(true, accounts[1])

    // Elliptic curve signature must be done on the Keccak256 Sha3 hash of a piece of data.
    let addressHash = await ethUtil.sha3(accounts[1]);    
    let sig = ethUtil.ecsign(addressHash, ethUtil.toBuffer(this.signerAccount.privateKey));

    let isListed = await this.whitelist.verifyWithSignature(accounts[1], sig.v, ethUtil.bufferToHex(sig.r), ethUtil.bufferToHex(sig.s)); 
    isListed.should.be.equal(false)
})


})
