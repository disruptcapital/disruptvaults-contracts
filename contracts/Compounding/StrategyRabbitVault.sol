// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./StratManager.sol";
import "./FeeManager.sol";
import "./GasThrottler.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../IRabbitBank.sol";
import "../Rabbit/IFairLaunch.sol";
import "../IUniswapRouterETH.sol";
import "../IPancakePair.sol";
import "hardhat/console.sol";
import "../IRabbitBank.sol";
/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in Blizzard.Money.
 *
 * This strat is currently compatible with all LP pools.
 */
contract StrategyRabbitVault is StratManager, FeeManager, GasThrottler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public wbnb;
    address public output;
    address public want;
	address public ibToken;
	address public rabbitVault;
	address public rabbitStaking;
	uint256 public pid;

    // Routes
    address[] public outputToWbnbRoute;
    address[] public outputToInputRoute;

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
		address _rabbitVault,
		address _rabbitStaking,
		address _wbnb,
		address _output,
		address _gasPrice,
		address _ibToken,
		uint256 _pid
		
    ) StratManager(_keeper,  _unirouter, _vault, _feeRecipient)
	  GasThrottler(_gasPrice)
	 public {
        want = _want;
		output = _output;
		wbnb = _wbnb;
		ibToken = _ibToken;
		outputToWbnbRoute = [output, wbnb];
		outputToInputRoute = [output, wbnb, want];
		rabbitStaking = _rabbitStaking;
		rabbitVault = _rabbitVault;
		pid = _pid;
        _giveAllowances();
    }

    // Puts the funds to work
    function deposit() public whenNotPaused {
        uint256 pairBal = IERC20(want).balanceOf(address(this));
		console.log("strat depositing %s", pairBal);
        if (pairBal > 0) {
            IRabbitBank(rabbitVault).deposit(want, pairBal);			
        }

		uint256 ibTokenBalance = IERC20(ibToken).balanceOf(address(this));
         if (ibTokenBalance > 0) {
			console.log("strat depositing to fairlaunch %s", ibTokenBalance);
            IFairLaunch(rabbitStaking).deposit(address(this), pid, ibTokenBalance);	
		}
    }

	function wantToIBToken(uint256 _amount) public view 
		returns (uint256)
	{
		(,,,,,uint256 wantTotalToken,,,,) = IRabbitBank(rabbitVault).banks(want);
        uint256 ibTotal = IERC20(ibToken).totalSupply();
        uint256 ibAmount = (wantTotalToken == 0 || wantTotalToken == 0) ? _amount: _amount.mul(ibTotal).div(wantTotalToken);
	
		return ibAmount;
	}

    /**
     * @dev Withdraws funds and sends them back to the vault.
     * It withdraws {want} from the MasterChef.
     * The available {want} minus fees is returned to the vault.
     * Fees are not assessed if the Vault is paused.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");
		console.log("&&&&&&&&&&&&&&&&&&&& withdraw $$$$$$$$$$$$$$$$$$");

		console.log("strat withdraw %s", _amount);
		uint256 ibTokensToWithdraw = wantToIBToken(_amount);
		console.log("ibTokensToWithdraw: %s", ibTokensToWithdraw);

        uint256 ibTokensInContract = IERC20(ibToken).balanceOf(address(this));
		console.log("ibTokensInContract: %s", ibTokensInContract);

		// If not enough IB Tokens in contract, remove some from farm
        if (ibTokensInContract < _amount) {
			console.log("If not enough IB Tokens in contract, remove some from farm");
			uint256 ibTokensToWithdrawFromFairLaunch = ibTokensToWithdraw.sub(ibTokensInContract);
			console.log("ibTokensToWithdrawFromFairLaunch: %s", ibTokensToWithdrawFromFairLaunch);
            IFairLaunch(rabbitStaking).withdraw(address(this), pid, ibTokensToWithdrawFromFairLaunch);			
            ibTokensInContract = IERC20(ibToken).balanceOf(address(this));
			console.log("ibTokensInContract: %s", ibTokensInContract);
        }

        if (ibTokensInContract > _amount) {
			console.log("ibTokensInContract > _amount");
            ibTokensInContract = _amount;
        }

		// Swap ib Tokens for want tokens
		console.log("ibTokensInContract: %s", ibTokensInContract);
		uint256 wantTokensInContract = IERC20(want).balanceOf(address(this));	

		console.log("wantTokensInContract: %s", wantTokensInContract);	
		IRabbitBank(rabbitVault).withdraw(want, ibTokensInContract);

		wantTokensInContract = IERC20(want).balanceOf(address(this));	
		console.log("wantTokensInContract: %s", wantTokensInContract);

		console.log("Transfering %s to %s", vault, _amount);
		IERC20(want).safeTransfer(vault, _amount);        

		console.log("&&&&&&&&&&&&&&&&&&&& withdraw $$$$$$$$$$$$$$$$$$");
    }

    /**
     * @dev Public harvest. Doesn't work when the strat is paused.
     */
    function harvest() external whenNotPaused onlyEOA gasThrottle {
        IFairLaunch(rabbitStaking).deposit(ibToken, pid, 0);
        chargeFees();
		compound();
        deposit();

        emit StratHarvest(msg.sender);
    }

	function compound() internal {
		uint256 toWant = IERC20(output).balanceOf(address(this));
		IUniswapRouterETH(unirouter).swapExactTokensForTokens(toWant, 0, outputToInputRoute, address(this), block.timestamp);
	}

    // Performance fees
    function chargeFees() internal {
        uint256 toWbnb = IERC20(output).balanceOf(address(this)).mul(totalFee).div(MAX_FEE);
        console.log("tobnb: %s", toWbnb);

		IUniswapRouterETH(unirouter).swapExactTokensForTokens(toWbnb, 0, outputToWbnbRoute, address(this), block.timestamp);
        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));
		console.log("wbnbBal: %s", wbnbBal);

        uint256 callFeeAmount = wbnbBal.mul(callFee).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(msg.sender, callFeeAmount);
 		console.log("callFeeAmount: %s", callFeeAmount);

        uint256 feeAmount = wbnbBal.mul(fee).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(feeRecipient, feeAmount);
		console.log("feeAmount: %s", feeAmount);
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

		console.log("*************** BALANCEOFPOOL ********************");
		uint256 totalIbTokens = IERC20(ibToken).totalSupply();		
		console.log("totalIbTokens: %s", totalIbTokens);
		(uint256 amount, ,, ) = IFairLaunch(rabbitStaking).userInfo(pid, address(this));
		console.log("amount: %s", amount);

		(, , ,  ,  ,  uint256 totalVal, uint256 totalDebt , , uint256 totalReserve,) = IRabbitBank(rabbitVault).banks(want);
		console.log("totalVal: %s", totalVal);
		console.log("totalDebt: %s", totalDebt);
		console.log("totalReserve: %s", totalReserve);
		
		uint256 totalWant = totalVal == 0 ? 0 : totalVal.add(totalReserve).sub(totalDebt);
		console.log("totalWant: %s", totalWant);
		console.log("%s .mul(1e18).div( %s ).mul( %s )", amount, totalIbTokens, totalWant);
		uint256 balOfPool = totalIbTokens == 0 ? 0 : amount.mul(1e18).div(totalIbTokens).mul(totalWant).div(1e18);
		console.log("balOfPool: %s", balOfPool);
		console.log("*************** BALANCEOFPOOL ********************");

		return balOfPool;
    }

    function getPricePerFullShare() public view returns (uint256) {
		uint256 totalIBSupply = IERC20(ibToken).totalSupply();
        return totalIBSupply == 0 ? 1e18 : IRabbitBank(rabbitVault).totalToken(want).mul(1e18).div(totalIBSupply);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");
		IFairLaunch(rabbitStaking).emergencyWithdraw(pid);
		uint256 ibTokenBalance = IERC20(ibToken).balanceOf(address(this));
        IRabbitBank(rabbitVault).withdraw(want, ibTokenBalance);

        uint256 pairBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, pairBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
		pause();
		IFairLaunch(rabbitStaking).emergencyWithdraw(pid);
		uint256 ibTokenBalance = IERC20(ibToken).balanceOf(address(this));
		IRabbitBank(rabbitVault).withdraw(want, ibTokenBalance);

		uint256 pairBal = IERC20(want).balanceOf(address(this));
        
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
        IERC20(want).safeApprove(rabbitVault, type(uint256).max);
		IERC20(ibToken).safeApprove(rabbitStaking, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rabbitVault, 0);
		IERC20(ibToken).safeApprove(rabbitStaking, 0);
        IERC20(output).safeApprove(unirouter, 0);
    }
}