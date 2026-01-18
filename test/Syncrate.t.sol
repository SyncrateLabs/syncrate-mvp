// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/kyc/KYCRegistry.sol";
import "../src/tokens/MockUSDC.sol";
import "../src/tokens/OUSGToken.sol";
import "../src/tokens/TBILLToken.sol";
import "../src/core/TBILLIssuerMock.sol";
import "../src/core/OUSGRedemptionMock.sol";
import "../src/core/SettlementExecutor.sol";
import "../src/faucet/SyncrateFaucet.sol";

contract SyncrateMVPTest is Test {
    // Contracts
    KYCRegistry public kyc;
    MockUSDC public usdc;
    OUSGToken public ousg;
    TBILLToken public tbill;
    TBILLIssuerMock public tbillIssuer;
    OUSGRedemptionMock public redemption;
    SyncrateFaucet public faucet;
    SettlementExecutor public settlement;

    // Asset IDs
    bytes32 constant OUSG_ID = keccak256("mOUSG");
    bytes32 constant USDC_ID = keccak256("USDC");
    bytes32 constant TBILL_ID = keccak256("mTBILL");

    // Test accounts
    address constant KYC_PASS = 0x1111111111111111111111111111111111111111;
    address constant KYC_FAIL = 0x2222222222222222222222222222222222222222;
    address user1 = address(0x1001);
    address user2 = address(0x1002);
    address user3 = address(0x1003);
    address deployer = address(this);

    event RouteStarted(address indexed user, uint256 amount, SettlementExecutor.Chain indexed chain);
    event Redeemed(address indexed user, uint256 amount);
    event Issued(address indexed user, uint256 amount, SettlementExecutor.Chain indexed chain);
    event RouteCompleted(address indexed user, uint256 amount, SettlementExecutor.Chain indexed chain);
    event RouteFailed(address indexed user, string reason);
    event FaucetDrip(address indexed user);

    function setUp() public {
        // Deploy KYC
        kyc = new KYCRegistry();

        // Deploy tokens
        usdc = new MockUSDC();
        ousg = new OUSGToken(address(kyc), OUSG_ID);
        tbill = new TBILLToken(address(kyc), TBILL_ID);

        // Deploy issuers
        tbillIssuer = new TBILLIssuerMock(address(tbill), address(usdc), address(kyc));
        tbill.setIssuer(address(tbillIssuer));

        redemption = new OUSGRedemptionMock(address(ousg), address(usdc), address(kyc), OUSG_ID, USDC_ID);

        // Deploy faucet
        faucet = new SyncrateFaucet(address(ousg), address(usdc), address(kyc), OUSG_ID, USDC_ID);

        // Deploy settlement executor
        settlement = new SettlementExecutor(
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

        // Grant roles
        ousg.grantRole(ousg.BURNER_ROLE(), address(settlement));
        usdc.grantRole(usdc.MINTER_ROLE(), address(settlement));

        usdc.grantRole(usdc.MINTER_ROLE(), address(redemption));
        usdc.grantRole(usdc.MINTER_ROLE(), address(faucet));

        ousg.grantRole(ousg.MINTER_ROLE(), address(faucet));
        ousg.grantRole(ousg.BURNER_ROLE(), address(redemption));

        // Set KYC
        kyc.setKYC(KYC_PASS, OUSG_ID, true);
        kyc.setKYC(KYC_PASS, USDC_ID, true);
        kyc.setKYC(KYC_PASS, TBILL_ID, true);

        kyc.setKYC(KYC_FAIL, OUSG_ID, false);
        kyc.setKYC(KYC_FAIL, USDC_ID, false);
        kyc.setKYC(KYC_FAIL, TBILL_ID, false);

        // Set KYC for test users
        kyc.setKYC(user1, OUSG_ID, true);
        kyc.setKYC(user1, USDC_ID, true);
        kyc.setKYC(user1, TBILL_ID, true);

        kyc.setKYC(user2, OUSG_ID, true);
        kyc.setKYC(user2, USDC_ID, true);
        kyc.setKYC(user2, TBILL_ID, true);

        kyc.setKYC(user3, OUSG_ID, true);
        kyc.setKYC(user3, USDC_ID, true);
        kyc.setKYC(user3, TBILL_ID, true);
    }

    // ==================== KYC TESTS ====================

    function test_KYC_IsAllowed() public {
        assertTrue(kyc.isAllowed(KYC_PASS, OUSG_ID));
        assertFalse(kyc.isAllowed(KYC_FAIL, OUSG_ID));
    }

    function test_KYC_SetAndUnset() public {
        kyc.setKYC(address(0x123), OUSG_ID, true);
        assertTrue(kyc.isAllowed(address(0x123), OUSG_ID));

        kyc.setKYC(address(0x123), OUSG_ID, false);
        assertFalse(kyc.isAllowed(address(0x123), OUSG_ID));
    }

    // ==================== FAUCET TESTS ====================

    function test_Faucet_Drip_Success() public {
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1); // Ensure cooldown is met
        faucet.drip();

        assertEq(ousg.balanceOf(KYC_PASS), 1000 ether);
        assertEq(usdc.balanceOf(KYC_PASS), 1000 * 1e6);
    }

    function test_Faucet_Drip_FailsWhenNotKYC() public {
        vm.prank(KYC_FAIL);
        vm.warp(block.timestamp + 1);
        vm.expectRevert("Faucet: OUSG KYC fail");
        faucet.drip();
    }

    function test_Faucet_Cooldown() public {
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        vm.prank(KYC_PASS);
        vm.expectRevert("Faucet: cooldown active");
        faucet.drip();

        // Wait 1 hour
        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(KYC_PASS);
        faucet.drip(); // Should succeed
    }

    // ==================== SETTLEMENT ROUTE TESTS ====================

    function test_Settlement_FullRoute_Base() public {
        // Setup: Get tokens from faucet
        vm.prank(user1);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        uint256 amount = 100 ether;
        assertEq(ousg.balanceOf(user1), 1000 ether);

        // Route: Call settlement with Base chain
        vm.prank(user1);
        settlement.settle(user1, amount, SettlementExecutor.Chain.Base);

        // Verify: OUSG burned, TBILL minted
        assertEq(ousg.balanceOf(user1), 1000 ether - amount, "OUSG not burned");
        assertEq(tbill.balanceOf(user1), amount, "TBILL not minted");
    }

    function test_Settlement_FullRoute_Arbitrum() public {
        // Setup: Get tokens from faucet
        vm.prank(user2);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        uint256 amount = 100 ether;

        // Route: Call settlement with Arbitrum chain
        vm.prank(user2);
        settlement.settle(user2, amount, SettlementExecutor.Chain.Arbitrum);

        // Verify: OUSG burned, TBILL minted
        assertEq(ousg.balanceOf(user2), 1000 ether - amount, "OUSG not burned");
        assertEq(tbill.balanceOf(user2), amount, "TBILL not minted");
    }

    function test_Settlement_FailsWhenNotKYC() public {
        // Setup: Give tokens to KYC_FAIL directly (bypass faucet)
        vm.prank(deployer);
        ousg.grantRole(ousg.MINTER_ROLE(), deployer);
        ousg.mint(KYC_FAIL, 100 ether);

        // Try to route: Should fail because KYC_FAIL doesn't have TBILL approval
        vm.prank(KYC_FAIL);
        vm.expectRevert("Settlement: KYC fail");
        settlement.settle(KYC_FAIL, 100 ether, SettlementExecutor.Chain.Base);
    }

    function test_Settlement_ReplayProtection() public {
        // Setup: Get tokens
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        uint256 amount = 100 ether;

        // First call: Success
        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        // Second call with same params: Should fail
        vm.prank(KYC_PASS);
        vm.expectRevert("Settlement: already processed");
        settlement.settle(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        // Different amount: Should succeed
        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, amount + 1, SettlementExecutor.Chain.Base);
    }

    // ==================== MULTI-CHAIN TESTS ====================

    function test_MultiChain_DifferentChainsRequireDifferentRoutes() public {
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        uint256 amount = 100 ether;

        // Route on Base
        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        uint256 tbillAfterBase = tbill.balanceOf(KYC_PASS);
        assertEq(tbillAfterBase, amount);

        // Route same amount on Arbitrum (different chain enum = different hash)
        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, amount, SettlementExecutor.Chain.Arbitrum);

        uint256 tbillAfterArb = tbill.balanceOf(KYC_PASS);
        assertEq(tbillAfterArb, amount * 2, "Should have minted TBILL for both chains");
    }

    // ==================== TOKEN MECHANICS TESTS ====================

    function test_OUSGToken_KYCGated() public {
        // KYC_PASS can mint
        vm.prank(deployer);
        ousg.grantRole(ousg.MINTER_ROLE(), deployer);
        ousg.mint(KYC_PASS, 100 ether);
        assertEq(ousg.balanceOf(KYC_PASS), 100 ether);

        // KYC_FAIL cannot receive
        vm.expectRevert("OUSG: KYC fail");
        vm.prank(deployer);
        ousg.mint(KYC_FAIL, 100 ether);
    }

    function test_TBILLToken_OnlyIssuerCanMint() public {
        // Only tbillIssuer can mint
        vm.expectRevert("TBILL: only issuer");
        vm.prank(address(0x999));
        tbill.mint(KYC_PASS, 100 ether);

        // Issuer can mint
        vm.prank(address(tbillIssuer));
        tbill.mint(KYC_PASS, 100 ether);
        assertEq(tbill.balanceOf(KYC_PASS), 100 ether);
    }

    function test_MockUSDC_MinterOnly() public {
        // Non-minter cannot mint
        vm.expectRevert();
        vm.prank(address(0x999));
        usdc.mint(KYC_PASS, 1000 * 1e6);
    }

    // ==================== EVENT TESTS ====================

    function test_Settlement_EmitsAllEvents() public {
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        uint256 amount = 100 ether;

        vm.expectEmit(true, true, false, true);
        emit RouteStarted(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        vm.expectEmit(true, false, false, true);
        emit Redeemed(KYC_PASS, amount);

        vm.expectEmit(true, true, false, true);
        emit Issued(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        vm.expectEmit(true, true, false, true);
        emit RouteCompleted(KYC_PASS, amount, SettlementExecutor.Chain.Base);

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, amount, SettlementExecutor.Chain.Base);
    }

    // ==================== EDGE CASES ====================

    function test_Settlement_WithZeroAmount() public {
        vm.prank(KYC_PASS);
        vm.warp(block.timestamp + 1);
        faucet.drip();

        // Zero amount should still work
        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 0, SettlementExecutor.Chain.Base);

        assertEq(tbill.balanceOf(KYC_PASS), 0);
    }

    function test_Settlement_WithLargeAmount() public {
        vm.prank(deployer);
        ousg.grantRole(ousg.MINTER_ROLE(), deployer);
        ousg.mint(KYC_PASS, 10000 ether);

        vm.prank(KYC_PASS);
        settlement.settle(KYC_PASS, 10000 ether, SettlementExecutor.Chain.Base);

        assertEq(tbill.balanceOf(KYC_PASS), 10000 ether);
    }
}
