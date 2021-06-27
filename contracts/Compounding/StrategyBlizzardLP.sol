// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./StratManager.sol";
import "./FeeManager.sol";
import "./GasThrottler.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ISmartYeti.sol";
import "../IUniswapRouterETH.sol";
import "../IPancakePair.sol";
import "hardhat/console.sol";

/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in Blizzard.Money.
 *
 * This strat is currently compatible with all LP pools.
 */
contract StrategyBlizzardLP is StratManager, FeeManager, GasThrottler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public wbnb;
    address public busd;
    address public output;
    address public want;
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public masterchef;

    // Routes
    address[] public outputToWbnbRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    /**
    * @dev Event that is fired each time someone harvests the strat.
    */
    event StratHarvest(address indexed harvester);

    /**
     * @dev Initializes the strategy with the token to maximize.
     */
    constructor(
        address _want,
        address _vault,
        address _unirouter,
        address _keeper,
        address _feeRecipient,
		address _masterChef,
		address _wbnb,
		address _tusk,
		address _busd,
		address _gasPrice
    ) StratManager(_keeper,  _unirouter, _vault, _feeRecipient)
	  GasThrottler(_gasPrice)
	 public {
        want = _want;
		masterchef = _masterChef;
		output = _tusk;
		wbnb = _wbnb;
		busd = _busd;
        lpToken0 = IPancakePair(want).token0();
        lpToken1 = IPancakePair(want).token1();
		outputToWbnbRoute = [output, wbnb];
       
	    if (lpToken0 == wbnb) {
            outputToLp0Route = [output, wbnb];
        } else if (lpToken0 == busd) {
            outputToLp0Route = [output, busd];
        } else if (lpToken0 != output) {
            outputToLp0Route = [output, wbnb, lpToken0];
        }

        if (lpToken1 == wbnb) {
            outputToLp1Route = [output, wbnb];
        } else if (lpToken1 == busd) {
            outputToLp1Route = [output, busd];
        } else if (lpToken1 != output) {
            outputToLp1Route = [output, wbnb, lpToken1];
        }

        _giveAllowances();
    }

    // Puts the funds to work
    function deposit() public whenNotPaused {
        uint256 pairBal = IERC20(want).balanceOf(address(this));

        if (pairBal > 0) {
            ISmartYeti(masterchef).deposit(pairBal);
        }
    }

    /**
     * @dev Withdraws funds and sends them back to the vault.
     * It withdraws {want} from the MasterChef.
     * The available {want} minus fees is returned to the vault.
     * Fees are not assessed if the Vault is paused.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 pairBal = IERC20(want).balanceOf(address(this));

        if (pairBal < _amount) {
            ISmartYeti(masterchef).withdraw(_amount.sub(pairBal));
            pairBal = IERC20(want).balanceOf(address(this));
        }

        if (pairBal > _amount) {
            pairBal = _amount;
        }

        if (tx.origin == owner() || paused()) {
            IERC20(want).safeTransfer(vault, pairBal);
        } else {
            uint256 withdrawalFee = pairBal.mul(WITHDRAWAL_FEE).div(WITHDRAWAL_MAX);
            IERC20(want).safeTransfer(vault, pairBal.sub(withdrawalFee));
        }
    }

    /**
     * @dev Public harvest. Doesn't work when the strat is paused.
     */
    function harvest() external whenNotPaused onlyEOA gasThrottle {
        ISmartYeti(masterchef).deposit(0);
        chargeFees();
        addLiquidity();
        deposit();

        emit StratHarvest(msg.sender);
    }



    // Performance fees
    function chargeFees() internal {
        uint256 toWbnb = IERC20(output).balanceOf(address(this)).mul(totalFee).div(MAX_FEE);
        console.log("tobnb: %s", toWbnb);
		IUniswapRouterETH(unirouter).swapExactTokensForTokens(toWbnb, 0, outputToWbnbRoute, address(this), block.timestamp);

        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));

        uint256 callFeeAmount = wbnbBal.mul(callFee).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(msg.sender, callFeeAmount);

        uint256 feeAmount = wbnbBal.mul(fee).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(feeRecipient, feeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputHalf = IERC20(output).balanceOf(address(this)).div(2);

        if (lpToken0 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(outputHalf, 0, outputToLp0Route, address(this), block.timestamp);
        }

        if (lpToken1 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(outputHalf, 0, outputToLp1Route, address(this), block.timestamp);
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = ISmartYeti(masterchef).userInfo(address(this));
        return _amount;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        ISmartYeti(masterchef).emergencyWithdraw();

        uint256 pairBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, pairBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        ISmartYeti(masterchef).emergencyWithdraw();
    }

    // temporarily pauses the strategy
    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    // resumes operation of the vault
    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
		// console.log(masterchef);
        IERC20(want).safeApprove(masterchef, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }
}