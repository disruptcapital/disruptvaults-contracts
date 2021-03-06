// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


interface IBankConfig {
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    function getReserveBps() external view returns (uint256);

    function getLiquidateBps() external view returns (uint256);
}