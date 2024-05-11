// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * this token is for testing the Lock Vault
 */
contract Token is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 1e27);
    }
}
