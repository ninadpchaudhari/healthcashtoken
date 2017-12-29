/**
 * Numerous modifications have been made to this smart contract.
 * All such modifications are Copyright 2017 SimplyVitalHealth, Inc. 
 * 
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 * 
 */

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/DetailedERC20.sol';

import "./PricingStrategy.sol";
import "./FinalizeAgent.sol";
import "./AllocatedCrowdsaleMixin.sol";

/**
 *
 * Handle
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
contract Crowdsale is AllocatedCrowdsaleMixin {

  // Keep track of how much each referrer refferred 
  mapping(uint128 => uint) public referrals;

  function Crowdsale(
      address _token,
      PricingStrategy _pricingStrategy,
      address _multisigWallet,
      uint _start,
      uint _end,
      uint _minimumFundingGoal,
      address _tokenOwner)
      
      public 
 
      CrowdsaleBase(_token, 
      _pricingStrategy, 
      _multisigWallet, 
      _start, 
      _end, 
      _minimumFundingGoal) 

      AllocatedCrowdsaleMixin(_tokenOwner)
  {

  }

  /**
   * Preallocate tokens for the early investors.
   *
   * Preallocated tokens have been sold before the actual crowdsale opens.
   * This function mints the tokens and moves the crowdsale needle.
   *
   * Investor count is not handled; it is assumed this goes for multiple investors
   * and the token distribution happens outside the smart contract flow.
   *
   * No money is exchanged, as the crowdsale team already have received the payment.
   *
   * @param fullTokens tokens as full tokens - decimal places added internally
   * @param weiPrice Price of a single full token in wei
   *
   */
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10 ** token.decimals();
    uint weiAmount = weiPrice * fullTokens; // This can be also 0, we give out tokens for free

    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

    assignTokens(receiver, tokenAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

  function investWithSignedAddress(
      address addr,
      uint128 customerId,
      uint8 v,
      bytes32 r,
      bytes32 s)
      public
      payable 
  {
     require(address(whitelist) != address(0));
     require(whitelist.verifyWithSignature(addr, v, r, s)); 
     require(addr == msg.sender);
     investInternal(addr, customerId);
  }

  // Allow anonymous contributions to this crowdsale.
  function invest(address addr) public payable {
      
      // Crowdsale allows only server-side signed participants
      if (address(whitelist) != address(0)) {
        if (whitelist.requiredSignedAddress()) {
            revert(); 
        } else {
            require(whitelist.verify(addr));
        }
      }

      investInternal(addr, 0);
  }

  // Invest to tokens, recognize the payer and clear his address
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
      investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

  // Invest to tokens, keep track of referral totals
  function buyWithReferralSignedAddress(uint128 customerId, uint128 referralId, uint8 v, bytes32 r, bytes32 s) public payable {
      referrals[referralId] = referrals[referralId].add(msg.value);      
      investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

  // Invest to tokens, keep track of referral totals
  function buyWithReferral(uint128 referralId) public payable {
      referrals[referralId] = referrals[referralId].add(msg.value);      
      invest(msg.sender);
  }
  
  //basic entry point 
  function buy() public payable {
      invest(msg.sender);
  }

}
