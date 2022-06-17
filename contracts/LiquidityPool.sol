//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "./interface/ILiquidityFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LiquidityPoll {
    struct Liquidity {
        address token1;
        address token2;
    }

    uint fee = 25;

    Liquidity liquidityPool;
    constructor() {
        (liquidityPool.token1, liquidityPool.token2) = ILiquidityFactory(msg.sender).params();
    }

    function balance1() internal view returns(uint){
        (bool success, bytes memory data) = 
            liquidityPool.token1.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data , (uint));
    }

    function balance2() internal view returns(uint){
        (bool success, bytes memory data) = 
            liquidityPool.token2.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data , (uint));
    }

    function getPrice(uint amount1, uint amount2) internal pure returns(uint){
        return amount1/amount2;
    }

    function getCurrentPrice() public view returns(uint price){
        uint token1 = balance1();
        uint token2 = balance2();
        price = getPrice(token1, token2);
    }

}