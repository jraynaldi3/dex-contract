//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "./interface/ILiquidityFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract LiquidityPool is ReentrancyGuard{

    event LiquidityAdded(uint amount1, uint amount2, address by);
    event LiquidityRemoved(uint amount1, uint amount2, address by);
    event Swap(uint amount1, uint amount2, address by, uint atPrice);
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
    uint deliminator = 2**64;

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

    function getPrice(uint amount1, uint amount2) internal view returns(uint){
        return amount1*deliminator/amount2;
    }

    function getCurrentPrice() public view returns(uint price){
        uint token1 = balance1();
        uint token2 = balance2();
        price = getPrice(token1, token2);
    }

    function addLiquidity(uint256 amount1, uint256 amount2) public payable{
        uint price = getCurrentPrice();
        require ( amount1 * deliminator / amount2 > price - (price*space/10000) && amount1 * deliminator / amount2  < price + (price*space/10000),"Wrong Price");
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this), amount1));
        require(success,"Transfer Unsuccessfull");
        (bool success2, ) = 
            liquidityPool.token2.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this), amount2));
        require(success2,"Transfer Unsuccessfull");
        positionOfAccount[msg.sender].amountToken1 += amount1;
        positionOfAccount[msg.sender].amountToken2 += amount2;
        
        emit LiquidityAdded(amount1, amount2, msg.sender);
    }

    function removeLiquidity(uint amount) public payable {
        uint price = getCurrentPrice();
        require( amount <= positionOfAccount[msg.sender].amountToken1);
        uint amount2 =  amount* deliminator/price;
        positionOfAccount[msg.sender].amountToken1 -= amount;
        positionOfAccount[msg.sender].amountToken2 -= amount2;
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount));
        require(success,"failed transfer token1");
        (success, ) = 
            liquidityPool.token2.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount2));
        require(success,"failed transfer token2");
        emit LiquidityRemoved(amount, amount2, msg.sender);
    }

    function swap(uint256 amount, bool oneToTwo) external payable{
        if(oneToTwo){
            (bool success, bytes memory data) = 
                liquidityPool.token1.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(msg.sender)));
            require(success && abi.decode(data, (uint))>=amount);

        } else {
            (bool success, bytes memory data) = 
                liquidityPool.token2.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(msg.sender)));
            require(success && abi.decode(data, (uint))>=amount);
        }

        uint priceAfterSwap = getPriceAfterSwap(amount, oneToTwo);
        uint toSend = oneToTwo?
            (amount*deliminator/priceAfterSwap):
            amount*priceAfterSwap/deliminator;

        if(oneToTwo){
            (bool success,bytes memory data) = liquidityPool.token2.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            require(success && abi.decode(data,(uint))>=toSend,"Not Enought Liquidity");
            (success,) = liquidityPool.token1.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this),amount));
            require(success,"failed");
            (success, )= liquidityPool.token2.call(abi.encodeWithSelector(IERC20.transfer.selector,address(msg.sender),toSend));
            require(success,"failed");
            emit Swap(amount, toSend, msg.sender, priceAfterSwap);
        } else {
            (bool success,bytes memory data) = liquidityPool.token1.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            require(success && abi.decode(data,(uint))>=toSend,"Not Enought Liquidity");
            (success,) = liquidityPool.token2.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this),amount));
            require(success,"failed");
            (success, )= liquidityPool.token1.call(abi.encodeWithSelector(IERC20.transfer.selector,address(msg.sender),toSend));
            require(success,"failed");
            emit Swap(toSend, amount, msg.sender, priceAfterSwap);
        }
    }

    function getPriceAfterSwap(uint amount, bool oneToTwo) public view returns(uint price){
        uint currentBalance1 = balance1();
        uint currentBalance2 = balance2();
        uint currentPrice = getCurrentPrice();
        if(oneToTwo){
            price = getPrice(currentBalance1 + amount, (currentBalance2*deliminator - (amount*(deliminator**2)/currentPrice))/deliminator);
        } else {
            price = getPrice((currentBalance1*deliminator - (amount*currentPrice))/deliminator,currentBalance2 + amount);
        }
    }
}