// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/kyc/KYCRegistry.sol";
import "../src/faucet/SyncrateFaucet.sol";
import "../src/core/SettlementExecutor.sol";
import "../src/tokens/OUSGToken.sol";
import "../src/tokens/MockUSDC.sol";
import "../src/tokens/TBILLToken.sol";

/**
 * Demo script to exercise the full route via SettlementExecutor
 * Steps:
 * 1) drip() via SyncrateFaucet to mint OUSG + USDC to deployer
 * 2) call SettlementExecutor.settle(deployer, 1e18)
 * 3) log final balances
 */
contract DemoRoute is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address faucetAddr = vm.envAddress("FAUCET");
        address settlementAddr = vm.envAddress("SETTLEMENT_EXECUTOR");
        address ousgAddr = vm.envAddress("OUSG");
        address usdcAddr = vm.envAddress("USDC");
        address tbillAddr = vm.envAddress("TBILL");

        vm.startBroadcast(deployerKey);

        SyncrateFaucet faucet = SyncrateFaucet(faucetAddr);
        SettlementExecutor settlement = SettlementExecutor(settlementAddr);
        OUSGToken ousg = OUSGToken(ousgAddr);
        MockUSDC usdc = MockUSDC(usdcAddr);
        TBILLToken tbill = TBILLToken(tbillAddr);

        // Ensure deployer is KYC'd for OUSG, USDC and TBILL before interacting with faucet/issuer
        KYCRegistry kyc = KYCRegistry(ousg.kyc());
        bytes32 USDC_ID = keccak256("USDC");
        kyc.setKYC(deployer, ousg.ASSET_ID(), true);
        kyc.setKYC(deployer, USDC_ID, true);
        kyc.setKYC(deployer, tbill.ASSET_ID(), true);

        // 1) drip to get demo assets
        faucet.drip();

        {
            uint256 b = ousg.balanceOf(deployer);
            console.log("OUSG balance before settle:", b);
        }
        {
            uint256 b = usdc.balanceOf(deployer);
            console.log("USDC balance before settle:", b);
        }
        {
            uint256 b = tbill.balanceOf(deployer);
            console.log("TBILL balance before settle:", b);
        }

        // 2) call settle (executor will run the canonical route)
        // Using Base chain (0)
        settlement.settle(deployer, 1e18, SettlementExecutor.Chain.Base);

        // 3) log balances after
        {
            uint256 b = ousg.balanceOf(deployer);
            console.log("OUSG balance after settle:", b);
        }
        {
            uint256 b = usdc.balanceOf(deployer);
            console.log("USDC balance after settle:", b);
        }
        {
            uint256 b = tbill.balanceOf(deployer);
            console.log("TBILL balance after settle:", b);
        }

        vm.stopBroadcast();
    }
}
