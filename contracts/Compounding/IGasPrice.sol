// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IGasPrice {
    function maxGasPrice() external returns (uint);
}