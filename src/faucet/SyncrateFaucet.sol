// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/OUSGToken.sol";
import "../tokens/MockUSDC.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title SyncrateFaucet
 * @notice Demo-only faucet for Syncrate MVP
 * @dev Dispenses mOUSG + USDC with a cooldown, KYC-gated
 */
contract SyncrateFaucet {
    OUSGToken public immutable ousg;
    MockUSDC public immutable usdc;
    KYCRegistry public immutable kyc;

    bytes32 public immutable OUSG_ASSET_ID;
    bytes32 public immutable USDC_ASSET_ID;

    uint256 public constant OUSG_AMOUNT = 1_000 ether;
    uint256 public constant USDC_AMOUNT = 1_000 * 1e6;
    uint256 public constant COOLDOWN = 1 hours;

    mapping(address => uint256) public lastClaim;

    event FaucetDrip(address indexed user);

    constructor(
        address ousgToken,
        address usdcToken,
        address kycRegistry,
        bytes32 ousgAssetId,
        bytes32 usdcAssetId
    ) {
        ousg = OUSGToken(ousgToken);
        usdc = MockUSDC(usdcToken);
        kyc = KYCRegistry(kycRegistry);
        OUSG_ASSET_ID = ousgAssetId;
        USDC_ASSET_ID = usdcAssetId;
    }

    function drip() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + COOLDOWN,
            "Faucet: cooldown active"
        );
        require(kyc.isAllowed(msg.sender, OUSG_ASSET_ID), "Faucet: OUSG KYC fail");
        require(kyc.isAllowed(msg.sender, USDC_ASSET_ID), "Faucet: USDC KYC fail");

        lastClaim[msg.sender] = block.timestamp;

        ousg.mint(msg.sender, OUSG_AMOUNT);
        usdc.mint(msg.sender, USDC_AMOUNT);

        emit FaucetDrip(msg.sender);
    }
}
