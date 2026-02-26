// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Trade Oracle Interface
/// @notice Interface for verifying trade data authenticity
interface ITradeOracle {
    /// @notice Verify trade data authenticity
    /// @param tradeDataHash Hash of trade data
    /// @return bool True if trade data is valid
    function verifyTradeData(bytes32 tradeDataHash) external view returns (bool);

    /// @notice Verify trade data with individual document hashes (SECURITY FIX)
    /// @param tradeDataHash Original trade data hash
    /// @param invoiceHash Hash of commercial invoice
    /// @param bolHash Hash of bill of lading
    /// @param packingHash Hash of packing list
    /// @param cooHash Hash of certificate of origin
    /// @return bool True if all document hashes are valid
    function verifyTradeDataWithDocuments(
        bytes32 tradeDataHash,
        bytes32 invoiceHash,
        bytes32 bolHash,
        bytes32 packingHash,
        bytes32 cooHash
    ) external view returns (bool);
}
