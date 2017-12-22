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
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'zeppelin-solidity/contracts/token/DetailedERC20.sol';

import "./Crowdsale.sol";


/**
*   Collect funds from approved purchasers before crowsale.
*   Once crowdsale is available, buy tokens in a single transaction.
*   Participants may claim the tokens they purchased, once the token
*   is released.
*
* - Allow owner to set the crowdsale contract
* - Have refund after X days, if the crowdsale doesn't materialize
* - Tokens are distributed to this smart contract first
* - All functions can be paused by owner if something goes wrong
*/

contract WhitelistProxyBuyer is Ownable, Pausable {
  using SafeMath for uint;

  // How many investors we have now 
  uint public investorCount;

  // How many wei we have raised total 
  uint public weiRaised;

  // Who are our investors (iterable) 
  address[] public investors;

  // How much they have invested 
  mapping(address => uint) public balances;

  // How many tokens investors have claimed 
  mapping(address => uint) public claimed;

  // When our refund freeze is over (UNIT timestamp) 
  uint public freezeEndsAt;

  // What is the minimum buy in 
  uint public weiMinimumLimit;

  // What is the maximum buy in 
  uint public weiMaximumLimit;

  // How many weis total we are allowed to collect. 
  uint public weiCap;

  // How many tokens were bought 
  uint public tokensBought;

  // How many investors have claimed their tokens 
  uint public claimCount;

  uint public totalClaimed;

  // If timeLock > 0, claiming is possible only after the time has passed 
  uint public timeLock;

  // This is used to signal that we want the refund 
  bool public forcedRefund;

  // Our crowdsale contract where we will move the funds 
  Crowdsale public crowdsale;

  // What is our current state. 
  enum State { Unknown, Funding, Distributing, Refunding }

  // Somebody loaded their investment money 
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // Refund claimed 
  event Refunded(address investor, uint value);

  // We executed our buy 
  event TokensBoughts(uint count);

  // We distributed tokens to an investor 
  event Distributed(address investor, uint count);
  
  // Only whitelisted addresses may participate 
  mapping (address => bool) whiteListedAddr;

  function WhitelistProxyBuyer(
      address _owner, 
      uint _freezeEndsAt, 
      uint _weiMinimumLimit, 
      uint _weiMaximumLimit, 
      uint _weiCap
  )
      public    
  {

    require(_freezeEndsAt > 0);
    require(_weiMinimumLimit > 0);
    require(_weiMaximumLimit > 0);

    owner = _owner;
    weiMinimumLimit = _weiMinimumLimit;
    weiMaximumLimit = _weiMaximumLimit;
    weiCap = _weiCap;
    freezeEndsAt = _freezeEndsAt;
  }

  // Get the token we are distributing. 
  function getToken() 
      public
      constant
      returns(DetailedERC20) 
  {
      require(address(crowdsale) != address(0));
      return crowdsale.token();
  }

  // Add users to whitelist 
  function addToWhitelist(address[] users)
      public
      onlyOwner
  {
      for (uint i = 0; i < users.length; i++) {
          whiteListedAddr[users[i]] = true;
      }
  }

  function isWhitelisted(address _user) 
      public
      constant
      returns (bool)  
  {
      return whiteListedAddr[_user];
  }

  modifier canParticipate(address _user) {
      require(isWhitelisted(_user));
      _;
  }


  // Participate in whitelist contribution 
  function buy()
      public
      payable
      whenNotPaused
      canParticipate(msg.sender)      
   {
    
    require(getState() == State.Funding);
    require(msg.value > 0); // No empty buys
    address investor = msg.sender;

    bool existing = balances[investor] > 0;

    balances[investor] = balances[investor].add(msg.value);

    // Need to satisfy minimum and maximum limits 
    require(balances[investor] >= weiMinimumLimit && balances[investor] <= weiMaximumLimit);

    // This is a new investor
    if (!existing) {
      investors.push(investor);
      investorCount++;
    }

    weiRaised = weiRaised.add(msg.value);
    require(weiRaised <= weiCap);

    /** We will use the same event as the crowdsale for compatibility reasons
     *  despite not having a token amount. */
    Invested(investor, msg.value, 0, 0);

  }

  // Send funds to crowdsale for all participants 
  function buyForEverybody() whenNotPaused public {

    require(getState() == State.Funding);
    require(address(crowdsale) != address(0)); // crowdsale should be set

    // Buy tokens on the contract 
    crowdsale.invest.value(weiRaised)(address(this));

    // Record how many tokens we got 
    tokensBought = getToken().balanceOf(address(this));

    require(tokensBought > 0);
    TokensBoughts(tokensBought);
  }

  // How may tokens each participant gets
  function getClaimAmount(address investor) 
      public
      constant
      returns (uint) 
  {
    // Claims can be only made if we manage to buy tokens
    require(getState() == State.Distributing);
    return balances[investor].mul(tokensBought) / weiRaised;
  }

  // How many tokens remain unclaimed for an investor.
  function getClaimLeft(address investor)
      public
      constant
      returns (uint) 
  {
      return getClaimAmount(investor).sub(claimed[investor]);
  }

  // Claim all remaining tokens for this investor.
  function claimAll() public {
    claim(getClaimLeft(msg.sender));
  }

  // Claim N bought tokens to the investor as the msg sender.
  function claim(uint amount)
      public
      whenNotPaused 
  {
    
    require (now > timeLock);
    require(amount > 0);

    address investor = msg.sender;
    require(getClaimLeft(investor) <= amount);

    // We track who many investor have (partially) claimed their tokens
    if (claimed[investor] == 0) {
      claimCount++;
    }

    claimed[investor] = claimed[investor].add(amount);
    totalClaimed = totalClaimed.add(amount);
    getToken().transfer(investor, amount);

    Distributed(investor, amount);
  }

  // crowdsale never happened. Allow refund.
  function refund()
      public
      whenNotPaused 
  {
    require(getState() == State.Refunding);

    address investor = msg.sender;
    require(balances[investor] > 0);

    uint amount = balances[investor];
    delete balances[investor];
    investor.transfer(amount);
    Refunded(investor, amount);
  }

  /** Set the crowdsale contract, 
   *  where we will move presale funds 
   *  when the whitesale is complete. */      
  function setCrowdsale(Crowdsale _crowdsale) 
      public
      onlyOwner 
  {  
    crowdsale = _crowdsale;
  }

  // set time after which claiming is possible
  function setTimeLock(uint _timeLock)
      public
      onlyOwner 
  {
      timeLock = _timeLock;
  }

  // set weiMinLimit, to adjust as desired
  function setWeiMinimumLimit(uint _weiMinimumLimit)
      public
      onlyOwner 
  {
      weiMinimumLimit = _weiMinimumLimit;
  }

  // set weiMaxLimit, to adjust as desired
  function setWeiMaximumLimit(uint _weiMaximumLimit)
      public
      onlyOwner 
  {
      weiMaximumLimit = _weiMaximumLimit;
  }

  // set weiCap, to adjust as desired
  function setWeiCap(uint _weiCap)
      public
      onlyOwner 
  {
      weiCap = _weiCap;
  }

  // this will force the state to refunding
  function forceRefund() public onlyOwner {
    forcedRefund = true;
  }

  // to send funds back for refunding
  function loadRefund() public payable {
    require(getState() == State.Refunding);
  }

  // return current contract state
  function getState() public constant returns(State) {
    
      if (forcedRefund) 
          return State.Refunding;

      if (tokensBought == 0) {
          if (now >= freezeEndsAt) {
              return State.Refunding;
          } else {
              return State.Funding;
          }
      } else {
          return State.Distributing;
      }
  }

  // only accept funds with buy() or loadRefund()
  function() public payable {
    revert();
  }

}
