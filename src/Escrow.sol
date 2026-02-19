// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Trade Infrastructure Escrow Contract
/// @notice Advanced escrow with arbitration, oracle verification, and fee collection
/// @dev Supports ETH and ERC20 tokens with full state machine management
interface ITradeOracle {
    /// @notice Verify trade data authenticity
    /// @param tradeDataHash Hash of trade data
    /// @return bool True if trade data is valid
    function verifyTradeData(
        bytes32 tradeDataHash
    ) external view returns (bool);
}

contract TradeInfraEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Enums ============
    enum State {
        DRAFT,
        FUNDED,
        RELEASED,
        REFUNDED,
        DISPUTED
    }

    enum UserTier {
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND
    }

    // ============ Structs ============
    struct EscrowTransaction {
        address buyer;
        address seller;
        address arbiter;
        address token;
        uint256 amount;
        uint256 tradeId;
        bytes32 tradeDataHash;
        State state;
    }

    // ============ Errors ============
    error InvalidAddresses();
    error InvalidAmount();
    error InvalidState();
    error NotAParty();
    error NotTheArbiter();
    error OnlyBuyerCanFund();
    error IncorrectETHAmount();
    error OnlyBuyerCanConfirm();
    error OracleVerificationFailed();
    error InvalidRuling();
    error ETHTransferFailed();
    error TooManyDisputes();
    error SellerCannotBeBuyer();
    error ArbiterCannotBeBuyer();
    error ArbiterCannotBeSeller();
    error NoETHForERC20Escrow();

    // ============ State Variables ============
    ITradeOracle public immutable oracle;
    address public immutable feeRecipient;

    mapping(uint256 => EscrowTransaction) public escrows;
    uint256 public nextEscrowId;

    /// @notice Track successful completed trades per user
    mapping(address => uint256) public successfulTrades;

    /// @notice Track disputes initiated per user
    mapping(address => uint256) public disputesInitiated;

    /// @notice Track disputes lost per user (punishment)
    mapping(address => uint256) public disputesLost;

    // ============ Events ============
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );
    event Funded(uint256 indexed escrowId, uint256 amount);
    event Released(
        uint256 indexed escrowId,
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );
    event Refunded(
        uint256 indexed escrowId,
        address indexed recipient,
        uint256 amount
    );
    event DisputeRaised(uint256 indexed escrowId, address indexed initiator);
    event DisputeResolved(uint256 indexed escrowId, uint8 indexed ruling);

    // ============ Modifiers ============
    /// @notice Verify escrow is in expected state
    /// @param _escrowId ID of the escrow
    /// @param _state Expected state
    modifier inState(uint256 _escrowId, State _state) {
        if (escrows[_escrowId].state != _state) revert InvalidState();
        _;
    }

    /// @notice Verify caller is buyer or seller
    /// @param _escrowId ID of the escrow
    modifier onlyParty(uint256 _escrowId) {
        EscrowTransaction memory txn = escrows[_escrowId];
        if (msg.sender != txn.buyer && msg.sender != txn.seller)
            revert NotAParty();
        _;
    }

    /// @notice Verify caller is the arbiter
    /// @param _escrowId ID of the escrow
    modifier onlyArbiter(uint256 _escrowId) {
        if (msg.sender != escrows[_escrowId].arbiter) revert NotTheArbiter();
        _;
    }

    // ============ Reputation & Tier Functions ============

    /// @notice Calculate user's tier based on trade history
    /// @param _user Address of the user
    /// @return UserTier Current tier of the user
    function getUserTier(address _user) public view returns (UserTier) {
        uint256 successes = successfulTrades[_user];
        uint256 disputes = disputesLost[_user];

        // DIAMOND: 50+ successful trades, 0 losses
        if (successes >= 50 && disputes == 0) return UserTier.DIAMOND;

        // GOLD: 20+ successful trades, ≤1 loss
        if (successes >= 20 && disputes <= 1) return UserTier.GOLD;

        // SILVER: 5+ successful trades
        if (successes >= 5) return UserTier.SILVER;

        // BRONZE: New user or low activity
        return UserTier.BRONZE;
    }

    /// @notice Calculate dynamic fee based on user tier
    /// @param _user Address of the user
    /// @return fee Fee in basis points divided by 1000 (e.g., 12 = 1.2%)
    function _calculateUserFee(address _user) internal view returns (uint256) {
        UserTier tier = getUserTier(_user);

        // DIAMOND: 0.7% fee (best)
        if (tier == UserTier.DIAMOND) return 7;

        // GOLD: 0.8% fee
        if (tier == UserTier.GOLD) return 8;

        // SILVER: 0.9% fee
        if (tier == UserTier.SILVER) return 9;

        // BRONZE: 1.2% fee (default, higher for risk)
        return 12;
    }

    /// @notice Calculate fee amount based on transaction and user tier
    /// @param _amount Transaction amount
    /// @param _user Address of the user
    /// @return Fee amount in token units
    function _getFeeAmount(
        uint256 _amount,
        address _user
    ) internal view returns (uint256) {
        uint256 feeBasisPoints = _calculateUserFee(_user);
        return (_amount * feeBasisPoints) / 1000;
    }

    // ============ Constructor ============
    /// @notice Initialize contract with oracle and fee recipient
    /// @param _oracleAddress Address of the trade oracle
    /// @param _feeRecipient Address to receive transaction fees
    constructor(address _oracleAddress, address _feeRecipient) {
        if (_oracleAddress == address(0) || _feeRecipient == address(0)) {
            revert InvalidAddresses();
        }
        oracle = ITradeOracle(_oracleAddress);
        feeRecipient = _feeRecipient;
    }

    // ============ Core Functions ============

    /// @notice Create a new escrow transaction
    /// @param _seller Address of the seller
    /// @param _arbiter Address of the dispute arbiter
    /// @param _token Address of ERC20 token (address(0) for ETH)
    /// @param _amount Amount to escrow
    /// @param _tradeId External trade ID
    /// @param _tradeDataHash Hash of trade data for oracle verification
    /// @return escrowId The ID of created escrow
    function createEscrow(
        address _seller,
        address _arbiter,
        address _token,
        uint256 _amount,
        uint256 _tradeId,
        bytes32 _tradeDataHash
    ) external returns (uint256) {
        if (_seller == address(0) || _arbiter == address(0))
            revert InvalidAddresses();
        if (_amount == 0) revert InvalidAmount();
        if (msg.sender == _seller) revert SellerCannotBeBuyer();
        if (_arbiter == msg.sender) revert ArbiterCannotBeBuyer();
        if (_arbiter == _seller) revert ArbiterCannotBeSeller();

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = EscrowTransaction({
            buyer: msg.sender,
            seller: _seller,
            arbiter: _arbiter,
            token: _token,
            amount: _amount,
            tradeId: _tradeId,
            tradeDataHash: _tradeDataHash,
            state: State.DRAFT
        });

        emit EscrowCreated(escrowId, msg.sender, _seller, _amount);
        return escrowId;
    }

    /// @notice Fund the escrow with ETH or ERC20 tokens
    /// @param _escrowId ID of the escrow to fund
    function fund(
        uint256 _escrowId
    ) external payable inState(_escrowId, State.DRAFT) nonReentrant {
        EscrowTransaction storage txn = escrows[_escrowId];
        if (msg.sender != txn.buyer) revert OnlyBuyerCanFund();

        if (txn.token == address(0)) {
            if (msg.value != txn.amount) revert IncorrectETHAmount();
        } else {
            if (msg.value > 0) revert NoETHForERC20Escrow();
            IERC20(txn.token).safeTransferFrom(
                msg.sender,
                address(this),
                txn.amount
            );
        }

        txn.state = State.FUNDED;
        emit Funded(_escrowId, txn.amount);
    }

    /// @notice Buyer manually confirms delivery and releases funds to seller
    /// @param _escrowId ID of the escrow
    function confirmDelivery(
        uint256 _escrowId
    ) external inState(_escrowId, State.FUNDED) nonReentrant {
        if (msg.sender != escrows[_escrowId].buyer)
            revert OnlyBuyerCanConfirm();
        _releaseFunds(_escrowId, escrows[_escrowId].seller);
    }

    /// @notice Release funds based on oracle verification
    /// @param _escrowId ID of the escrow
    function confirmByOracle(
        uint256 _escrowId
    ) external inState(_escrowId, State.FUNDED) nonReentrant {
        EscrowTransaction storage txn = escrows[_escrowId];
        if (!oracle.verifyTradeData(txn.tradeDataHash))
            revert OracleVerificationFailed();
        _releaseFunds(_escrowId, txn.seller);
    }

    /// @notice Raise a dispute on the escrow transaction
    /// @param _escrowId ID of the escrow
    function raiseDispute(
        uint256 _escrowId
    ) external onlyParty(_escrowId) inState(_escrowId, State.FUNDED) {
        address initiator = msg.sender;

        // Check for excessive disputes (prevent abuse)
        // Hard limit: 10+ disputes initiations
        if (disputesInitiated[initiator] >= 10) revert TooManyDisputes();

        // Check loss rate: >50% loss rate with 3+ losses
        uint256 losses = disputesLost[initiator];
        if (losses >= 3) {
            uint256 totalDisputes = disputesInitiated[initiator];
            if (totalDisputes > 0 && (losses * 100) / totalDisputes > 50) {
                revert TooManyDisputes();
            }
        }

        // Track dispute initiation
        disputesInitiated[initiator]++;

        escrows[_escrowId].state = State.DISPUTED;
        emit DisputeRaised(_escrowId, initiator);
    }

    /// @notice Resolve dispute with arbiter ruling
    /// @param _escrowId ID of the escrow
    /// @param _ruling Ruling (1 = release to seller, 2 = refund to buyer)
    function resolveDispute(
        uint256 _escrowId,
        uint8 _ruling
    )
        external
        onlyArbiter(_escrowId)
        inState(_escrowId, State.DISPUTED)
        nonReentrant
    {
        EscrowTransaction storage txn = escrows[_escrowId];

        if (_ruling == 1) {
            // Ruling in favor of seller
            // Buyer loses the dispute
            disputesLost[txn.buyer]++;
            _releaseFunds(_escrowId, txn.seller);
        } else if (_ruling == 2) {
            // Ruling in favor of buyer
            // Seller loses the dispute
            disputesLost[txn.seller]++;
            _refundFunds(_escrowId, txn.buyer);
        } else {
            revert InvalidRuling();
        }

        emit DisputeResolved(_escrowId, _ruling);
    }

    // ============ Internal Functions ============

    /// @notice Internal function to release funds with fee deduction
    /// @param _escrowId ID of the escrow
    /// @param _recipient Address to receive funds
    function _releaseFunds(uint256 _escrowId, address _recipient) internal {
        EscrowTransaction storage txn = escrows[_escrowId];
        txn.state = State.RELEASED;

        // Calculate fee based on seller's tier (quality of service)
        uint256 feeAmount = _getFeeAmount(txn.amount, _recipient);
        uint256 recipientAmount = txn.amount - feeAmount;

        // Track successful trade for BOTH seller and buyer (symmetric)
        successfulTrades[_recipient]++;
        successfulTrades[txn.buyer]++;

        if (txn.token == address(0)) {
            (bool sent, ) = payable(_recipient).call{value: recipientAmount}(
                ""
            );
            if (!sent) revert ETHTransferFailed();

            (bool feeSent, ) = payable(feeRecipient).call{value: feeAmount}("");
            if (!feeSent) revert ETHTransferFailed();
        } else {
            IERC20(txn.token).safeTransfer(_recipient, recipientAmount);
            IERC20(txn.token).safeTransfer(feeRecipient, feeAmount);
        }

        emit Released(_escrowId, _recipient, recipientAmount, feeAmount);
    }

    /// @notice Internal function to refund funds to buyer (no fee deduction)
    /// @param _escrowId ID of the escrow
    /// @param _recipient Address to receive refund
    function _refundFunds(uint256 _escrowId, address _recipient) internal {
        EscrowTransaction storage txn = escrows[_escrowId];
        txn.state = State.REFUNDED;

        // Track successful resolution for buyer (symmetric reputation)
        successfulTrades[_recipient]++;

        if (txn.token == address(0)) {
            (bool sent, ) = payable(_recipient).call{value: txn.amount}("");
            if (!sent) revert ETHTransferFailed();
        } else {
            IERC20(txn.token).safeTransfer(_recipient, txn.amount);
        }

        emit Refunded(_escrowId, _recipient, txn.amount);
    }

    // ============ View Functions ============

    /// @notice Get full escrow transaction details
    /// @param _escrowId ID of the escrow
    /// @return EscrowTransaction struct with all details
    function getEscrow(
        uint256 _escrowId
    ) external view returns (EscrowTransaction memory) {
        return escrows[_escrowId];
    }

    /// @notice Get current number of escrows
    /// @return uint256 Total escrow count
    function getEscrowCount() external view returns (uint256) {
        return nextEscrowId;
    }

    /// @notice Get user's current tier as string
    /// @param _user Address of the user
    /// @return string Tier name (BRONZE, SILVER, GOLD, DIAMOND)
    function getUserTierName(
        address _user
    ) external view returns (string memory) {
        UserTier tier = getUserTier(_user);
        if (tier == UserTier.DIAMOND) return "DIAMOND";
        if (tier == UserTier.GOLD) return "GOLD";
        if (tier == UserTier.SILVER) return "SILVER";
        return "BRONZE";
    }

    /// @notice Get user's current fee rate
    /// @param _user Address of the user
    /// @return uint256 Fee in basis points (1000ths), e.g., 12 = 1.2%
    function getUserFeeRate(address _user) external view returns (uint256) {
        return _calculateUserFee(_user);
    }

    /// @notice Get user's reputation stats
    /// @param _user Address of the user
    /// @return _successfulTrades Number of completed trades
    /// @return _disputesInitiated Number of disputes initiated
    /// @return _disputesLost Number of disputes lost
    function getUserStats(
        address _user
    )
        external
        view
        returns (
            uint256 _successfulTrades,
            uint256 _disputesInitiated,
            uint256 _disputesLost
        )
    {
        return (
            successfulTrades[_user],
            disputesInitiated[_user],
            disputesLost[_user]
        );
    }
}
