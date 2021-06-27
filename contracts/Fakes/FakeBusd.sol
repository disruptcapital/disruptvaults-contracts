// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeBusd is ERC20("BUSD", "BUSD")
{
    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}