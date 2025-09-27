// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockPYUSD
 * @dev Mock PYUSD token for testing purposes
 */
contract MockPYUSD is ERC20 {
    constructor() ERC20("PayPal USD", "PYUSD") {
        // Mint initial supply to deployer (1 million PYUSD with 6 decimals)
        _mint(msg.sender, 1000000 * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6; // PYUSD has 6 decimals
    }

    // Mint function for testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
