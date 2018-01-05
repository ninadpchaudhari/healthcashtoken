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

/** @dev Tranche based pricing with special support for pre-ico deals.
 *  Implementing "first price" tranches, meaning, that if buyers order is
 *  covering more than one tranche, the price of the lowest tranche will apply
 *  to the whole order.
 */
contract TokenTranchePricing is PricingStrategy, Ownable {

  using SafeMath for uint;

  // addresses and their prices (weis per token)
  mapping (address => uint) public preicoAddresses;

  // Define pricing schedule using tranches.
  struct Tranche {

      // when x tokens are sold this tranche becomes active
      uint amount;

      // How many weis one token cost in this tranche
      uint price;
  }
  
  Tranche[10] public tranches; //up to 10 tranches

  // How many active tranches we have
  uint public trancheCount;

  /// @dev Contruction, creating a list of tranches
  /// @param _tranches uint[] tranches Pairs of (start amount, price)
  function TokenTranchePricing(uint[] _tranches) public {
    
    // Need to have tuples
    require(_tranches.length % 2 == 0);
    trancheCount = _tranches.length / 2;
    uint highestAmount = 0;

    for (uint i = 0; i < trancheCount; i++) {

      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];

      // each tranche must have a larger amount than the previous 
      if ((highestAmount != 0) && (tranches[i].amount <= highestAmount)) {
         revert();
      } 

      highestAmount = tranches[i].amount;
    }

    //First tranche must start with 0 tokens purchased
    require(tranches[0].amount == 0);

    // Last tranche price must be zero, terminating the crowdale
    require(tranches[trancheCount-1].price == 0);
  }

  /** @dev This is invoked once for every pre-ICO address, set pricePerToken
   *  to 0 to disable
   *  @param preicoAddress PresaleFundCollector address
   *  @param pricePerToken How many weis one token cost for pre-ico investors
   */
  function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
  {
    preicoAddresses[preicoAddress] = pricePerToken;
  }

  /** @dev Iterate through tranches. You reach end of tranches when price = 0
   *  @return tuple (time, price)
   */
  function getTranche(uint n) public constant returns (uint, uint) {
    return (tranches[n].amount, tranches[n].price);
  }

  function getFirstTranche() private constant returns (Tranche) {
    return tranches[0];
  }

  function getLastTranche() private constant returns (Tranche) {
    return tranches[trancheCount-1];
  }

  function getPricingStartsAt() public constant returns (uint) {
    return getFirstTranche().amount;
  }

  function getPricingEndsAt() public constant returns (uint) {
    return getLastTranche().amount;
  }

  function isSane(address _crowdsale) public constant returns(bool) {
    /* Our tranches are not bound by time, so we can't really check are we sane
     * so we presume we are  */
    return true;
  }

  /** @dev Get the current tranche or bail out if we are not in the tranche periods.
   *  @param tokensSold total amount of tokens sold, for calculating the current tranche
   *  @return {[type]} [description] 
   */
  function getCurrentTranche(uint tokensSold) private constant returns (Tranche) {

    for (uint i = 0; i < tranches.length; i++) {
        if (tokensSold < tranches[i].amount) {
            return tranches[i-1];
        }
    }
  }

  /** @dev Get the current price.
   *  @param tokensSold total amount of tokens sold, for calculating the current tranche
   *  @return The current price or 0 if we are outside trache ranges
   */
  function getCurrentPrice(uint tokensSold) public constant returns (uint result) {
    return getCurrentTranche(tokensSold).price;
  }

  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return (preicoAddresses[purchaser] > 0);
  }


  // @dev Calculate the current price for buy in amount.
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

    uint multiplier = uint(10) ** decimals;

    // This investor is coming through pre-ico
    if (preicoAddresses[msgSender] > 0) {
      return value.mul(multiplier) / preicoAddresses[msgSender];
    }

    uint price = getCurrentPrice(tokensSold);
    return value.mul(multiplier) / price;
  }

  function() public payable {
    revert(); // No money on this contract
  }

}
