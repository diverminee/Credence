"use client";

import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { getEscrowContract } from "@/lib/contracts/config";
import { EscrowMode } from "@/types/escrow";

interface CreateEscrowParams {
  seller: `0x${string}`;
  arbiter: `0x${string}`;
  token: `0x${string}`;
  amount: bigint;
  tradeId: bigint;
  tradeDataHash: `0x${string}`;
  mode?: EscrowMode;
  maturityDays?: bigint;
  collateralBps?: bigint;
}

// Fallback gas limit for createEscrow transactions
// This is used when gas estimation fails or returns an excessive value
const FALLBACK_GAS_LIMIT = BigInt(500000);

export function useCreateEscrow(chainId: number) {
  const contract = getEscrowContract(chainId);

  const {
    writeContract,
    data: hash,
    isPending,
    error,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } =
    useWaitForTransactionReceipt({ hash });

  /**
   * Parse the error and return a user-friendly message
   */
  function parseError(err: Error | null): string | null {
    if (!err) return null;

    const message = err.message || "";

    // Handle "exceeds max transaction gas limit" error
    if (message.includes("exceeds max transaction gas limit")) {
      return "Transaction failed due to gas estimation issues. This may be because: (1) KYC verification is required, (2) The contract is paused, or (3) The seller hasn't completed KYC. Please ensure you and the seller have completed KYC verification.";
    }

    // Handle AmountBelowMinimum error
    if (message.includes("AmountBelowMinimum") || message.includes("0x2fcd1a0f")) {
      return "The escrow amount is below the minimum required. Please increase the amount and try again. Minimum amounts may vary by token - please check the documentation for token-specific minimums.";
    }

    // Handle AmountExceedsMaximum error
    if (message.includes("AmountExceedsMaximum") || message.includes("0x46d71cf4")) {
      return "The escrow amount exceeds the maximum allowed. Please reduce the amount and try again.";
    }

    // Handle NotKYCApproved error
    if (message.includes("NotKYCApproved") || message.includes("0xdfac5c4a")) {
      return "KYC verification is required to create an escrow. Please complete KYC approval first. Both the buyer and seller must be KYC approved.";
    }

    // Handle SellerCannotBeBuyer error
    if (message.includes("SellerCannotBeBuyer") || message.includes("0x4ac4cd5a")) {
      return "You cannot be both the buyer and the seller in an escrow.";
    }

    // Handle ArbiterCannotBeBuyer error
    if (message.includes("ArbiterCannotBeBuyer") || message.includes("0x4b2a4cd8")) {
      return "You cannot be the arbiter of an escrow you are creating.";
    }

    // Handle ArbiterCannotBeSeller error
    if (message.includes("ArbiterCannotBeSeller") || message.includes("0x5c6d1cdf")) {
      return "The seller cannot be the arbiter of an escrow.";
    }

    // Handle ProtocolArbiterCannotBeParty error
    if (message.includes("ProtocolArbiterCannotBeParty") || message.includes("0x8d5d8c32")) {
      return "The protocol arbiter cannot be a party to an escrow.";
    }

    // Handle InvalidAddresses error
    if (message.includes("InvalidAddresses") || message.includes("0x1476a480")) {
      return "Invalid address provided. Please check all addresses and try again.";
    }

    // Handle InvalidAmount error
    if (message.includes("InvalidAmount") || message.includes("0xad3c4289")) {
      return "Invalid amount. Please enter a valid escrow amount.";
    }

    if (message.includes("User rejected the request")) {
      return "Transaction was rejected. Please approve the transaction in your wallet.";
    }

    // Return the original error if no specific handling
    return message;
  }

  function createEscrow(params: CreateEscrowParams) {
    // DEBUG: Log incoming parameters
    console.log('[useCreateEscrow] createEscrow called:', {
      amount: params.amount?.toString(),
      amountDecimal: Number(params.amount) / 1e6,
      seller: params.seller,
      arbiter: params.arbiter,
      token: params.token,
    });

    if (!contract.address) return;

    const isPaymentCommitment =
      params.mode !== undefined &&
      params.mode === EscrowMode.PAYMENT_COMMITMENT;

    // Build the base transaction config with fallback gas limit
    const baseConfig = {
      address: contract.address,
      abi: contract.abi,
      functionName: "createEscrow" as const,
      gas: FALLBACK_GAS_LIMIT, // Use fallback gas limit to avoid estimation issues
    };

    if (isPaymentCommitment) {
      // 9-param overload for PAYMENT_COMMITMENT
      writeContract({
        ...baseConfig,
        args: [
          params.seller,
          params.arbiter,
          params.token,
          params.amount,
          params.tradeId,
          params.tradeDataHash,
          params.mode,
          params.maturityDays ?? 0n,
          params.collateralBps ?? 0n,
        ],
      });
    } else {
      // 6-param overload for CASH_LOCK
      writeContract({
        ...baseConfig,
        args: [
          params.seller,
          params.arbiter,
          params.token,
          params.amount,
          params.tradeId,
          params.tradeDataHash,
        ],
      });
    }
  }

  // Return parsed error for user-friendly display
  const parsedError = parseError(error as Error | null);

  return { 
    createEscrow, 
    hash, 
    isPending, 
    isConfirming, 
    isSuccess, 
    error: parsedError,
    rawError: error, // Keep original error for debugging
  };
}
