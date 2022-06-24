//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

library LiquidityCalc {
    function amountToLiquidity(uint amount, uint balance, uint totalLiquidity) external pure returns(uint liquidity){
        liquidity = amount / balance * totalLiquidity;
    }

    function liquidityToAmount(uint liquidity, uint balance, uint totalLiquidity) external pure returns(uint amount){
        amount = liquidity / totalLiquidity * balance;
    }
}