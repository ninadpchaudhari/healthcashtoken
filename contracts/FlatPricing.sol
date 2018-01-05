/**
 * Numerous modifications have been made to this smart contract.
 * All such modifications are Copyright 2017 SimplyVitalHealth, Inc. 
 * 
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 * 
 */

pragma solidity ^0.4.18;

import "./PricingStrategy.sol";
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

// flat pricing everybody gets this price
contract FlatPricing is PricingStrategy, Ownable {

  using SafeMath for uint;

  // How many weis one token costs 
  uint public oneTokenInWei;

  function FlatPricing(uint _oneTokenInWei) public {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;
  }

  function setTokenPrice(uint _oneTokenInWei) public onlyOwner {
      oneTokenInWei = _oneTokenInWei;
  }

  // Calculate the current price for buy in amount.
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
    uint multiplier = uint(10) ** decimals;
    return value.mul(multiplier) / oneTokenInWei;
  }

}