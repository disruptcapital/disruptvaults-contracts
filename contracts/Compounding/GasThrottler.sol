// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IGasPrice.sol";

contract GasThrottler {
	constructor(address _gasPrice)
	{
		gasprice = _gasPrice;
	}

    address public gasprice;

    

    modifier gasThrottle() {
        require(tx.gasprice <= IGasPrice(gasprice).maxGasPrice(), "gas is too high!");
        _;
    }
}
