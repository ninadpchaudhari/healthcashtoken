
pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/BurnableToken.sol';
import "./ReleaseableToken.sol";

contract HealthCashToken is BurnableToken, ReleasableToken {

  string public name;
  string public symbol;
  uint public decimals;

  /**
   * @param _name        : token name
   * @param _symbol      : token symbol 
   * @param _totalSupply : how many tokens 
   * @param _decimals    : number of decimal places
   */
  function HealthCashToken(string _name, string _symbol, uint _totalSupply, uint _decimals) public 
  {

    // Create with any address, can be transferred
    // to team multisig via changeOwner(),
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    decimals = _decimals;
    balances[owner] = totalSupply;
  }


}