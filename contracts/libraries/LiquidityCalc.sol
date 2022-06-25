//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

///@notice for calculate liquidity 
library LiquidityCalc {
    ///@notice convert an amount number of transfer to liquidity 
    ///@dev use while adding liquidity to pool
    ///@param amount of token;
    ///@param balance token balance of liquidity pool;
    ///@param totalLiquidity total liquidity that pool have;
    function amountToLiquidity(uint amount, uint balance, uint totalLiquidity) internal pure returns(uint liquidity){
        liquidity = amount / balance * totalLiquidity;
    }

    ///@notice convert liquidity to amount of token;
    ///@dev use while removing liquidity from pool
    function liquidityToAmount(uint liquidity, uint balance, uint totalLiquidity) internal pure returns(uint amount){
        amount = liquidity / totalLiquidity * balance;
    }
}