/**
 * Copyright 2017 SimplyVitalHealth, Inc. 
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 */

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract Whitelist is Ownable {

  // list of valid/approved addresses
  mapping (address => bool) whiteListedAddr;

  function Whitelist() public {
      
  } 

  // Add users to whitelist 
  function addToWhitelist(address[] addresses)
      public
      onlyOwner
  {
      for (uint i = 0; i < addresses.length; i++) {
          whiteListedAddr[addresses[i]] = true;
      }
  }

  function verify(address _address) 
      public
      constant
      returns (bool)  
  {
      return whiteListedAddr[_address];
  }

  // don't accept funds
  function() public payable {
      revert();
  }

}