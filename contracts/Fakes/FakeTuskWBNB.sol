// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeTuskWBNB is ERC20("TUSKWBNB", "TUSKWBNB")
{
	constructor(address wbnb, address tusk)
	{
		token0 = wbnb;
		token1 = tusk;
	}

	address public token0 ;
	address public token1 ;

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}