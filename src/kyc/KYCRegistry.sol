// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KYCRegistry
 * @notice Simple per-asset KYC registry for Syncrate MVP
 * @dev Demo-only. In production this would be replaced by issuer attestations or zkKYC.
 */
contract KYCRegistry {
    // assetId => user => allowed
    mapping(bytes32 => mapping(address => bool)) private _kyc;

    event KYCUpdated(address indexed user, bytes32 indexed assetId, bool allowed);

    function setKYC(address user, bytes32 assetId, bool allowed) external {
        _kyc[assetId][user] = allowed;
        emit KYCUpdated(user, assetId, allowed);
    }

    function isAllowed(address user, bytes32 assetId) external view returns (bool) {
        return _kyc[assetId][user];
    }
}
