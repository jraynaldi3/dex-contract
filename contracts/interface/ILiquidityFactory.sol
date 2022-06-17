//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

interface ILiquidityFactory{
    
    event PoolCreated(address tokenA, address tokenB);

    struct Params{
        address tokenA;
        address tokenB;
    }

    function poolAddress(
        address tokenA,
        address tokenB
    ) external view returns(address);

    function createPool(
        address _tokenA,
        address _tokenB
    ) external ;

    function params ()
        external 
        view
        returns(
            address tokenA,
            address tokenB
        );
}