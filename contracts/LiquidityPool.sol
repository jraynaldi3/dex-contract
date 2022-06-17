//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;



contract LiquidityPoll {
    struct Liquidity {
        address token1;
        address token2;
    }

    Liquidity liquidityPool;
    constructor() {
    }
}