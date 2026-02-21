// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IReceivableMinter
/// @notice Interface for external NFT contract called by TradeInfraEscrow on document commitment
interface IReceivableMinter {
    /// @notice Called by TradeInfraEscrow when goods are confirmed shipped
    /// @param escrowId The escrow this receivable represents
    /// @param seller Address of the exporter (initial NFT recipient)
    /// @param faceValue Full payment amount due at maturity
    /// @param maturityDate Unix timestamp of payment due date
    /// @param documentMerkleRoot Merkle root of committed trade documents
    /// @param token Payment token address (address(0) for ETH)
    /// @return tokenId The minted NFT token ID
    function mintReceivable(
        uint256 escrowId,
        address seller,
        uint256 faceValue,
        uint256 maturityDate,
        bytes32 documentMerkleRoot,
        address token
    ) external returns (uint256 tokenId);

    /// @notice Called by TradeInfraEscrow when the underlying escrow settles
    /// @param tokenId The NFT token ID to settle
    function settleReceivable(uint256 tokenId) external;
}
