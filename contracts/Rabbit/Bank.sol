// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IBankConfig.sol";
import "./IBTokenFactory.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "hardhat/console.sol";

contract Bank is IBTokenFactory{
  using SafeMath for uint;
  using SafeERC20 for IERC20;

    uint256 constant GLO_VAL = 10000;
    
    struct TokenBank {
        address tokenAddr; 
        address ibTokenAddr; 
        bool isOpen;
        bool canDeposit; 
        bool canWithdraw; 
        uint256 totalVal;
        uint256 totalDebt;
        uint256 totalDebtShare;
        uint256 totalReserve;
        uint256 lastInterestTime;
    }
    
    struct Production {
        address coinToken;
        address currencyToken; 
        address borrowToken;
        bool isOpen;
        bool canBorrow;
        address goblin;
        uint256 minDebt;
        uint256 maxDebt;
        uint256 openFactor;
        uint256 liquidateFactor;
    }
    
    struct Position {
        address owner; 
        uint256 productionId;
        uint256 debtShare;
    }
    
    IBankConfig public config;
    mapping(address => TokenBank) public banks;
    
    mapping(uint256 => Production) public productions;
    uint256 public currentPid;
    
    mapping(uint256 => Position) public positions;
    uint256 public currentPos;
    
    mapping(address => uint256[]) public userPosition;


    struct Pos{
        uint256 posid;
        address token0;
        address token1;
        address borrowToken;
        uint256 positionsValue;
        uint256 totalValue;
        address goblin;
    }
    
    address public devAddr;
    
    
    function totalToken(address token) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');    
        uint balance = token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));
        balance = bank.totalVal < balance? bank.totalVal: balance;
        return balance.add(bank.totalDebt).sub(bank.totalReserve);
    }
    
    
    function deposit(address token, uint256 amount) external payable  {
        TokenBank storage bank = banks[token];
        require(bank.isOpen && bank.canDeposit, 'Token not exist or cannot deposit');

		IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        bank.totalVal = bank.totalVal.add(amount);
        uint256 total = totalToken(token).sub(amount); 
        uint256 ibTotal = IBToken(bank.ibTokenAddr).totalSupply();
        uint256 ibAmount = (total == 0 || ibTotal == 0) ? amount: amount.mul(ibTotal).div(total);
        IBToken(bank.ibTokenAddr).mint(msg.sender, ibAmount);
    }
    
	function addFunds(address token, uint256 _amount) public
	{
		TokenBank storage bank = banks[token];
		bank.totalVal = bank.totalVal.add(_amount);
	}

    function withdraw(address token, uint256 pAmount) external  {
        TokenBank storage bank = banks[token];
        require(bank.isOpen && bank.canWithdraw, 'Token not exist or cannot withdraw');

        uint256 amount = pAmount.mul(totalToken(token)).div(IBToken(bank.ibTokenAddr).totalSupply());
        bank.totalVal = bank.totalVal.sub(amount);
        IBToken(bank.ibTokenAddr).burn(msg.sender, pAmount);
         IERC20(token).safeTransfer(msg.sender, amount );
    }
    
    
    
    function addBank(address token, string calldata _symbol) external  {
        TokenBank storage bank = banks[token];
        require(!bank.isOpen, 'token already exists');
        bank.isOpen = true;
        address ibToken = genIBToken(_symbol);
        bank.tokenAddr = token;
        bank.ibTokenAddr = ibToken;
        bank.canDeposit = true;
        bank.canWithdraw = true;
        bank.totalVal = 0;
        bank.totalDebt = 0;	
        bank.totalDebtShare = 0;
        bank.totalReserve = 0;
        bank.lastInterestTime = block.timestamp;
    }
    
    function ibTokenCalculation(address token, uint256 amount) view external returns(uint256){
        TokenBank memory bank = banks[token];
        uint256 total = totalToken(token).sub(amount); 
        uint256 ibTotal = IBToken(bank.ibTokenAddr).totalSupply();
        return (total == 0 || ibTotal == 0) ? amount: amount.mul(ibTotal).div(total);
    }
    
    receive() external payable {}
}