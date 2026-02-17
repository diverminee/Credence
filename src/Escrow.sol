// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title USDC Escrow Contract
/// @notice Simple, secure escrow for buyer-seller transactions
/// @dev MVP: No arbitrator, no disputes, no deadlines
contract Escrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ============ Errors ============
    error InvalidSeller();
    error InvalidAmount();
    error SellerCannotBeBuyer();
    error OnlySellerCanAccept();
    error OnlyBuyerCanConfirm();
    error OnlyBuyerCanCancel();
    error AlreadyAccepted();
    error AlreadyReleased();
    error AlreadyCancelled();
    error SellerNotAccepted();
    error CannotCancelAfterAccept();
    error EscrowNotFound();

    // ============ State Variables ============
    IERC20 public immutable usdc;

    struct EscrowData {
        address buyer;
        address seller;
        uint256 amount;
        bool sellerAccepted;
        bool isReleased;
        bool isCancelled;
    }

    mapping(uint256 => EscrowData) public escrows;
    uint256 public escrowCount;

    // ============ Events ============
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event SellerAccepted(uint256 indexed escrowId, address indexed seller);
    event FundsReleased(uint256 indexed escrowId, address indexed seller, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed buyer, uint256 amount);

    // ============ Constructor ============
    constructor(address _usdc) Ownable(msg.sender) {
        if (_usdc == address(0)) revert InvalidSeller();
        usdc = IERC20(_usdc);
    }

    // ============ Functions ============

    /// @notice Create a new escrow
    /// @param seller Address of the seller
    /// @param amount Amount of USDC to escrow
    function createEscrow(address seller, uint256 amount) external nonReentrant {
        if (seller == address(0)) revert InvalidSeller();
        if (amount == 0) revert InvalidAmount();
        if (seller == msg.sender) revert SellerCannotBeBuyer();

        uint256 escrowId = escrowCount++;

        usdc.safeTransferFrom(msg.sender, address(this), amount);

        escrows[escrowId] = EscrowData({
            buyer: msg.sender,
            seller: seller,
            amount: amount,
            sellerAccepted: false,
            isReleased: false,
            isCancelled: false
        });

        emit EscrowCreated(escrowId, msg.sender, seller, amount);
    }

    /// @notice Seller accepts the escrow
    /// @param escrowId ID of the escrow
    function acceptEscrow(uint256 escrowId) external {
        EscrowData storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.seller) revert OnlySellerCanAccept();
        if (escrow.sellerAccepted) revert AlreadyAccepted();
        if (escrow.isCancelled) revert AlreadyCancelled();

        escrow.sellerAccepted = true;
        emit SellerAccepted(escrowId, msg.sender);
    }

    /// @notice Buyer confirms delivery and releases funds
    /// @param escrowId ID of the escrow
    function confirmDelivery(uint256 escrowId) external nonReentrant {
        EscrowData storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.buyer) revert OnlyBuyerCanConfirm();
        if (!escrow.sellerAccepted) revert SellerNotAccepted();
        if (escrow.isReleased) revert AlreadyReleased();
        if (escrow.isCancelled) revert AlreadyCancelled();

        escrow.isReleased = true;
        usdc.safeTransfer(escrow.seller, escrow.amount);
        
        emit FundsReleased(escrowId, escrow.seller, escrow.amount);
    }

    /// @notice Buyer cancels escrow before seller accepts
    /// @param escrowId ID of the escrow
    function cancelEscrow(uint256 escrowId) external nonReentrant {
        EscrowData storage escrow = escrows[escrowId];
        
        if (msg.sender != escrow.buyer) revert OnlyBuyerCanCancel();
        if (escrow.sellerAccepted) revert CannotCancelAfterAccept();
        if (escrow.isReleased) revert AlreadyReleased();
        if (escrow.isCancelled) revert AlreadyCancelled();

        escrow.isCancelled = true;
        usdc.safeTransfer(escrow.buyer, escrow.amount);
        
        emit EscrowCancelled(escrowId, msg.sender, escrow.amount);
    }

    // ============ Getter Functions ============

    /// @notice Get escrow details
    /// @param escrowId ID of the escrow
    function getEscrow(uint256 escrowId) external view returns (EscrowData memory) {
        return escrows[escrowId];
    }

    /// @notice Get total number of escrows
    function getEscrowCount() external view returns (uint256) {
        return escrowCount;
    }
}