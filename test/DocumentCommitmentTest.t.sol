// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EscrowTestBase} from "./EscrowTestBase.sol";
import {EscrowTypes} from "../src/libraries/EscrowTypes.sol";
import {BaseEscrow} from "../src/core/BaseEscrow.sol";
import {TradeInfraEscrow} from "../src/core/TradeInfraEscrow.sol";

/// @notice Tests for Merkle document commitment system
contract DocumentCommitmentTest is EscrowTestBase {
    // ═══════════════════════════════════════════════════════════════════
    // commitDocuments — happy path
    // ═══════════════════════════════════════════════════════════════════

    function test_CommitDocuments_AllFourDocs() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);

        (
            bytes32 invoiceHash,
            bytes32 bolHash,
            bytes32 packingHash,
            bytes32 cooHash,
            bytes32 merkleRoot,
            uint256 committedAt
        ) = escrow.escrowDocuments(id);

        assertEq(invoiceHash, INVOICE_HASH);
        assertEq(bolHash, BOL_HASH);
        assertEq(packingHash, PACKING_HASH);
        assertEq(cooHash, COO_HASH);
        assertTrue(merkleRoot != bytes32(0));
        assertEq(committedAt, block.timestamp);
    }

    function test_CommitDocuments_ThreeDocsOptionalCOO() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, bytes32(0));

        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertTrue(merkleRoot != bytes32(0));
    }

    function test_CommitDocuments_EmitsEvent() public {
        uint256 id = _fundedETHEscrow();

        // We can't predict the exact merkle root in expectEmit, so just check indexed fields
        vm.expectEmit(true, false, false, false);
        emit BaseEscrow.DocumentsCommitted(id, bytes32(0), 0); // topic match only
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);
    }

    // ═══════════════════════════════════════════════════════════════════
    // commitDocuments — reverts
    // ═══════════════════════════════════════════════════════════════════

    function testRevert_CommitDocuments_NotFunded() public {
        uint256 id = _createETHEscrow();
        vm.expectRevert(BaseEscrow.InvalidState.selector);
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);
    }

    function testRevert_CommitDocuments_NotSeller() public {
        uint256 id = _fundedETHEscrow();
        vm.expectRevert(BaseEscrow.OnlySellerCanCommitDocuments.selector);
        vm.prank(buyer);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);
    }

    function testRevert_CommitDocuments_AlreadyCommitted() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);

        vm.expectRevert(BaseEscrow.DocumentsAlreadyCommitted.selector);
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);
    }

    function testRevert_CommitDocuments_NoHashes() public {
        uint256 id = _fundedETHEscrow();
        vm.expectRevert(BaseEscrow.NoDocumentHashes.selector);
        vm.prank(seller);
        escrow.commitDocuments(id, bytes32(0), bytes32(0), bytes32(0), bytes32(0));
    }

    function testRevert_CommitDocuments_EscrowNotFound() public {
        vm.expectRevert(BaseEscrow.EscrowNotFound.selector);
        vm.prank(seller);
        escrow.commitDocuments(999, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);
    }

    // ═══════════════════════════════════════════════════════════════════
    // Merkle root correctness — known vectors
    // ═══════════════════════════════════════════════════════════════════

    function test_MerkleRoot_FourLeaves() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, COO_HASH);

        // Manual computation: 4-leaf Merkle tree
        bytes32 left = keccak256(abi.encodePacked(INVOICE_HASH, BOL_HASH));
        bytes32 right = keccak256(abi.encodePacked(PACKING_HASH, COO_HASH));
        bytes32 expectedRoot = keccak256(abi.encodePacked(left, right));

        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertEq(merkleRoot, expectedRoot, "4-leaf merkle root mismatch");
    }

    function test_MerkleRoot_ThreeLeaves() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, PACKING_HASH, bytes32(0));

        // Manual computation: 3-leaf Merkle tree (odd leaf promoted)
        bytes32 left = keccak256(abi.encodePacked(INVOICE_HASH, BOL_HASH));
        bytes32 expectedRoot = keccak256(abi.encodePacked(left, PACKING_HASH));

        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertEq(merkleRoot, expectedRoot, "3-leaf merkle root mismatch");
    }

    function test_MerkleRoot_TwoLeaves() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, BOL_HASH, bytes32(0), bytes32(0));

        bytes32 expectedRoot = keccak256(abi.encodePacked(INVOICE_HASH, BOL_HASH));

        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertEq(merkleRoot, expectedRoot, "2-leaf merkle root mismatch");
    }

    function test_MerkleRoot_OneLeaf() public {
        uint256 id = _fundedETHEscrow();
        vm.prank(seller);
        escrow.commitDocuments(id, INVOICE_HASH, bytes32(0), bytes32(0), bytes32(0));

        // Single leaf: root = leaf
        (,,,, bytes32 merkleRoot,) = escrow.escrowDocuments(id);
        assertEq(merkleRoot, INVOICE_HASH, "1-leaf merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    // Oracle confirmation with documents
    // ═══════════════════════════════════════════════════════════════════

    function test_OracleConfirm_WithDocuments_Succeeds() public {
        oracle.setVerifyResult(true);
        uint256 id = _fundedETHEscrow();
        _commitDocuments(id);

        uint256 sellerBefore = seller.balance;
        escrow.confirmByOracle(id);

        _assertState(id, EscrowTypes.State.RELEASED);
        assertTrue(seller.balance > sellerBefore);
    }

    function testRevert_OracleConfirm_WithoutDocuments_Reverts() public {
        oracle.setVerifyResult(true);
        uint256 id = _fundedETHEscrow();

        vm.expectRevert(TradeInfraEscrow.DocumentsNotCommitted.selector);
        escrow.confirmByOracle(id);
    }
}
