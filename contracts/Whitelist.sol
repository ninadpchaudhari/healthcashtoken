/**
 * Copyright 2017 SimplyVitalHealth, Inc. 
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 */

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract Whitelist is Ownable {


  // require contributors to be verified on the server side
  bool public requiredSignedAddress = false;

  // Server side address that signed allowed contributors
  address public signerAddress;

  // list of valid/approved addresses
  mapping (address => bool) whiteListedAddr;

  //Whitelist policy changes
  event WhitelistPolicyChanged(bool requiredSignedAddress, address newSignerAddress);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  function Whitelist() public {
      owner = msg.sender;
  } 

  // Add users to whitelist 
  function addToWhitelist(address[] addresses)
      public
      onlyOwner
  {
      for (uint i = 0; i < addresses.length; i++) {
          whiteListedAddr[addresses[i]] = true;
          Whitelisted(addresses[i], true);
      }
  }

  //remove users from whitelist
  function removeFromWhitelist(address[] addresses)
      public
      onlyOwner
  {
      for (uint i = 0; i < addresses.length; i++) {
          whiteListedAddr[addresses[i]] = false;
          Whitelisted(addresses[i], false);
      }
  }

  function setRequireSignedAddress(bool _required, address _signerAddress) 
      public
      onlyOwner 
  {
      requiredSignedAddress = _required;
      signerAddress = _signerAddress;
      WhitelistPolicyChanged(_required, signerAddress);
  }

  function verify(address _address) 
      public
      constant
      returns (bool)  
  {
      if (requiredSignedAddress) 
          return false;

      return whiteListedAddr[_address];
  }

  function verifyWithSignature(address _address, uint8 v, bytes32 r, bytes32 s) 
      public
      constant
      returns (bool)  
  {

      /** if signedAddress not required 
       *  check onchain list first      */
      if (!requiredSignedAddress) {
          if (whiteListedAddr[_address]) {
              return true;
          }
      }

     bytes32 hash = keccak256(_address);
     return (ecrecover(hash, v, r, s) == signerAddress);
  }


  //interface function
  function isWhitelist() public returns (bool) {
      return true;
  }

  // don't accept funds
  function() public payable {
      revert();
  }

}