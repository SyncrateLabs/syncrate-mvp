// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/kyc/KYCRegistry.sol";
import "../src/tokens/MockUSDC.sol";
import "../src/tokens/OUSGToken.sol";
import "../src/tokens/TBILLToken.sol";
import "../src/core/TBILLIssuerMock.sol";
import "../src/core/OUSGRedemptionMock.sol";
import "../src/core/SettlementExecutor.sol";
import "../src/faucet/SyncrateFaucet.sol";

contract SyncrateCoreTest is Test {
    KYCRegistry public kyc;
    MockUSDC public usdc;
    OUSGToken public ousg;
    TBILLToken public tbill;
    TBILLIssuerMock public tbillIssuer;
    OUSGRedemptionMock public redemption;
    SyncrateFaucet public faucet;
    SettlementExecutor public settlement;

    bytes32 constant OUSG_ID = keccak256("mOUSG");
    bytes32 constant USDC_ID = keccak256("USDC");
    bytes32 constant TBILL_ID = keccak256("mTBILL");

    address constant KYC_PASS = 0x1111111111111111111111111111111111111111;
    address constant KYC_FAIL = 0x2222222222222222222222222222222222222222;

    function setUp() public {
        kyc = new KYCRegistry();
        usdc = new MockUSDC();
        ousg = new OUSGToken(address(kyc), OUSG_ID);
        tbill = new TBILLToken(address(kyc), TBILL_ID);
        tbillIssuer = new TBILLIssuerMock(address(tbill), address(usdc), address(kyc));
        tbill.setIssuer(address(tbillIssuer));
        redemption = new OUSGRedemptionMock(address(ousg), address(usdc), address(kyc), OUSG_ID, USDC_ID);
        faucet = new SyncrateFaucet(address(ousg), address(usdc), address(kyc), OUSG_ID, USDC_ID);
        settlement = new SettlementExecutor(
            address(tbill), address(ousg), address(usdc), address(kyc),
            TBILL_ID, OUSG_ID, USDC_ID, address(tbillIssuer), address(redemption)
        );

        ousg.grantRole(ousg.BURNER_ROLE(), address(settlement));
        usdc.grantRole(usdc.MINTER_ROLE(), address(settlement));
        usdc.grantRole(usdc.MINTER_ROLE(), address(redemption));
        usdc.grantRole(usdc.MINTER_ROLE(), address(faucet));
        ousg.grantRole(ousg.MINTER_ROLE(), address(faucet));
        ousg.grantRole(ousg.BURNER_ROLE(), address(redemption));

        kyc.setKYC(KYC_PASS, OUSG_ID, true);
        kyc.setKYC(KYC_PASS, USDC_ID, true);
        kyc.setKYC(KYC_PASS, TBILL_ID, true);
        kyc.setKYC(KYC_FAIL, OUSG_ID, false);
        kyc.setKYC(KYC_FAIL, USDC_ID, false);
        kyc.setKYC(KYC_FAIL, TBILL_ID, false);
    }

    function test_KYC_Check() public {
        assertTrue(kyc.isAllowed(KYC_PASS, OUSG_ID));
        assertFalse(kyc.isAllowed(KYC_FAIL, OUSG_ID));
    }

    function test_Faucet() public {
        vm.prank(KYC_PASS);
        faucet.drip();
        assertEq(ousg.balanceOf(KYC_PASS), 1000 ether);
        assertEq(usdc.balanceOf(KYC_PASS), 1000 * 1e6);
    }

    function test_SettlementBase() public {
        vm.prank(KYC_PASS);
        faucet.drip();

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Base);

        assertEq(ousg.balanceOf(KYC_PASS), 900 ether);
        assertEq(tbill.balanceOf(KYC_PASS), 100 ether);
    }

    function test_SettlementArbitrum() public {
        vm.prank(KYC_PASS);
        faucet.drip();

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Arbitrum);

        assertEq(ousg.balanceOf(KYC_PASS), 900 ether);
        assertEq(tbill.balanceOf(KYC_PASS), 100 ether);
    }

    function test_ReplayProtection() public {
        vm.prank(KYC_PASS);
        faucet.drip();

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Base);

        vm.prank(KYC_PASS);
        vm.expectRevert("Settlement: already processed");
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Base);
    }

    function test_MultiChainSupport() public {
        vm.prank(KYC_PASS);
        faucet.drip();

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Base);
        assertEq(tbill.balanceOf(KYC_PASS), 100 ether);

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 100 ether, SettlementExecutor.Chain.Arbitrum);
        assertEq(tbill.balanceOf(KYC_PASS), 200 ether);
    }

    function test_SettlementKYCRequired() public {
        vm.prank(address(0x999));
        ousg.grantRole(ousg.MINTER_ROLE(), address(0x999));
        ousg.mint(KYC_FAIL, 100 ether);

        vm.prank(KYC_FAIL);
        vm.expectRevert("Settlement: KYC fail");
        settlement.settle(KYC_FAIL, 100 ether, SettlementExecutor.Chain.Base);
    }

    function test_TokenMechanics() public {
        vm.prank(address(this));
        ousg.grantRole(ousg.MINTER_ROLE(), address(this));
        ousg.mint(KYC_PASS, 100 ether);
        assertEq(ousg.balanceOf(KYC_PASS), 100 ether);

        vm.prank(KYC_PASS);
        ousg.transfer(KYC_PASS, 50 ether);
        assertEq(ousg.balanceOf(KYC_PASS), 100 ether);
    }
}
