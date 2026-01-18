// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/TBILLToken.sol";
import "../tokens/OUSGToken.sol";
import "../tokens/MockUSDC.sol";
import "../core/TBILLIssuerMock.sol";
import "../core/OUSGRedemptionMock.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title SettlementExecutor
 * @notice Canonical issuance of TBILL after settlement
 * @dev Demo-only. In production, this would verify CCTP / attestation proofs.
 */
contract SettlementExecutor {
    // Chain enumeration for multi-chain support
    enum Chain { Base, Arbitrum }

    TBILLToken public immutable tbill;
    OUSGToken public immutable ousg;
    MockUSDC public immutable usdc;
    TBILLIssuerMock public immutable tbillIssuer;
    OUSGRedemptionMock public immutable redemption;
    KYCRegistry public immutable kyc;

    bytes32 public immutable TBILL_ASSET_ID;
    bytes32 public immutable OUSG_ASSET_ID;
    bytes32 public immutable USDC_ASSET_ID;

    // replay protection (user+amount+chain pair)
    mapping(bytes32 => bool) public processed;

    event RouteStarted(address indexed user, uint256 amount, Chain indexed chain);
    event Redeemed(address indexed user, uint256 amount);
    event Issued(address indexed user, uint256 amount, Chain indexed chain);
    event RouteCompleted(address indexed user, uint256 amount, Chain indexed chain);
    event RouteFailed(address indexed user, string reason);
    event SettlementCompleted(address indexed user, uint256 amount);

    constructor(
        address tbillToken,
        address ousgToken,
        address usdcToken,
        address kycRegistry,
        bytes32 tbillAssetId,
        bytes32 ousgAssetId,
        bytes32 usdcAssetId,
        address tbillIssuer_,
        address redemption_
    ) {
        tbill = TBILLToken(tbillToken);
        ousg = OUSGToken(ousgToken);
        usdc = MockUSDC(usdcToken);
        tbillIssuer = TBILLIssuerMock(tbillIssuer_);
        redemption = OUSGRedemptionMock(redemption_);
        kyc = KYCRegistry(kycRegistry);
        TBILL_ASSET_ID = tbillAssetId;
        OUSG_ASSET_ID = ousgAssetId;
        USDC_ASSET_ID = usdcAssetId;
    }

    /**
     * @notice Finalize settlement and mint TBILL
     * @param user The user address receiving TBILL
     * @param amount The amount of tokens to route
     * @param chain The target chain (Base or Arbitrum)
     * @dev This automates the canonical route in strict order:
     * 1) KYC checks
     * 2) Redeem OUSG (burn)
     * 3) Ensure USDC settlement (mint)
     * 4) Transfer USDC to TBILL issuer
     * 5) Issue TBILL via issuer
     */
    function settle(address user, uint256 amount, Chain chain) external {
        bytes32 id = keccak256(abi.encodePacked(user, amount, chain));
        
        if (processed[id]) {
            emit RouteFailed(user, "Settlement: already processed");
            revert("Settlement: already processed");
        }

        emit RouteStarted(user, amount, chain);

        // 1. KYC: require user allowed for TBILL and OUSG
        if (!kyc.isAllowed(user, TBILL_ASSET_ID)) {
            emit RouteFailed(user, "KYC fail");
            revert("Settlement: KYC fail");
        }
        if (!kyc.isAllowed(user, OUSG_ASSET_ID)) {
            emit RouteFailed(user, "OUSG KYC fail");
            revert("Settlement: OUSG KYC fail");
        }

        processed[id] = true;

        // 2. Trigger canonical redemption of OUSG (burn user's OUSG)
        // SettlementExecutor is granted BURNER_ROLE on OUSG in deploy scripts
        ousg.burn(user, amount);
        emit Redeemed(user, amount);

        // 3. Ensure USDC settlement completes by minting USDC to this executor
        // SettlementExecutor is granted MINTER_ROLE on USDC in deploy scripts
        usdc.mint(address(this), amount);

        // 4. Transfer USDC to the TBILL issuer
        usdc.transfer(address(tbillIssuer), amount);

        // 5. Final: canonical issuance
        tbillIssuer.issue(user, amount);
        emit Issued(user, amount, chain);

        emit RouteCompleted(user, amount, chain);
        emit SettlementCompleted(user, amount);
    }
}
