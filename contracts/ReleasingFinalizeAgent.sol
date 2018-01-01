/**
 * Numerous modifications have been made to this smart contract.
 * All such modifications are Copyright 2017 SimplyVitalHealth, Inc. 
 * 
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 * 
 */

pragma solidity ^0.4.18;

import "./Crowdsale.sol";
import "./ReleasableToken.sol";

/**
 * A finalize agent that does nothing.
 * Token transfer must be manually released by the owner
 */
contract ReleasingFinalizeAgent is FinalizeAgent {

  Crowdsale public crowdsale;
  ReleasableToken public token;

  function ReleasingFinalizeAgent(
      ReleasableToken _token,
      Crowdsale _crowdsale)
      public 
  {
      token = _token;  
      crowdsale = _crowdsale;
  }
   

  // Check that we can release the token 
  function isSane() public constant returns (bool) {
    return (crowdsale.finalizeAgent() == address(this)) && (token.releaseAgent() == address(this));
  }

  // Called once by crowdsale finalize() 
  function finalizeCrowdsale() public {
    require(msg.sender == address(crowdsale));
    token.releaseTokenTransfer();
  }

}