pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import 'zeppelin-solidity/contracts/token/DetailedERC20.sol';

contract Crowdsale is Ownable, Pausable {

/** This is a mock crowdsale contract, 
only used for meeting the WhitelistProxyBuyer 
dependencies for testing */

DetailedERC20 public token;

  function invest(address addr) public payable {
      require(addr != address(0));
  }

}