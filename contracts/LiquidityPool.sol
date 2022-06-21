//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "./interface/ILiquidityFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract LiquidityPoll is ReentrancyGuard{

    event LiquidityAdded(uint amount1, uint amount2, address by);
    event LiquidityRemoved(uint amount1, uint amount2, address by);
    struct Liquidity {
        address token1;
        address token2;
    }

    struct Position {
        uint amountToken1;
        uint amountToken2;
    }

    uint fee = 25;
    uint space = 1000;

    mapping (address => Position) positionOfAccount;

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

    function addLiquidity(uint amount1, uint amount2) public payable{
        uint price = getCurrentPrice();
        require (amount1 / amount2 > price - (price*space/10000) && amount1 / amount2 < price + (price*space/10000),"Wrong Price");
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSelector(IERC20.transferFrom.selector,address(msg.sender), address(this), amount1));
        require(success,"Transfer Unsuccessfull");
        ( success, ) = 
            liquidityPool.token2.call(abi.encodeWithSelector(IERC20.transferFrom.selector,address(msg.sender), address(this), amount2));
        require(success,"Transfer Unsuccessfull");
        positionOfAccount[msg.sender].amountToken1 += amount1;
        positionOfAccount[msg.sender].amountToken2 += amount2;
        
        emit LiquidityAdded(amount1, amount2, msg.sender);
    }

    function removeLiquidity(uint amount) public payable {
        uint price = getCurrentPrice();
        require( amount <= positionOfAccount[msg.sender].amountToken1);
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount));
        require(success);
        uint amount2 = amount * price;
        (success, ) = 
            liquidityPool.token2.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount2));
        require(success);
        positionOfAccount[msg.sender].amountToken1 -= amount;
        positionOfAccount[msg.sender].amountToken2 -= amount2;
        emit LiquidityRemoved(amount, amount2, msg.sender);
    }
}