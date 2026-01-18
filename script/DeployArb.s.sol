// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../src/kyc/KYCRegistry.sol";
import "../src/tokens/MockUSDC.sol";
import "../src/tokens/OUSGToken.sol";
import "../src/tokens/TBILLToken.sol";
import "../src/core/TBILLIssuerMock.sol";
import "../src/core/OUSGRedemptionMock.sol";
import "../src/core/SettlementExecutor.sol";
import "../src/faucet/SyncrateFaucet.sol";

contract DeployArb is Script {
    bytes32 constant OUSG_ID = keccak256("mOUSG");
    bytes32 constant USDC_ID = keccak256("USDC");
    bytes32 constant TBILL_ID = keccak256("mTBILL");

    address constant KYC_PASS =
        0x1111111111111111111111111111111111111111;

    address constant KYC_FAIL =
        0x2222222222222222222222222222222222222222;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // 1. KYC
        KYCRegistry kyc = new KYCRegistry();

        // 2. USDC
        MockUSDC usdc = new MockUSDC();

        // 3. OUSG
        OUSGToken ousg = new OUSGToken(address(kyc), OUSG_ID);

        // 4. TBILL (canonical asset for Arbitrum)
        TBILLToken tbill = new TBILLToken(address(kyc), TBILL_ID);

        // 5. TBILL issuer (holds USDC and mints TBILL)
        TBILLIssuerMock tbillIssuer = new TBILLIssuerMock(address(tbill), address(usdc), address(kyc));

        // configure issuer on TBILL token (callable once by admin)
        tbill.setIssuer(address(tbillIssuer));

        // 6. Redemption
        OUSGRedemptionMock redemption = new OUSGRedemptionMock(
            address(ousg),
            address(usdc),
            address(kyc),
            OUSG_ID,
            USDC_ID
        );

        // 7. Faucet
        SyncrateFaucet faucet = new SyncrateFaucet(
            address(ousg),
            address(usdc),
            address(kyc),
            OUSG_ID,
            USDC_ID
        );

        // 8. Settlement executor (automates full route)
        SettlementExecutor settlement = new SettlementExecutor(
            address(tbill),
            address(ousg),
            address(usdc),
            address(kyc),
            TBILL_ID,
            OUSG_ID,
            USDC_ID,
            address(tbillIssuer),
            address(redemption)
        );

        // grant necessary roles to SettlementExecutor so it can burn OUSG and mint USDC
        ousg.grantRole(ousg.BURNER_ROLE(), address(settlement));
        usdc.grantRole(usdc.MINTER_ROLE(), address(settlement));

        // -----------------------------
        // ROLE ASSIGNMENTS
        // -----------------------------

        usdc.grantRole(usdc.MINTER_ROLE(), address(redemption));
        usdc.grantRole(usdc.MINTER_ROLE(), address(faucet));

        ousg.grantRole(ousg.MINTER_ROLE(), address(faucet));
        ousg.grantRole(ousg.BURNER_ROLE(), address(redemption));

        // -----------------------------
        // KYC SETUP
        // -----------------------------

        kyc.setKYC(KYC_PASS, OUSG_ID, true);
        kyc.setKYC(KYC_PASS, USDC_ID, true);
        kyc.setKYC(KYC_PASS, TBILL_ID, true);

        kyc.setKYC(KYC_FAIL, OUSG_ID, false);
        kyc.setKYC(KYC_FAIL, USDC_ID, false);
        kyc.setKYC(KYC_FAIL, TBILL_ID, false);

        vm.stopBroadcast();
    }
}
