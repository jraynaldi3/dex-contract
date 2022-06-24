//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

interface ILiquidityPool {

    function getCurrentPrice() external view returns(uint price);
    
    function getPriceAfterSwap(uint amount, bool oneToTwo) external view returns(uint price);

    function addLiquidity(uint256 amount1, uint256 amount2) external payable;

    function removeLiquidity(uint amount) external payable;

    function swap(uint256 amount, bool oneToTwo) external payable;
}