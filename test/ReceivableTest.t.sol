// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EscrowTestBase} from "./EscrowTestBase.sol";
import {EscrowTypes} from "../src/libraries/EscrowTypes.sol";
import {BaseEscrow} from "../src/core/BaseEscrow.sol";
import {CredenceReceivable} from "../src/CredenceReceivable.sol";
import {IReceivableMinter} from "../src/interfaces/IReceivableMinter.sol";

/// @notice A mock minter that always reverts (for testing try/catch resilience)
contract FailingMinter is IReceivableMinter {
    function mintReceivable(uint256, address, uint256, uint256, bytes32, address) external pure returns (uint256) {
        revert("MINT_FAILED");
    }

    function settleReceivable(uint256) external pure {
        revert("SETTLE_FAILED");
    }
}

/// @notice Tests for Receivable NFT minting hook
contract ReceivableTest is EscrowTestBase {
    CredenceReceivable internal receivable;

    function setUp() public override {
        super.setUp();
        receivable = new CredenceReceivable(address(escrow));
        escrow.setReceivableMinter(address(receivable));
    }

    // ═══════════════════════════════════════════════════════════════════
    // Helper: create a funded PAYMENT_COMMITMENT escrow
    // ═══════════════════════════════════════════════════════════════════

    function _fundedPCEscrow() internal returns (uint256 id) {
        vm.prank(buyer);
        id = escrow.createEscrow(
            seller,
            arbiter,
            address(0),
            ESCROW_AMOUNT,
            TRADE_ID,
            TRADE_DATA_HASH,
            EscrowTypes.EscrowMode.PAYMENT_COMMITMENT,
            60,
            2000
        );
        // Fund with collateral (20% of 1e18 = 0.2e18)
        uint256 collateral = (ESCROW_AMOUNT * 2000) / 10_000;
        vm.prank(buyer);
        escrow.fund{value: collateral}(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Minting hook fires on PAYMENT_COMMITMENT document commit
    // ═══════════════════════════════════════════════════════════════════

    function test_Receivable_MintedOnCommitDocuments() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);
        assertTrue(tokenId != 0, "receivable should be minted");
        assertEq(receivable.ownerOf(tokenId), seller, "NFT should belong to seller");
    }

    function test_Receivable_MetadataCorrect() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);
        CredenceReceivable.ReceivableData memory data = receivable.getReceivableData(tokenId);

        assertEq(data.escrowId, id);
        assertEq(data.faceValue, ESCROW_AMOUNT);
        assertEq(data.paymentToken, address(0));
        assertFalse(data.isSettled);
        assertTrue(data.maturityDate > block.timestamp);
        assertTrue(data.documentMerkleRoot != bytes32(0));
    }

    function test_Receivable_TokenURIReturnsJSON() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);
        string memory uri = receivable.tokenURI(tokenId);
        // Should start with data:application/json;base64,
        assertTrue(bytes(uri).length > 35, "tokenURI should be non-empty");
    }

    function test_Receivable_EmitsMintedEvent() public {
        uint256 id = _fundedPCEscrow();

        vm.expectEmit(true, false, false, false);
        emit BaseEscrow.ReceivableMinted(id, 0); // topic match only
        _commitDocuments(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // NOT minted for CASH_LOCK escrows
    // ═══════════════════════════════════════════════════════════════════

    function test_Receivable_NotMintedForCashLock() public {
        uint256 id = _fundedETHEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);
        assertEq(tokenId, 0, "receivable should NOT be minted for CASH_LOCK");
    }

    // ═══════════════════════════════════════════════════════════════════
    // Minting failure does NOT revert the trade
    // ═══════════════════════════════════════════════════════════════════

    function test_Receivable_MintFailureDoesNotRevert() public {
        // Replace minter with a failing one
        FailingMinter failing = new FailingMinter();
        escrow.setReceivableMinter(address(failing));

        uint256 id = _fundedPCEscrow();

        // This should NOT revert even though minting fails
        _commitDocuments(id);

        // Documents should still be committed
        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertTrue(merkleRoot != bytes32(0), "documents should be committed despite mint failure");

        // Token ID should be 0 (mint failed)
        assertEq(escrow.getReceivableTokenId(id), 0, "tokenId should be 0 on mint failure");
    }

    function test_Receivable_MintFailureEmitsEvent() public {
        FailingMinter failing = new FailingMinter();
        escrow.setReceivableMinter(address(failing));

        uint256 id = _fundedPCEscrow();

        vm.expectEmit(true, false, false, false);
        emit BaseEscrow.ReceivableMintFailed(id, "");
        _commitDocuments(id);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Settlement on escrow release
    // ═══════════════════════════════════════════════════════════════════

    function test_Receivable_SettledOnConfirmDelivery() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);
        assertFalse(receivable.getReceivableData(tokenId).isSettled);

        // Buyer confirms delivery
        vm.prank(buyer);
        escrow.confirmDelivery(id);

        assertTrue(receivable.getReceivableData(tokenId).isSettled, "receivable should be settled");
    }

    function test_Receivable_SettledOnOracleConfirm() public {
        oracle.setVerifyResult(true);
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);

        escrow.confirmByOracle(id);

        assertTrue(receivable.getReceivableData(tokenId).isSettled, "receivable should be settled");
    }

    function test_Receivable_SettledOnRefund() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);

        // Raise dispute, then resolve in buyer's favor (refund)
        vm.prank(buyer);
        escrow.raiseDispute(id);
        vm.prank(arbiter);
        escrow.resolveDispute(id, 2); // refund to buyer

        assertTrue(receivable.getReceivableData(tokenId).isSettled, "receivable should be settled on refund");
    }

    function test_Receivable_SettledOnDefaultClaim() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        uint256 tokenId = escrow.getReceivableTokenId(id);

        // Warp past maturity and claim default
        vm.warp(block.timestamp + 61 days);
        vm.prank(seller);
        escrow.claimDefaultedCommitment(id);

        assertTrue(receivable.getReceivableData(tokenId).isSettled, "receivable should be settled on default");
    }

    // ═══════════════════════════════════════════════════════════════════
    // Access control
    // ═══════════════════════════════════════════════════════════════════

    function testRevert_Receivable_OnlyEscrowCanMint() public {
        vm.expectRevert(CredenceReceivable.OnlyEscrow.selector);
        vm.prank(stranger);
        receivable.mintReceivable(0, seller, 1e18, block.timestamp + 60 days, bytes32(uint256(1)), address(0));
    }

    function testRevert_Receivable_OnlyEscrowCanSettle() public {
        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);
        uint256 tokenId = escrow.getReceivableTokenId(id);

        vm.expectRevert(CredenceReceivable.OnlyEscrow.selector);
        vm.prank(stranger);
        receivable.settleReceivable(tokenId);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Minter configuration
    // ═══════════════════════════════════════════════════════════════════

    function test_Receivable_DisabledWhenMinterIsZero() public {
        escrow.setReceivableMinter(address(0));

        uint256 id = _fundedPCEscrow();
        _commitDocuments(id);

        assertEq(escrow.getReceivableTokenId(id), 0, "no receivable when minter disabled");
    }

    function test_Receivable_SetMinterEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit BaseEscrow.ReceivableMinterUpdated(address(receivable), address(0));
        escrow.setReceivableMinter(address(0));
    }

    function testRevert_Receivable_SetMinterNotOwner() public {
        vm.expectRevert(BaseEscrow.NotOwner.selector);
        vm.prank(stranger);
        escrow.setReceivableMinter(address(0));
    }
}
