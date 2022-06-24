//SPDX-License-Identifier:NOLICENSE

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    function transfer(address token, address to, uint256 amount) internal{
        (bool success,bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(success && (data.length==0|| abi.decode(data,(bool))),"failedTransfer");
    }

    function transferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success,bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
        require(success && (data.length==0|| abi.decode(data,(bool))),"failedTransferFrom");
    } 

    function approve(address token, address to, uint256 amount) internal {
        (bool success,bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.approve.selector, to, amount));
        require(success && (data.length==0|| abi.decode(data,(bool))),"failedApprove");
    }
    
    function transferEth(address to, uint256 amount) internal {
        (bool success,) = to.call{value : amount}("");
        require(success, "failedTransferETH");
    }
}