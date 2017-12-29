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

import "./Whitelist.sol";
import "./PricingStrategy.sol";
import "./FinalizeAgent.sol";


/**
 * Crowdsale state machine without buy functionality.
 *
 * Implements basic state machine logic, but leaves out all buy functions,
 * so that subclasses can implement their own buying logic.
 *
 *
 * For the default buy() implementation see Crowdsale.sol.
 */
contract CrowdsaleBase is Ownable, Pausable {

  /* Max investment count when we are still allowed to change the multisig address */
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMath for uint;

  /* The token we are selling */
  DetailedERC20 public token;

  /* How we are going to price our offering */
  PricingStrategy public pricingStrategy;

  /* Post-success callback */
  FinalizeAgent public finalizeAgent;

  /* tokens will be transfered from this address */
  address public multisigWallet;

  /* if the funding goal is not reached, investors may withdraw their funds */
  uint public minimumFundingGoal;

  /* the UNIX timestamp start date of the crowdsale */
  uint public startsAt;

  /* the UNIX timestamp end date of the crowdsale */
  uint public endsAt;

  /* the number of tokens already sold through this contract*/
  uint public tokensSold = 0;

  /* How many wei of funding we have raised */
  uint public weiRaised = 0;

  /* Calculate incoming funds from presale contracts and addresses */
  uint public presaleWeiRaised = 0;

  /* How many distinct addresses have invested */
  uint public investorCount = 0;

  /* How much wei we have returned back to the contract after a failed crowdfund. */
  uint public loadedRefund = 0;

  /* How much wei we have given back to investors.*/
  uint public weiRefunded = 0;

  /* Has this crowdsale been finalized */
  bool public finalized;

  /** How much ETH each address has invested to this crowdsale */
  mapping (address => uint256) public investedAmountOf;

  /** How much tokens this crowdsale has credited for each investor address */
  mapping (address => uint256) public tokenAmountOf;

  /** Our Whitelist contract */
  Whitelist public whitelist;

  /** You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
  uint public ownerTestValue;

  /** State machine
   *
   * - Preparing: All contract initialization calls and variables have not been set yet
   * - Prefunding: We have not passed start time yet
   * - Funding: Active crowdsale
   * - Success: Minimum funding goal reached
   * - Failure: Minimum funding goal not reached before ending time
   * - Finalized: The finalized has been called and succesfully executed
   * - Refunding: Refunds are loaded on the contract for reclaim.
   */
  enum State {Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

  // A new investment was made
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

  // Refund was processed for a contributor
  event Refund(address investor, uint weiAmount);

  // Crowdsale end time has been changed
  event EndsAtChanged(uint newEndsAt);

  // Crowdsale start time has been changed
  event StartsAtChanged(uint newStartsAt);


  State public testState;

  function CrowdsaleBase(
      address _token,
      PricingStrategy _pricingStrategy,
      address _multisigWallet,
      uint _start,
      uint _end,
      uint _minimumFundingGoal)
      public 
  {

    token = DetailedERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    require(multisigWallet != address(0)); 

    require(_start != 0);
    startsAt = _start;

    require(_end != 0);
    endsAt = _end;

    // Don't mess the dates
    require(startsAt < endsAt);

    // Minimum funding goal can be zero
    minimumFundingGoal = _minimumFundingGoal;
  }

  /**
   * Don't expect to just send in money and get tokens.
   */
  function() public payable {
    revert();
  }

  /**
   * Make an investment.
   *
   * Crowdsale must be running for one to invest.
   * We must have not pressed the emergency brake.
   *
   * @param receiver The Ethereum address who receives the tokens
   * @param customerId (optional) UUID v4 to track the successful payments on the server side'
   *
   * @return tokenAmount How mony tokens were bought
   */
  function investInternal(address receiver, uint128 customerId) 
      whenNotPaused
      internal
      returns(uint tokensBought) 
  {
      // Determine if it's a good time to accept investment from this participant
      if (getState() == State.PreFunding) {
          
          // only whitelisted for early deposit
          require(address(whitelist) != address(0));
          require(whitelist.verify(receiver));

      } else if (getState() == State.Funding) {
          // Retail participants can only come in when the crowdsale is running
          // pass
      } else {
          // Unwanted state
          revert();
      }

      uint weiAmount = msg.value;

      // Account presale sales separately, so that they do not count against pricing tranches
      uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

      // Dust transaction
      require(tokenAmount != 0);

      if (investedAmountOf[receiver] == 0) {
          // A new investor
          investorCount++;
      }

      // Update investor
      investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
      tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

      // Update totals
      weiRaised = weiRaised.add(weiAmount);
      tokensSold = tokensSold.add(tokenAmount);

      if (pricingStrategy.isPresalePurchase(receiver)) {
          presaleWeiRaised = presaleWeiRaised.add(weiAmount);
      }

    // Check that we did not bust the cap
    require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

    assignTokens(receiver, tokenAmount);

    // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our multisig
    multisigWallet.transfer(weiAmount);

    // Tell us invest was success
    Invested(receiver, weiAmount, tokenAmount, customerId);

    return tokenAmount;
  }

  /**
   * Finalize a succcesful crowdsale.
   *
   * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
   */
  function finalize() public inState(State.Success) onlyOwner whenNotPaused {

      // Already finalized
      require(finalized==false);

      // Finalizing is optional. We only call it if we are given a finalizing agent.
      if (address(finalizeAgent) != 0) {
          finalizeAgent.finalizeCrowdsale();
      }

      finalized = true;
  }

  /**
   * Allow to (re)set finalize agent.
   */
  function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
    
      finalizeAgent = addr;
      require(finalizeAgent.isFinalizeAgent()); //must be agent
  }

  // Set the whitelist which approves our buyers
  function setWhitelist(Whitelist addr) public onlyOwner {  
      
      whitelist = addr;
      require(whitelist.isWhitelist()); //must be whitelist

  }

  /**
   * Allow crowdsale owner to adjust times of crowsale 
   *
   * This may put the crowdsale to an invalid state,
   * but we trust owners know what they are doing.
   */
  function setEndsAt(uint time) public onlyOwner {
      require(time > now);
      require(time > startsAt);
      endsAt = time;
      EndsAtChanged(endsAt);
  }

  function setStartsAt(uint time) public onlyOwner {
      require(time > now);
      require(time < endsAt);
      startsAt = time;
      StartsAtChanged(startsAt);
  }

  /**
   * Allow to (re)set pricing strategy.
   */
  function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
    
    pricingStrategy = _pricingStrategy;
    
    //must be pricing strategy
    require(pricingStrategy.isPricingStrategy()); 
  }

  /**
   * Allow to change the team multisig address in the case of emergency.
   *
   * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
   * (we have done only few test transactions). After the crowdsale is going
   * then multisig address stays locked for the safety reasons.
   */
  function setMultisig(address addr) public onlyOwner {

    require(investorCount < MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);
    multisigWallet = addr;

  }

  /**
   * Allow load refunds back on the contract for the refunding.
   *
   * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
   */
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value > 0);
    loadedRefund = loadedRefund.add(msg.value);
  }

  // Investors can claim refund.
  function refund() public inState(State.Refunding) {
      uint256 weiValue = investedAmountOf[msg.sender];
      require(weiValue > 0);
      investedAmountOf[msg.sender] = 0;
      weiRefunded = weiRefunded.add(weiValue);
      Refund(msg.sender, weiValue);
      msg.sender.transfer(weiValue);
  }

  // return true if the crowdsale has raised enough money to be a successful
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  // Check if the contract relationship looks good
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

  // Check if the contract relationship looks good
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

  /**
   * Crowdfund state machine management.
   *
   * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
   */
  function getState() public constant returns (State) {
      
      if (finalized) 
          return State.Finalized;
      else if (address(finalizeAgent) == 0)
          return State.Preparing;
      else if (!finalizeAgent.isSane())
          return State.Preparing;
      else if (!pricingStrategy.isSane(address(this)))
          return State.Preparing;
      else if (block.timestamp < startsAt)
          return State.PreFunding;
      else if (block.timestamp <= endsAt && !isCrowdsaleFull())
          return State.Funding;
      else if (isMinimumGoalReached())
          return State.Success;
      else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
          return State.Refunding;
      else
          return State.Failure;
  }

  // This is for manual testing of multisig wallet interaction
  function setOwnerTestValue(uint val) public onlyOwner {
    ownerTestValue = val;
  }

  // Interface marker
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

  /**
   * Modifiers
   */

  // Modified allowing execution only if the crowdsale is currently running
  modifier inState(State state) {
    require(getState() == state);
    _;
  }


  /**
   * Abstract functions
   */

  /**
   * Check if the current invested breaks our cap rules.
   *
   *
   * The child contract must define their own cap setting rules.
   * We allow a lot of flexibility through different capping strategies (ETH, token count)
   * Called from invest().
   *
   * @param weiAmount The amount of wei the investor tries to invest in the current transaction
   * @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
   * @param weiRaisedTotal What would be our total raised balance after this transaction
   * @param tokensSoldTotal What would be our total sold tokens count after this transaction
   *
   * @return true if taking this investment would break our cap rules
   */
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);

  // Check if the current crowdsale is full
  function isCrowdsaleFull() public constant returns (bool);

  // Create new tokens or transfer issued tokens to the investor
  function assignTokens(address receiver, uint tokenAmount) internal;
}
