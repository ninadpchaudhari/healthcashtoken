/**
 * Numerous modifications have been made to this smart contract.
 * All such modifications are Copyright 2017 SimplyVitalHealth, Inc. 
 * 
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 * 
 */

pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';

/* Standard token, but transfer locked until release.
*  Specific contracts, like the crowdsale contract, 
*  may transfer tokens before released. 
*/
contract ReleasableToken is StandardToken, Ownable {

  address public releaseAgent;
  bool public released = false;
  mapping (address => bool) public transferAgents;

  // Limit token transfer until the crowdsale is over.
  modifier canTransfer(address _sender) {
      if (!released) {
          require(transferAgents[_sender]);
      }
      _;
  }

  // require a whitelisted release agent
  modifier onlyReleaseAgent() {
      require(msg.sender == releaseAgent);
      _;
  }

  // require function to be called in a specific state
  modifier inReleaseState(bool releaseState) 
  {
      require(releaseState == released);
      _;
  }

  // set the contract that can release the token
  function setReleaseAgent(address addr) 
       onlyOwner
       inReleaseState(false)
       public 
  {

      releaseAgent = addr;
  }

  // owner can allow a particular address (crowdsale contract) to 
  // transfer tokens despite the lock up period.
  function setTransferAgent(address addr, bool state) 
      onlyOwner
      inReleaseState(false)
      public 
  {
      transferAgents[addr] = state;
  }

  // one way function to release the tokens
  function releaseTokenTransfer() 
      public 
      onlyReleaseAgent 
  {
      released = true;
  }

  function transfer(address _to, uint _value) 
      public 
      canTransfer(msg.sender)
      returns (bool success) 
  {
      return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) 
      public 
      canTransfer(_from)
      returns (bool success) 
  {
      return super.transferFrom(_from, _to, _value);
  }

}
