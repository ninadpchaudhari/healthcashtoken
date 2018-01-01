/**
 * 
 * Copyright (c) 2016 Smart Contract Solutions, Inc. (OpenZeppelin)
 * Licensed under the Apache License, version 2.0: https://github.com/Health-Nexus/healthcashtoken/blob/master/LICENSE
 */

pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/TokenTimelock.sol';

contract TokenFreezer is TokenTimelock {

    function TokenFreezer(
        ERC20Basic _token, 
        address _beneficiary, 
        uint64 _releaseTime) 
        public 
        TokenTimelock(_token, _beneficiary, _releaseTime)
    {

    }

}