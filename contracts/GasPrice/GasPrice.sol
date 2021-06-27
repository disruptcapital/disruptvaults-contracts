// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


import "@openzeppelin/contracts/access/Ownable.sol";

contract GasPrice is Ownable {

	constructor(uint _maxGasPrice)
	{
		maxGasPrice = _maxGasPrice;
	}

    uint public maxGasPrice; // 5 gwei

    event NewMaxGasPrice(uint oldPrice, uint newPrice);

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        emit NewMaxGasPrice(maxGasPrice, _maxGasPrice);
        maxGasPrice = _maxGasPrice;
    }
}