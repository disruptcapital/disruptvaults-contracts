// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a _governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governance account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGov`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Governable is Context {
    address private _governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governor = msgSender;
        emit GovernorshipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function governor() public view virtual returns (address) {
        return _governor;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernor() {
        require(governor() == _msgSender(), "Governable: caller is not the governor");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address newGovernor) public virtual onlyGovernor {
        require(newGovernor != address(0), "Governable: new governor is the zero address");
        emit GovernorshipTransferred(_governor, newGovernor);
        _governor = newGovernor;
    }
}