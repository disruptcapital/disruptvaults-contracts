// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract StratManager is Ownable, Pausable {
    /**
     * @dev 
     * {keeper} - Address to manage a few lower risk features of the strat
     * {vault} - Address of the vault that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public unirouter;
    address public vault;
    address public feeRecipient;

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     * @param _unirouter router to use for swaps
     * @param _vault address of parent vault.
     * @param _feeRecipient address where to send fees.
     */
    constructor(
        address _keeper,
        address _unirouter,
        address _vault,
        address _feeRecipient
    ) {
        keeper = _keeper;
        unirouter = _unirouter;
        vault = _vault;
        feeRecipient = _feeRecipient;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * @dev Updates fee recipient.
     * @param _feeRecipient new fee recipient address.
     */
    function setfeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}
