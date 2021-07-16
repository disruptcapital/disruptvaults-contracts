// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// For interacting with the Rabbit bank vaults
interface IRabbitBank {

	function deposit(address token, uint256 _amount) external;

	function withdraw(address token, uint256 _amount) external;

    function userInfo(address _user) external view returns (uint256, uint256);

	function totalToken(address token) external view returns (uint256);

	function banks(address token) external view returns (address, address, bool, bool, bool, uint256, uint256, uint256, uint256, uint256);
}