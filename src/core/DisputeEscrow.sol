// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EscrowTypes} from "../libraries/EscrowTypes.sol";
import {BaseEscrow} from "./BaseEscrow.sol";

/// @title Dispute Escrow Contract
/// @notice Extends base escrow with dispute resolution functionality
contract DisputeEscrow is BaseEscrow {
    // ============ Errors ============
    error NotAParty();
    error NotTheArbiter();
    error NotProtocolArbiter();
    error TooManyDisputes();
    error InvalidRuling();
    error ArbiterDeadlineExpired();
    error DisputeNotExpired();
    error EscalationNotExpired();
    error NotEscalated();

    // ============ Constructor ============
    constructor(
        address _oracleAddress,
        address _feeRecipient,
        address _protocolArbiter
    ) BaseEscrow(_oracleAddress, _feeRecipient, _protocolArbiter) {}

    // ============ Events ============
    event DisputeRaised(
        uint256 indexed escrowId,
        address indexed initiator,
        uint256 deadline,
        uint256 timestamp
    );
    event DisputeResolved(
        uint256 indexed escrowId,
        uint8 ruling,
        address indexed arbiter,
        uint256 timestamp
    );
    event DisputeEscalated(
        uint256 indexed escrowId,
        address indexed escalatedBy,
        uint256 newDeadline,
        uint256 timestamp
    );
    event EscalationResolved(
        uint256 indexed escrowId,
        uint8 indexed ruling,
        uint256 timestamp
    );
    event TimeoutClaimed(
        uint256 indexed escrowId,
        address indexed claimedBy,
        address indexed refundedTo,
        uint256 timestamp
    );

    // ============ Modifiers ============

    modifier onlyParty(uint256 _escrowId) {
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        EscrowTypes.EscrowTransaction memory txn = escrows[_escrowId];
        if (msg.sender != txn.buyer && msg.sender != txn.seller)
            revert NotAParty();
        _;
    }

    modifier onlyArbiter(uint256 _escrowId) {
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        if (msg.sender != escrows[_escrowId].arbiter) revert NotTheArbiter();
        _;
    }

    function raiseDispute(
        uint256 _escrowId
    ) external onlyParty(_escrowId) nonReentrant {
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.FUNDED) revert InvalidState();

        address initiator = msg.sender;

        if (disputesInitiated[initiator] >= 10) revert TooManyDisputes();

        uint256 losses = disputesLost[initiator];
        if (losses >= 3) {
            uint256 totalDisputes = disputesInitiated[initiator];
            if (totalDisputes == 0 || (losses * 100) / totalDisputes > 50) {
                revert TooManyDisputes();
            }
        }

        disputesInitiated[initiator]++;

        txn.disputeDeadline = block.timestamp + DISPUTE_TIMELOCK;
        txn.state = EscrowTypes.State.DISPUTED;
        emit DisputeRaised(
            _escrowId,
            initiator,
            txn.disputeDeadline,
            block.timestamp
        );
    }

    function resolveDispute(
        uint256 _escrowId,
        uint8 _ruling
    ) external onlyArbiter(_escrowId) nonReentrant {
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.DISPUTED) revert InvalidState();
        if (block.timestamp > txn.disputeDeadline)
            revert ArbiterDeadlineExpired();

        if (_ruling == 1) {
            disputesLost[txn.buyer]++;
            _releaseFunds(_escrowId, txn.seller);
        } else if (_ruling == 2) {
            disputesLost[txn.seller]++;
            _refundFunds(_escrowId, txn.buyer);
        } else {
            revert InvalidRuling();
        }

        emit DisputeResolved(_escrowId, _ruling, msg.sender, block.timestamp);
    }

    function escalateToProtocol(
        uint256 _escrowId
    ) external onlyParty(_escrowId) nonReentrant {
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.DISPUTED) revert InvalidState();
        if (block.timestamp < txn.disputeDeadline) revert DisputeNotExpired();

        txn.state = EscrowTypes.State.ESCALATED;
        txn.disputeDeadline = block.timestamp + ESCALATION_TIMELOCK;

        emit DisputeEscalated(_escrowId, msg.sender, txn.disputeDeadline, block.timestamp);
    }

    function resolveEscalation(
        uint256 _escrowId,
        uint8 _ruling
    ) external nonReentrant {
        if (msg.sender != protocolArbiter) revert NotProtocolArbiter();
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.ESCALATED) revert NotEscalated();

        if (_ruling == 1) {
            disputesLost[txn.buyer]++;
            _releaseFunds(_escrowId, txn.seller);
        } else if (_ruling == 2) {
            disputesLost[txn.seller]++;
            _refundFunds(_escrowId, txn.buyer);
        } else {
            revert InvalidRuling();
        }

        emit EscalationResolved(_escrowId, _ruling, block.timestamp);
    }

    function claimTimeout(uint256 _escrowId) external nonReentrant {
        if (!escrowExists[_escrowId]) revert EscrowNotFound();
        EscrowTypes.EscrowTransaction storage txn = escrows[_escrowId];
        if (txn.state != EscrowTypes.State.ESCALATED) revert NotEscalated();
        if (block.timestamp < txn.disputeDeadline)
            revert EscalationNotExpired();

        address buyerAddr = txn.buyer;
        _refundFunds(_escrowId, buyerAddr);

        emit TimeoutClaimed(_escrowId, msg.sender, buyerAddr, block.timestamp);
    }

    function canRaiseDispute(address _user) external view returns (bool) {
        uint256 initiated = disputesInitiated[_user];
        if (initiated >= 10) return false;

        uint256 losses = disputesLost[_user];
        if (losses >= 3) {
            if (initiated == 0 || (losses * 100) / initiated > 50) return false;
        }

        return true;
    }
}
