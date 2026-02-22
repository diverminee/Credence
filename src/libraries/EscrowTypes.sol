// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Escrow Types Library
/// @notice Shared types and enums for escrow system
library EscrowTypes {
    // ============ Enums ============
    enum State {
        DRAFT,
        FUNDED,
        RELEASED,
        REFUNDED,
        DISPUTED,
        ESCALATED // Escalated to protocol arbiter after primary arbiter timeout

    }

    enum UserTier {
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND
    }

    enum DeploymentTier {
        TESTNET,
        LAUNCH,
        GROWTH,
        MATURE
    }

    enum EscrowMode {
        CASH_LOCK,
        PAYMENT_COMMITMENT
    }

    // ============ Structs ============

    /// @notice Trade document commitment data with Merkle root
    struct DocumentSet {
        bytes32 invoiceHash;
        bytes32 bolHash;
        bytes32 packingHash;
        bytes32 cooHash;
        bytes32 merkleRoot;
        uint256 committedAt;
    }

    /// @notice Core escrow transaction data
    struct EscrowTransaction {
        address buyer;
        address seller;
        address arbiter;
        address token; // address(0) for ETH, otherwise ERC20 token address
        uint256 amount;
        uint256 tradeId; // External trade identifier
        bytes32 tradeDataHash; // Hash of trade documents
        State state;
        uint256 disputeDeadline; // Deadline for current arbiter to act (0 when not disputed)
        uint256 feeRate; // Fee rate snapshot at creation (basis points / 1000)
        EscrowMode mode;
        uint256 faceValue;
        uint256 collateralAmount;
        uint256 collateralBps;
        uint256 maturityDate;
        bool commitmentFulfilled;
    }
}
