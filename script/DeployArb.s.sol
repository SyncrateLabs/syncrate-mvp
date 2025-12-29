// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../src/kyc/KYCRegistry.sol";
import "../src/tokens/MockUSDC.sol";
import "../src/tokens/OUSGToken.sol";
import "../src/core/OUSGRedemptionMock.sol";
import "../src/faucet/SyncrateFaucet.sol";
contract DeployArb is Script {
  bytes32 constant OUSG_ID = keccak256("mOUSG");
    bytes32 constant USDC_ID = keccak256("USDC");

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

        // 4. Redemption
        OUSGRedemptionMock redemption = new OUSGRedemptionMock(
            address(ousg),
            address(usdc),
            address(kyc),
            OUSG_ID,
            USDC_ID
        );

        // 5. Faucet
        SyncrateFaucet faucet = new SyncrateFaucet(
            address(ousg),
            address(usdc)
        );

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

        kyc.setKYC(KYC_FAIL, OUSG_ID, false);
        kyc.setKYC(KYC_FAIL, USDC_ID, false);

        vm.stopBroadcast();
    }
}
