// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title KYCRegistry
 * @notice Simple per-asset KYC registry for Syncrate MVP
 * @dev Demo-only. In production this would be replaced by issuer attestations or zkKYC.
 */
contract KYCRegistry is AccessControl {
    // assetId => user => allowed
    mapping(bytes32 => mapping(address => bool)) private _kyc;

    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");

    event KYCUpdated(address indexed user, bytes32 indexed assetId, bool allowed);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(KYC_ADMIN_ROLE, msg.sender);
    }

    function setKYC(address user, bytes32 assetId, bool allowed) external onlyRole(KYC_ADMIN_ROLE) {
        _kyc[assetId][user] = allowed;
        emit KYCUpdated(user, assetId, allowed);
    }

    function isAllowed(address user, bytes32 assetId) external view returns (bool) {
        return _kyc[assetId][user];
    }
}
