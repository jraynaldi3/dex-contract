//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "./interface/ILiquidityFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/ILiquidityPool.sol";
import "./libraries/LiquidityCalc.sol";


contract LiquidityPool is ReentrancyGuard,ILiquidityPool{

    event LiquidityAdded(uint amount1, uint amount2, address by);
    event LiquidityRemoved(uint amount1, uint amount2, address by);
    event Swap(uint amount1, uint amount2, address by, uint atPrice);
    
    struct Liquidity {
        address token1;
        address token2;
    }

    uint fee = 25;
    uint space = 1000;
    uint deliminator = 2**64;
    uint totalLiquidity;

    mapping (address => uint) public override liquidityOfAccount;

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

    function getCurrentPrice() public view override returns(uint price){
        if (totalLiquidity <= 0) {
            return price = 0;
        }
        uint token1 = balance1();
        uint token2 = balance2();
        price = getPrice(token1, token2);
    }

    function getPriceAfterSwap(uint amount, bool oneToTwo) public view override returns(uint price){
        require(totalLiquidity > 0 &&balance1() >0 && balance2() > 0 , "Not Enought Liquidity");
        uint currentBalance1 = balance1();
        uint currentBalance2 = balance2();
        uint currentPrice = getCurrentPrice();
        if(oneToTwo){
            price = getPrice(currentBalance1 + amount, (currentBalance2*deliminator - (amount*(deliminator**2)/currentPrice))/deliminator);
        } else {
            price = getPrice((currentBalance1*deliminator - (amount*currentPrice))/deliminator,currentBalance2 + amount);
        }
    }

    function addLiquidity(uint256 amount1, uint256 amount2) external override payable{
        uint price = getCurrentPrice();
        if(totalLiquidity > 0){
            require ( getPrice(amount1, amount2)> price - (price*space/10000) && getPrice(amount1, amount2) < price + (price*space/10000),"Wrong Price");
        }
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this), amount1));
        require(success,"Transfer Unsuccessfull");
        (bool success2, ) = 
            liquidityPool.token2.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(msg.sender),address(this), amount2));
        require(success2,"Transfer Unsuccessfull");
        if(totalLiquidity > 0 ) {
            uint liquidity = LiquidityCalc.amountToLiquidity(amount1, balance1(), totalLiquidity);
            liquidityOfAccount[msg.sender] += liquidity; 
            totalLiquidity += liquidity;
        } else {
            liquidityOfAccount[msg.sender] += 1 * deliminator;
            totalLiquidity += 1 * deliminator;
        }
        emit LiquidityAdded(amount1, amount2, msg.sender);
    }

    function removeLiquidity(uint liquidity) external override payable {
        require( liquidity <= liquidityOfAccount[msg.sender],"Not Enought");
        liquidityOfAccount[msg.sender] -= liquidity;
        uint amount1 = LiquidityCalc.liquidityToAmount(liquidity, balance1(), totalLiquidity);
        uint amount2 = LiquidityCalc.liquidityToAmount(liquidity, balance2(), totalLiquidity);
        totalLiquidity -= liquidity;
        (bool success, ) = 
            liquidityPool.token1.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount1));
        require(success,"failed transfer token1");
        (success, ) = 
            liquidityPool.token2.call(abi.encodeWithSelector(IERC20.transfer.selector, address(msg.sender), amount2));
        require(success,"failed transfer token2");
        emit LiquidityRemoved(amount1, amount2, msg.sender);
    }

    function swap(uint256 amount, bool oneToTwo) external override payable{
        require(totalLiquidity>0);
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

    
}