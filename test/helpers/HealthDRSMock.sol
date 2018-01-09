
pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';

contract HealthDRSMock {

 StandardToken public token; 

  function HealthDRSMock(StandardToken _token) public {
    token = _token;
  }

   function purchaseKey(address _seller) public {
     assert(token.transferFrom(msg.sender, _seller, 10));
   }

}