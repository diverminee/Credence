// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ITradeOracle} from "./interfaces/ITradeOracle.sol";

/// @title Centralized Trade Oracle
/// @notice Owner-controlled registry where a trusted backend submits trade verification results on-chain.
///         The owner (backend EOA or multisig) calls submitVerification() to mark a tradeDataHash as
///         verified or rejected before confirmByOracle() is triggered in the escrow contract.
contract CentralizedTradeOracle is ITradeOracle {
    // ============ State Variables ============
    address public owner;
    mapping(bytes32 => bool) public verifiedTrades;
    mapping(bytes32 => bytes32[]) internal _documentFlags;

    // ============ Errors ============
    error NotOwner();
    error ZeroAddress();

    // ============ Events ============
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TradeVerified(bytes32 indexed tradeDataHash, bool result);

    // ============ Constructor ============
    /// @param _owner Address of the trusted backend that will submit verifications
    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    // ============ Modifiers ============
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ============ Owner Functions ============

    /// @notice Submit the verification result for a trade data hash
    /// @param tradeDataHash The keccak256 hash of the trade data
    /// @param result True if the trade is verified, false otherwise
    function submitVerification(bytes32 tradeDataHash, bool result) external onlyOwner {
        verifiedTrades[tradeDataHash] = result;
        emit TradeVerified(tradeDataHash, result);
    }

    /// @notice Submit verification with per-document flags
    /// @param tradeDataHash The merkle root or trade data hash
    /// @param result Overall verification result
    /// @param documentFlags Ordered bytes32 flags (0x01 = verified, 0x00 = failed) for each document
    function submitVerification(bytes32 tradeDataHash, bool result, bytes32[] calldata documentFlags)
        external
        onlyOwner
    {
        verifiedTrades[tradeDataHash] = result;
        _documentFlags[tradeDataHash] = documentFlags;
        emit TradeVerified(tradeDataHash, result);
    }

    /// @notice Get per-document verification breakdown for a merkle root
    /// @param merkleRoot The merkle root to query
    /// @return overallResult Whether the trade was verified overall
    /// @return documentFlags Per-document verification flags
    function getDocumentVerification(bytes32 merkleRoot)
        external
        view
        returns (bool overallResult, bytes32[] memory documentFlags)
    {
        return (verifiedTrades[merkleRoot], _documentFlags[merkleRoot]);
    }

    /// @notice Transfer ownership to a new address (e.g. multisig handoff)
    /// @param newOwner Address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ============ ITradeOracle ============

    /// @notice Returns true if the trade data hash was marked verified by the owner
    /// @param tradeDataHash The keccak256 hash of the trade data
    function verifyTradeData(bytes32 tradeDataHash) external view returns (bool) {
        return verifiedTrades[tradeDataHash];
    }
}
