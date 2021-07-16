// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IBToken.sol";
import "hardhat/console.sol";

contract IBTokenFactory {
    function genIBToken(string memory _symbol) public returns(address) {
        return address(new IBToken(_symbol));
    }
}