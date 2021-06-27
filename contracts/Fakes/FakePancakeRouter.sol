// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../IUniswapRouterETH.sol";
import "hardhat/console.sol";

contract FakePancakeRouter //is IUniswapRouterETH
{
	mapping(address => mapping(address => address)) public tokens;
    function factory() external pure returns (address)
	{
		return address(0);
	}

    function WETH() external pure returns (address){
		return address(0);
	}

	function mapTokens(address _tokenA, address _tokenB, address _pair) public
	{
		tokens[_tokenA][_tokenB] = _pair;
	}

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity)
	{
		IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
		IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
		address pairToken = tokens[tokenA][tokenB];
		if(pairToken == address(0))
		{
			pairToken = tokens[tokenB][tokenA];
		}

		require (pairToken != address(0), "Shit, no mapping");

		IERC20(pairToken).transfer(to, amountADesired);
		console.log("Privded liquidity");
		return (0, 0, 0);
	}

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity)
	{
		return (0, 0, 0);
	}

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB)
	{
		return (0, 0);
	}

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH)
	{
		return (0, 0);
	}

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB)
	{
		return (0, 0);
	}

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH)
	{
		return (0, 0);
	}

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH)
	{
		return 0;
	}

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH)
	{
		return 0;
	}

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts)
	{
		console.log(path[0]);
		IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
		IERC20(path[path.length-1]).transfer(to, amountIn);
		uint[] memory ret ;
		return  ret ;
	}

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts)
	{
			 uint[] memory ret ;
		return  ret ;
	}

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external
	{

	}

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable
	{

	}

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external
	{

	}

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts)
		{
			uint[] memory ret ;
			return  ret ;
		}

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts)
		{
			uint[] memory ret ;
			return  ret ;
		}

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts)
		{
			uint[] memory ret ;
			return  ret ;
		}

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts)
		{
			uint[] memory ret ;
			return  ret ;
		}

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB)
	{
		return 0;
	}

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut)
	{
		return 0;
	}

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn)
	{ 
		return 0;
	}

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)
	{
		 uint[] memory ret ;
		return  ret ;
	}

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts)
	{
		 uint[] memory ret ;
		return  ret ;
	}


}