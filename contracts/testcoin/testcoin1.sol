//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract testcoin1 is ERC20 {
    constructor () ERC20("Testcoin","TEST1"){
        _mint(msg.sender, 1000 ether);
    }
}