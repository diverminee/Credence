// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ITradeOracle} from "../../src/interfaces/ITradeOracle.sol";

/// @notice Mock oracle that only verifies a specific hash (for testing merkle root verification)
contract HashSpecificMockOracle is ITradeOracle {
    bytes32 public verifiedHash;

    function setVerifiedHash(bytes32 _hash) external {
        verifiedHash = _hash;
    }

    function verifyTradeData(bytes32 tradeDataHash) external view returns (bool) {
        return tradeDataHash == verifiedHash;
    }

    function verifyTradeDataWithDocuments(
        bytes32 tradeDataHash,
        bytes32 /*invoiceHash*/,
        bytes32 /*bolHash*/,
        bytes32 /*packingHash*/,
        bytes32 /*cooHash*/
    ) external view returns (bool) {
        return tradeDataHash == verifiedHash;
    }
}
