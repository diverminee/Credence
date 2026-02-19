// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EscrowTypes} from "../libraries/EscrowTypes.sol";
import {BaseEscrow} from "./BaseEscrow.sol";

/// @title Dispute Escrow Contract
/// @notice Extends base escrow with dispute resolution functionality
contract DisputeEscrow is BaseEscrow {
    // ============ Errors ============
    error NotAParty();
    error NotTheArbiter();
    error TooManyDisputes();
    error InvalidRuling();

    // ============ Constructor ============
    constructor(
        address _oracleAddress,
        address _feeRecipient
    ) BaseEscrow(_oracleAddress, _feeRecipient) {}

    // ============ Events ============
    event DisputeRaised(uint256 indexed escrowId, address indexed initiator);
    event DisputeResolved(uint256 indexed escrowId, uint8 indexed ruling);

    // ============ Modifiers ============

    /// @notice Verify caller is buyer or seller
    modifier onlyParty(uint256 _escrowId) {
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        EscrowTypes.EscrowTransaction memory txn = escrows[_escrowId];
        if (msg.sender != txn.buyer && msg.sender != txn.seller)
            revert NotAParty();
        _;
    }

    /// @notice Verify caller is the arbiter
    modifier onlyArbiter(uint256 _escrowId) {
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        if (msg.sender != escrows[_escrowId].arbiter) revert NotTheArbiter();
        _;
    }

    /// @notice Raise a dispute on the escrow transaction
    /// @param _escrowId ID of the escrow
    function raiseDispute(
        uint256 _escrowId
    ) external onlyParty(_escrowId) nonReentrant {
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.FUNDED) revert InvalidState();

        address initiator = msg.sender;

        // Check for excessive disputes (prevent abuse)
        // Hard limit: 10+ disputes initiated
        if (disputesInitiated[initiator] >= 10) revert TooManyDisputes();

        // Check loss rate: >50% loss rate with 3+ losses
        uint256 losses = disputesLost[initiator];
        if (losses >= 3) {
            uint256 totalDisputes = disputesInitiated[initiator];
            // Safety: only check rate if user has initiated disputes
            if (totalDisputes > 0 && (losses * 100) / totalDisputes > 50) {
                revert TooManyDisputes();
            }
        }

        // Track dispute initiation
        disputesInitiated[initiator]++;

        escrows[_escrowId].state = EscrowTypes.State.DISPUTED;
        emit DisputeRaised(_escrowId, initiator);
    }

    /// @notice Resolve dispute with arbiter ruling
    /// @param _escrowId ID of the escrow
    /// @param _ruling Ruling (1 = release to seller, 2 = refund to buyer)
    function resolveDispute(
        uint256 _escrowId,
        uint8 _ruling
    ) external onlyArbiter(_escrowId) nonReentrant {
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.DISPUTED) revert InvalidState();

        if (_ruling == 1) {
            // Ruling in favor of seller
            disputesLost[txn.buyer]++;
            _releaseFunds(_escrowId, txn.seller);
        } else if (_ruling == 2) {
            // Ruling in favor of buyer
            disputesLost[txn.seller]++;
            _refundFunds(_escrowId, txn.buyer);
        } else {
            revert InvalidRuling();
        }

        emit DisputeResolved(_escrowId, _ruling);
    }

    /// @notice Check if an address can raise more disputes
    /// @param _user Address to check
    /// @return bool True if user can raise disputes
    function canRaiseDispute(address _user) external view returns (bool) {
        uint256 initiated = disputesInitiated[_user];
        if (initiated >= 10) return false;

        uint256 losses = disputesLost[_user];
        if (losses >= 3) {
            if (initiated > 0 && (losses * 100) / initiated > 50) return false;
        }

        return true;
    }
}
