//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "./LiquidityPool.sol";
import "./interface/ILiquidityFactory.sol";

contract LiquidityFactory is ILiquidityFactory{

    Params public override params;

    mapping(address => mapping (address=>address)) public override poolAddress;

    function deploy(address _tokenA, address _tokenB) private returns(address pool){
        params = Params({
            tokenA: _tokenA,
            tokenB: _tokenB
        });

        pool = address(new LiquidityPool{salt : keccak256(abi.encodePacked(_tokenA, _tokenB))}());
        delete params;
    }

    function createPool(address _tokenA, address _tokenB) external override{
        require(_tokenA!=_tokenB);
        (address token0, address token1) = _tokenA> _tokenB ? (_tokenA, _tokenB) : (_tokenB,_tokenA);
        require(poolAddress[token0][token1] == address(0),"Pool already exist");
        address pool = deploy(token0, token1);
        poolAddress[token0][token1] = pool;
        emit PoolCreated(_tokenA, _tokenB);
    }

    
}