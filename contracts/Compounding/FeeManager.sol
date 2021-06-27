// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    // 1%
    uint constant public MAX_FEE = 1000;
    uint constant public MAX_CALL_FEE = 111;

    uint public WITHDRAWAL_FEE = 0;
    uint constant public WITHDRAWAL_MAX = 10000;

    uint public callFee = 111;
    uint public fee = MAX_FEE - callFee;

    uint public totalFee = 10;

    function setTotalFee(uint256 _fee) external onlyManager
    {
        totalFee = _fee;
    }

    function setWithdrawlFee(uint256 _fee) external onlyManager
    {
        WITHDRAWAL_FEE = _fee;
    }

    function setCallFee(uint256 _fee) external onlyManager {
        require(_fee <= MAX_CALL_FEE, "!cap");
        
        callFee = _fee;
        fee = MAX_FEE - callFee;
    }
}
