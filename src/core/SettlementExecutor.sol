// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/TBILLToken.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title SettlementExecutor
 * @notice Canonical issuance of TBILL after settlement
 * @dev Demo-only. In production, this would verify CCTP / attestation proofs.
 */
contract SettlementExecutor {
    TBILLToken public immutable tbill;
    KYCRegistry public immutable kyc;

    bytes32 public immutable TBILL_ASSET_ID;

    // replay protection
    mapping(bytes32 => bool) public processed;

    event SettlementCompleted(
        bytes32 indexed settlementId,
        address indexed user,
        uint256 amount
    );

    constructor(
        address tbillToken,
        address kycRegistry,
        bytes32 tbillAssetId
    ) {
        tbill = TBILLToken(tbillToken);
        kyc = KYCRegistry(kycRegistry);
        TBILL_ASSET_ID = tbillAssetId;
    }

    /**
     * @notice Finalize settlement and mint TBILL
     * @dev `settlementId` represents a bridged USDC transfer (mocked)
     */
    function settle(
        bytes32 settlementId,
        address user,
        uint256 amount
    ) external {
        require(!processed[settlementId], "Settlement: already processed");
        require(
            kyc.isAllowed(user, TBILL_ASSET_ID),
            "Settlement: KYC fail"
        );

        processed[settlementId] = true;
        tbill.mint(user, amount);

        emit SettlementCompleted(settlementId, user, amount);
    }
}
