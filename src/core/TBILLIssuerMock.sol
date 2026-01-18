// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/TBILLToken.sol";
import "../tokens/MockUSDC.sol";
import "../kyc/KYCRegistry.sol";

/**
 * @title TBILLIssuerMock
 * @notice Canonical RWA issuer mock for Syncrate MVP
 * @dev This contract is the only entity allowed to mint TBILL tokens.
 */
contract TBILLIssuerMock {
    TBILLToken public immutable tbill;
    MockUSDC public immutable usdc;
    KYCRegistry public immutable kyc;

    event TBILLIssued(address indexed user, uint256 amount);

    constructor(address tbill_, address usdc_, address kyc_) {
        tbill = TBILLToken(tbill_);
        usdc = MockUSDC(usdc_);
        kyc = KYCRegistry(kyc_);
    }

    /// @notice Issue TBILL to a user in exchange for USDC held by this contract
    /// @dev Steps (strict order): verify KYC, ensure USDC balance, mint TBILL, emit event
    function issue(address user, uint256 amount) external {
        require(kyc.isAllowed(user, tbill.ASSET_ID()), "TBILLIssuer: KYC fail");
        require(usdc.balanceOf(address(this)) >= amount, "TBILLIssuer: insufficient USDC");

        // Mint exactly `amount` TBILL to `user`. TBILL.mint is locked to the issuer.
        tbill.mint(user, amount);

        emit TBILLIssued(user, amount);
    }
}
