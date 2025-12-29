// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/OUSGToken.sol";
import "../tokens/MockUSDC.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title OUSGRedemptionMock
 * @notice Canonical redemption: burn mOUSG, mint USDC
 * @dev Demo-only issuer redemption logic
 */
contract OUSGRedemptionMock {
    OUSGToken public immutable ousg;
    MockUSDC public immutable usdc;
    KYCRegistry public immutable kyc;

    bytes32 public immutable OUSG_ASSET_ID;
    bytes32 public immutable USDC_ASSET_ID;

    event RedemptionExecuted(address indexed user, uint256 amount);

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

    /**
     * @notice Redeem mOUSG for USDC (1:1 for demo)
     */
    function redeem(uint256 amount) external {
        address user = msg.sender;

        require(
            kyc.isAllowed(user, OUSG_ASSET_ID),
            "Redeem: OUSG KYC fail"
        );
        require(
            kyc.isAllowed(user, USDC_ASSET_ID),
            "Redeem: USDC KYC fail"
        );

        ousg.burn(user, amount);
        usdc.mint(user, amount);

        emit RedemptionExecuted(user, amount);
    }
}
