pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * Issuer manages token distribution 
 *
 * This contract is fed a CSV file with Ethereum addresses and associated
 * token balances. It act as a gate keeper to ensure there is no double
 * issuance. It gets allowance from another account to distribute tokens.
 *
 */
contract Issuer is Ownable {

  // addresses whose tokens we have already issued
  mapping(address => bool) public issued;

 // token we are distributing 
  StandardToken public token;

  // address from whom the tokens tokens will be distributed
  address public allower;

  // how many addresses have received their tokens
  uint public issuedCount;

  function Issuer(address _owner, address _allower, StandardToken _token) public {
    owner = _owner;
    allower = _allower;
    token = _token;
  }

  function issue(address benefactor, uint amount) public onlyOwner {
    require(issued[benefactor]==false);
    token.transferFrom(allower, benefactor, amount);
    issued[benefactor] = true;
    issuedCount += amount;
  }

}
