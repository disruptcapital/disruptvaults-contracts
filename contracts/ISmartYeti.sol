// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// For interacting with the pancake smart chef syrup pools
interface ISmartYeti {

function leaveStaking(uint256 _amount) external;

function enterStaking(uint256 _amount) external;

function pendingCake(address _user) external view returns (uint256);

function deposit(uint256 _amount) external;

function withdraw(uint256 _amount) external;

    function userInfo(address _user) external view returns (uint256, uint256);
    
    function emergencyWithdraw() external;

}