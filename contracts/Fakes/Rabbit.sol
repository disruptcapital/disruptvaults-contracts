// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IRabbit.sol";

contract Rabbit is  IRabbit, ERC20("Rabbit", "Rabbit")
{
    function mint(address to, uint256 amount) external override virtual  returns (bool){
        _mint(to, amount);
    }
}