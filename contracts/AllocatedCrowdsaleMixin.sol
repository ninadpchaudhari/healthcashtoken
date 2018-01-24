/**
 * Numerous modifications have been made to this smart contract.
 * All such modifications are Copyright 2017 SimplyVitalHealth, Inc.
 *
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 *
 */

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol';
import "./CrowdsaleBase.sol";

/**
 *   This crowdsale type sells tokens from a preallocated pool
 *   The token owner must transfer sellable tokens to the
 *   crowdsale contract using the ERC20.approve()
 */
contract AllocatedCrowdsaleMixin is CrowdsaleBase {

  // The owner who holds the full token pool and has approve()'ed tokens for this crowdsale
  address public tokenOwner;

  // The account who has performed approve() to allocate tokens for the token sale
  function AllocatedCrowdsaleMixin(address _tokenOwner) public {
    tokenOwner = _tokenOwner;
  }

  // called from invest() to confirm if the current purchase does not break our cap rule
  function isBreakingCap(
      uint weiAmount,
      uint tokenAmount,
      uint weiRaisedTotal,
      uint tokensSoldTotal)
      public
      constant
      returns (bool limitBroken)
  {

      return (tokenAmount > getTokensLeft());

  }

  // we are sold out when our approve pool is depleated
  function isCrowdsaleFull() public constant returns (bool) {
    return (getTokensLeft() == 0);
  }

  // get the amount of unsold tokens allocated to this contract
  function getTokensLeft() public constant returns (uint) {
    return token.allowance(tokenOwner, this);
  }

  // transfer tokens from approve() pool to the buyer
  function assignTokens(address receiver, uint tokenAmount) internal {
    assert(token.transferFrom(tokenOwner, receiver, tokenAmount));
  }
}
