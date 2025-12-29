// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title TBILLToken
 * @notice Canonical TBILL / BUIDL-style asset for Syncrate MVP
 * @dev Mint/Burn controlled, KYC-gated on all balance updates (OZ v5 pattern)
 */
contract TBILLToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bytes32 public immutable ASSET_ID;
    KYCRegistry public immutable kyc;

    constructor(address kycRegistry, bytes32 assetId)
        ERC20("Syncrate TBILL", "mTBILL")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        kyc = KYCRegistry(kycRegistry);
        ASSET_ID = assetId;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(kyc.isAllowed(to, ASSET_ID), "TBILL: KYC fail");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        require(kyc.isAllowed(from, ASSET_ID), "TBILL: KYC fail");
        _burn(from, amount);
    }

    /**
     * @dev OZ v5 hook: enforce KYC on all balance updates
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            require(kyc.isAllowed(from, ASSET_ID), "TBILL: sender not KYC");
        }
        if (to != address(0)) {
            require(kyc.isAllowed(to, ASSET_ID), "TBILL: recipient not KYC");
        }
        super._update(from, to, amount);
    }
}
