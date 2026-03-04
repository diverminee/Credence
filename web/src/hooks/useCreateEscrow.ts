"use client";

import { useWriteContract, useWaitForTransactionReceipt, useAccount } from "wagmi";
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

    // Handle other common errors
    if (message.includes("NotKYCApproved")) {
      return "KYC verification is required to create an escrow. Please complete your KYC first.";
    }

    if (message.includes("Paused")) {
      return "Escrow service is temporarily unavailable. Please try again later.";
    }

    if (message.includes("User rejected the request")) {
      return "Transaction was rejected. Please approve the transaction in your wallet.";
    }

    // Return the original error if no specific handling
    return message;
  }

  function createEscrow(params: CreateEscrowParams) {
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
