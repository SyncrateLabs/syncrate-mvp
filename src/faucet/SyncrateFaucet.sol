// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/OUSGToken.sol";
import "../tokens/MockUSDC.sol";

/**
 * @title SyncrateFaucet
 * @notice Demo-only faucet for Syncrate MVP
 * @dev Dispenses mOUSG + USDC with a cooldown
 */
contract SyncrateFaucet {
    OUSGToken public immutable ousg;
    MockUSDC public immutable usdc;

    uint256 public constant OUSG_AMOUNT = 1_000 ether;
    uint256 public constant USDC_AMOUNT = 1_000 * 1e6;
    uint256 public constant COOLDOWN = 1 hours;

    mapping(address => uint256) public lastClaim;

    event FaucetDrip(address indexed user);

    constructor(address ousgToken, address usdcToken) {
        ousg = OUSGToken(ousgToken);
        usdc = MockUSDC(usdcToken);
    }

    function drip() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + COOLDOWN,
            "Faucet: cooldown active"
        );

        lastClaim[msg.sender] = block.timestamp;

        ousg.mint(msg.sender, OUSG_AMOUNT);
        usdc.mint(msg.sender, USDC_AMOUNT);

        emit FaucetDrip(msg.sender);
    }
}
