"use client";

import { useReadContract } from "wagmi";
import { getEscrowContract } from "@/lib/contracts/config";

export interface EscrowRequirementStatus {
  isPaused: boolean;
  isBuyerKycApproved: boolean;
  isSellerKycApproved: boolean;
  isLoading: boolean;
  error: string | null;
}

/**
 * Hook to check escrow requirements before creating an escrow
 * Checks:
 * 1. If the contract is paused
 * 2. If the buyer has KYC approval
 * 3. If the seller has KYC approval
 */
export function useCheckEscrowRequirements({
  buyerAddress,
  sellerAddress,
  chainId,
  enabled = true,
}: {
  buyerAddress?: `0x${string}`;
  sellerAddress?: `0x${string}`;
  chainId?: number;
  enabled?: boolean;
}) {
  const contract = chainId ? getEscrowContract(chainId) : null;

  // Check if contract is paused
  const { data: pausedData, isLoading: isLoadingPaused } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "paused",
    query: {
      enabled: enabled && !!contract?.address,
    },
  });

  // Check buyer's KYC status
  const { data: buyerKycData, isLoading: isLoadingBuyerKyc } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "kycApproved",
    args: buyerAddress ? [buyerAddress] : undefined,
    query: {
      enabled: enabled && !!contract?.address && !!buyerAddress,
    },
  });

  // Check seller's KYC status
  const { data: sellerKycData, isLoading: isLoadingSellerKyc } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "kycApproved",
    args: sellerAddress ? [sellerAddress] : undefined,
    query: {
      enabled: enabled && !!contract?.address && !!sellerAddress,
    },
  });

  const isLoading = isLoadingPaused || isLoadingBuyerKyc || isLoadingSellerKyc;

  const status: EscrowRequirementStatus = {
    isPaused: pausedData === true,
    isBuyerKycApproved: buyerKycData === true,
    isSellerKycApproved: sellerKycData === true,
    isLoading,
    error: null,
  };

  return {
    status,
    /**
     * Get human-readable error messages for each requirement check
     */
    getErrors: () => {
      const errors: string[] = [];

      if (status.isPaused) {
        errors.push("Escrow service is temporarily unavailable. Please try again later.");
      }

      if (!status.isBuyerKycApproved && buyerAddress) {
        errors.push("You need to complete KYC verification before creating escrows.");
      }

      if (!status.isSellerKycApproved && sellerAddress) {
        errors.push("The seller has not completed KYC verification. Please choose another seller.");
      }

      return errors;
    },
    /**
     * Check if all requirements are met
     */
    canCreateEscrow: () => {
      return !status.isPaused && status.isBuyerKycApproved && status.isSellerKycApproved;
    },
  };
}
