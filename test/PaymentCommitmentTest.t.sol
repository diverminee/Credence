// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EscrowTestBase} from "./EscrowTestBase.sol";
import {EscrowTypes} from "../src/libraries/EscrowTypes.sol";
import {BaseEscrow} from "../src/core/BaseEscrow.sol";
import {TradeInfraEscrow} from "../src/core/TradeInfraEscrow.sol";

/// @notice Tests for PaymentCommitment escrow mode
contract PaymentCommitmentTest is EscrowTestBase {
    uint256 internal constant DEFAULT_COLLATERAL_BPS = 2000; // 20%
    uint256 internal constant BPS_BASE = 10_000;
    uint256 internal constant DEFAULT_MATURITY_DAYS = 60;

    // ── Helpers ────────────────────────────────────────────────

    function _collateralAmount() internal pure returns (uint256) {
        return (ESCROW_AMOUNT * DEFAULT_COLLATERAL_BPS) / BPS_BASE;
    }

    function _remainingAmount() internal pure returns (uint256) {
        return ESCROW_AMOUNT - _collateralAmount();
    }

    function _createPCEscrow() internal returns (uint256 id) {
        vm.prank(buyer);
        id = escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            0,
            0
        );
    }

    function _createPCEscrowERC20() internal returns (uint256 id) {
        vm.prank(buyer);
        id = escrow.createEscrow(
            seller,
            arbiter,
            address(token),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            0,
            0
        );
    }

    function _fundedPCEscrow() internal returns (uint256 id) {
        id = _createPCEscrow();
        vm.prank(buyer);
        escrow.fund{value: _collateralAmount()}(id);
    }

    function _fundedPCEscrowERC20() internal returns (uint256 id) {
        id = _createPCEscrowERC20();
        vm.startPrank(buyer);
        token.approve(address(escrow), _collateralAmount());
        escrow.fund(id);
        vm.stopPrank();
    }

    function _fulfilledPCEscrow() internal returns (uint256 id) {
        id = _fundedPCEscrow();
        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Creation
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_Create_SetsMode() public {
        uint256 id = _createPCEscrow();
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(uint8(txn.mode), uint8(EscrowTypes.EscrowMode.PAYMENT_COMMITMENT));
    }

    function test_PC_Create_SetsCollateral() public {
        uint256 id = _createPCEscrow();
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(txn.collateralAmount, _collateralAmount());
        assertEq(txn.collateralBps, DEFAULT_COLLATERAL_BPS);
    }

    function test_PC_Create_SetsFaceValue() public {
        uint256 id = _createPCEscrow();
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(txn.faceValue, ESCROW_AMOUNT);
        assertEq(txn.amount, ESCROW_AMOUNT);
    }

    function test_PC_Create_SetsMaturityDate() public {
        uint256 id = _createPCEscrow();
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(txn.maturityDate, block.timestamp + DEFAULT_MATURITY_DAYS * 1 days);
    }

    function test_PC_Create_CustomCollateralBps() public {
        vm.prank(buyer);
        uint256 id = escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            0,
            3000 // 30%
        );
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(txn.collateralBps, 3000);
        assertEq(txn.collateralAmount, (ESCROW_AMOUNT * 3000) / BPS_BASE);
    }

    function test_PC_Create_CustomMaturityDays() public {
        vm.prank(buyer);
        uint256 id = escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            90, // 90 days
            0
        );
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(txn.maturityDate, block.timestamp + 90 days);
    }

    function testRevert_PC_Create_CollateralBpsTooLow() public {
        vm.expectRevert(BaseEscrow.InvalidCollateralBps.selector);
        vm.prank(buyer);
        escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            0,
            500 // 5% — below min 10%
        );
    }

    function testRevert_PC_Create_CollateralBpsTooHigh() public {
        vm.expectRevert(BaseEscrow.InvalidCollateralBps.selector);
        vm.prank(buyer);
        escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            0,
            6000 // 60% — above max 50%
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    // Funding — only collateral required
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_Fund_OnlyCollateralRequired() public {
        uint256 id = _createPCEscrow();
        uint256 collateral = _collateralAmount();

        vm.prank(buyer);
        escrow.fund{value: collateral}(id);

        _assertState(id, EscrowTypes.State.FUNDED);
        assertEq(address(escrow).balance, collateral);
    }

    function testRevert_PC_Fund_FullAmountReverts() public {
        uint256 id = _createPCEscrow();
        vm.expectRevert(BaseEscrow.IncorrectETHAmount.selector);
        vm.prank(buyer);
        escrow.fund{value: ESCROW_AMOUNT}(id); // Full amount instead of collateral
    }

    function test_PC_Fund_ERC20_OnlyCollateral() public {
        uint256 id = _createPCEscrowERC20();
        uint256 collateral = _collateralAmount();

        vm.startPrank(buyer);
        token.approve(address(escrow), collateral);
        escrow.fund(id);
        vm.stopPrank();

        _assertState(id, EscrowTypes.State.FUNDED);
        assertEq(token.balanceOf(address(escrow)), collateral);
    }

    // ═══════════════════════════════════════════════════════════════════
    // fulfillCommitment
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_FulfillCommitment_ETH() public {
        uint256 id = _fundedPCEscrow();

        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);

        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertTrue(txn.commitmentFulfilled);
        assertEq(address(escrow).balance, ESCROW_AMOUNT); // Full amount now held
    }

    function test_PC_FulfillCommitment_ERC20() public {
        uint256 id = _fundedPCEscrowERC20();

        vm.startPrank(buyer);
        token.approve(address(escrow), _remainingAmount());
        escrow.fulfillCommitment(id);
        vm.stopPrank();

        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertTrue(txn.commitmentFulfilled);
        assertEq(token.balanceOf(address(escrow)), ESCROW_AMOUNT);
    }

    function test_PC_FulfillCommitment_EmitsEvent() public {
        uint256 id = _fundedPCEscrow();
        uint256 remaining = _remainingAmount();

        vm.expectEmit(true, true, false, true);
        emit TradeInfraEscrow.CommitmentFulfilled(id, buyer, remaining, block.timestamp);
        vm.prank(buyer);
        escrow.fulfillCommitment{value: remaining}(id);
    }

    function testRevert_PC_FulfillCommitment_NotBuyer() public {
        uint256 id = _fundedPCEscrow();
        vm.deal(seller, 10 ether);
        vm.expectRevert(BaseEscrow.OnlyBuyerCanFund.selector);
        vm.prank(seller);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);
    }

    function testRevert_PC_FulfillCommitment_AlreadyFulfilled() public {
        uint256 id = _fulfilledPCEscrow();
        vm.expectRevert(BaseEscrow.CommitmentAlreadyFulfilled.selector);
        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);
    }

    function testRevert_PC_FulfillCommitment_AfterMaturity() public {
        uint256 id = _fundedPCEscrow();
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);
        vm.expectRevert(BaseEscrow.CommitmentOverdue.selector);
        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);
    }

    function testRevert_PC_FulfillCommitment_NotPaymentCommitment() public {
        uint256 id = _fundedETHEscrow(); // CASH_LOCK
        vm.expectRevert(BaseEscrow.NotPaymentCommitmentMode.selector);
        vm.prank(buyer);
        escrow.fulfillCommitment{value: 1}(id);
    }

    function testRevert_PC_FulfillCommitment_WrongState_Draft() public {
        uint256 id = _createPCEscrow();
        vm.expectRevert(BaseEscrow.InvalidState.selector);
        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Release after fulfillment — full face value
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_ConfirmDelivery_AfterFulfillment_FullRelease() public {
        uint256 id = _fulfilledPCEscrow();
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        escrow.confirmDelivery(id);

        _assertState(id, EscrowTypes.State.RELEASED);
        uint256 feeAmount = (ESCROW_AMOUNT * 12) / 1000; // BRONZE 1.2%
        assertEq(seller.balance, sellerBefore + ESCROW_AMOUNT - feeAmount);
        assertEq(feeRecipient.balance, feeAmount);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Release without fulfillment — only collateral
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_ConfirmDelivery_WithoutFulfillment_CollateralOnly() public {
        uint256 id = _fundedPCEscrow();
        uint256 sellerBefore = seller.balance;
        uint256 collateral = _collateralAmount();

        vm.prank(buyer);
        escrow.confirmDelivery(id);

        _assertState(id, EscrowTypes.State.RELEASED);
        uint256 feeAmount = (collateral * 12) / 1000; // Fee on collateral only
        assertEq(seller.balance, sellerBefore + collateral - feeAmount);
        assertEq(feeRecipient.balance, feeAmount);
    }

    // ═══════════════════════════════════════════════════════════════════
    // claimDefaultedCommitment
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_ClaimDefault_AfterMaturity() public {
        uint256 id = _fundedPCEscrow();
        uint256 sellerBefore = seller.balance;
        uint256 collateral = _collateralAmount();

        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);

        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);

        _assertState(id, EscrowTypes.State.RELEASED);
        uint256 feeAmount = (collateral * 12) / 1000;
        assertEq(seller.balance, sellerBefore + collateral - feeAmount);
    }

    function test_PC_ClaimDefault_EmitsEvent() public {
        uint256 id = _fundedPCEscrow();
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);

        vm.expectEmit(true, true, false, true);
        emit TradeInfraEscrow.CommitmentDefaulted(id, seller, _collateralAmount(), block.timestamp);
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);
    }

    function testRevert_PC_ClaimDefault_BeforeMaturity() public {
        uint256 id = _fundedPCEscrow();
        vm.expectRevert(BaseEscrow.CommitmentNotYetOverdue.selector);
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);
    }

    function testRevert_PC_ClaimDefault_NotSeller() public {
        uint256 id = _fundedPCEscrow();
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);
        vm.expectRevert(BaseEscrow.OnlySellerCanClaimDefault.selector);
        vm.prank(buyer);
        escrow.claimDefaultedCommitment(id);
    }

    function testRevert_PC_ClaimDefault_AlreadyFulfilled() public {
        uint256 id = _fulfilledPCEscrow();
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);
        vm.expectRevert(BaseEscrow.CommitmentAlreadyFulfilled.selector);
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);
    }

    function testRevert_PC_ClaimDefault_NotPaymentCommitment() public {
        uint256 id = _fundedETHEscrow(); // CASH_LOCK
        vm.expectRevert(BaseEscrow.NotPaymentCommitmentMode.selector);
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // getMaturityStatus
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_MaturityStatus_NotOverdue() public {
        uint256 id = _fundedPCEscrow();
        (bool isPC, uint256 maturity, bool fulfilled, bool overdue, uint256 remaining) = escrow.getMaturityStatus(id);
        assertTrue(isPC);
        assertEq(maturity, block.timestamp + DEFAULT_MATURITY_DAYS * 1 days);
        assertFalse(fulfilled);
        assertFalse(overdue);
        assertEq(remaining, _remainingAmount());
    }

    function test_PC_MaturityStatus_Overdue() public {
        uint256 id = _fundedPCEscrow();
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);
        (,, bool fulfilled, bool overdue,) = escrow.getMaturityStatus(id);
        assertFalse(fulfilled);
        assertTrue(overdue);
    }

    function test_PC_MaturityStatus_Fulfilled() public {
        uint256 id = _fulfilledPCEscrow();
        (,, bool fulfilled, bool overdue, uint256 remaining) = escrow.getMaturityStatus(id);
        assertTrue(fulfilled);
        assertFalse(overdue);
        assertEq(remaining, 0);
    }

    function test_PC_MaturityStatus_CashLock() public {
        uint256 id = _fundedETHEscrow();
        (bool isPC, uint256 maturity, bool fulfilled, bool overdue, uint256 remaining) = escrow.getMaturityStatus(id);
        assertFalse(isPC);
        assertEq(maturity, 0);
        assertFalse(fulfilled);
        assertFalse(overdue);
        assertEq(remaining, 0);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Refund for unfulfilled commitment — returns collateral only
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_Refund_UnfulfilledCommitment_ReturnsCollateral() public {
        uint256 id = _fundedPCEscrow();
        uint256 buyerBefore = buyer.balance;
        uint256 collateral = _collateralAmount();

        // Raise dispute and resolve in buyer's favor
        vm.prank(buyer);
        escrow.raiseDispute(id);
        vm.prank(arbiter);
        escrow.resolveDispute(id, 2); // Refund to buyer

        _assertState(id, EscrowTypes.State.REFUNDED);
        assertEq(buyer.balance, buyerBefore + collateral);
    }

    function test_PC_Refund_FulfilledCommitment_ReturnsFullAmount() public {
        uint256 id = _fulfilledPCEscrow();
        uint256 buyerBefore = buyer.balance;

        // Raise dispute and resolve in buyer's favor
        vm.prank(buyer);
        escrow.raiseDispute(id);
        vm.prank(arbiter);
        escrow.resolveDispute(id, 2); // Refund to buyer

        _assertState(id, EscrowTypes.State.REFUNDED);
        assertEq(buyer.balance, buyerBefore + ESCROW_AMOUNT);
    }

    // ═══════════════════════════════════════════════════════════════════
    // CASH_LOCK backward compatibility
    // ═══════════════════════════════════════════════════════════════════

    function test_CashLock_DefaultValues() public {
        uint256 id = _createETHEscrow();
        EscrowTypes.EscrowTransaction memory txn = escrow.getEscrow(id);
        assertEq(uint8(txn.mode), uint8(EscrowTypes.EscrowMode.CASH_LOCK));
        assertEq(txn.collateralAmount, ESCROW_AMOUNT);
        assertEq(txn.collateralBps, BPS_BASE);
        assertEq(txn.maturityDate, 0);
        assertFalse(txn.commitmentFulfilled);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Full end-to-end PaymentCommitment flows
    // ═══════════════════════════════════════════════════════════════════

    function test_PC_FullFlow_FulfillAndRelease() public {
        // 1. Create PC escrow
        uint256 id = _createPCEscrow();
        _assertState(id, EscrowTypes.State.DRAFT);

        // 2. Fund with collateral only
        vm.prank(buyer);
        escrow.fund{value: _collateralAmount()}(id);
        _assertState(id, EscrowTypes.State.FUNDED);

        // 3. Fulfill commitment (remaining balance)
        vm.prank(buyer);
        escrow.fulfillCommitment{value: _remainingAmount()}(id);

        // 4. Confirm delivery → full release
        uint256 sellerBefore = seller.balance;
        vm.prank(buyer);
        escrow.confirmDelivery(id);
        _assertState(id, EscrowTypes.State.RELEASED);

        uint256 feeAmount = (ESCROW_AMOUNT * 12) / 1000;
        assertEq(seller.balance, sellerBefore + ESCROW_AMOUNT - feeAmount);
    }

    function test_PC_FullFlow_DefaultAfterMaturity() public {
        // 1. Create and fund PC escrow
        uint256 id = _fundedPCEscrow();

        // 2. Time passes — buyer does NOT fulfill
        vm.warp(block.timestamp + DEFAULT_MATURITY_DAYS * 1 days + 1);

        // 3. Seller claims default
        uint256 sellerBefore = seller.balance;
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);

        _assertState(id, EscrowTypes.State.RELEASED);
        uint256 collateral = _collateralAmount();
        uint256 feeAmount = (collateral * 12) / 1000;
        assertEq(seller.balance, sellerBefore + collateral - feeAmount);
    }
}
