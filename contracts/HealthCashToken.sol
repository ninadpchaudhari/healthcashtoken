
pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/BurnableToken.sol';
import "./ReleasableToken.sol";

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

    //allow owner to transfer
    setTransferAgent(owner, true);
  }

  /** 
   * Allow contracts the ability to transfer
   * for those that might not be able to 
   * transfer themselves. 
   * 
   * Used to enable utility of our token
   * immediatly even while the token is 
   * not released for transfering otherwise. 
   */
  modifier canTransfer(address _sender) {

      if (!released) { 
        require(transferAgents[_sender] || transferAgents[msg.sender]);
      }
      _;
  }

}