pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';

/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {

    if (!released) {
        require(transferAgents[_sender]);
    }

    _;
  }

  /** require a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) 
  {
       require(releaseState == released);
       _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) 
       onlyOwner
       inReleaseState(false)
       public 
  {

    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (crowdsale contract) to 
   * transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) 
      onlyOwner
      inReleaseState(false)
      public 
  {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
  */
  function releaseTokenTransfer() 
      public 
      onlyReleaseAgent 
  {
      released = true;
  }

  function transfer(address _to, uint _value) 
      public 
      canTransfer(msg.sender)
      returns (bool success) 
  {
      return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) 
      public 
      canTransfer(_from)
      returns (bool success) 
  {
      return super.transferFrom(_from, _to, _value);
  }

}
