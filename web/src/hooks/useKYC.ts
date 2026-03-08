"use client";

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from "wagmi";
import { getEscrowContract } from "@/lib/contracts/config";
import { useChainId } from "wagmi";

export type KYCStatus = "verified" | "pending" | "not_verified";

export function useKYC() {
  const chainId = useChainId();
  const contract = getEscrowContract(chainId);
  const { address: userAddress } = useAccount();
  
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  // Read KYC status for current user or any address
  const { data: kycApproved, refetch: refetchApproved } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "kycApproved",
    args: userAddress ? [userAddress] : undefined,
    query: { enabled: !!contract?.address && !!userAddress },
  });

  const { data: kycRequested, refetch: refetchRequested } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "kycRequested",
    args: userAddress ? [userAddress] : undefined,
    query: { enabled: !!contract?.address && !!userAddress },
  });

  // Determine status
  const status: KYCStatus = kycApproved === true 
    ? "verified" 
    : kycRequested === true 
      ? "pending" 
      : "not_verified";

  // Request KYC approval (user calls this to start the process)
  function requestKYC() {
    if (!contract.address) return;
    writeContract({
      address: contract.address,
      abi: contract.abi,
      functionName: "requestKYC",
      args: [],
    });
  }

  // Get all KYC approved addresses (for admin)
  const { data: approvedAddresses, refetch: refetchApprovedList } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "getKYCApprovedAddresses",
    query: { enabled: !!contract?.address },
  });

  // Get pending KYC requests (for admin)
  const { data: pendingRequests, refetch: refetchPendingList } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "getPendingKYCRequests",
    query: { enabled: !!contract?.address },
  });

  // Get counts
  const { data: approvedCount } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "getKYCApprovedCount",
    query: { enabled: !!contract?.address },
  });

  const { data: pendingCount } = useReadContract({
    address: contract?.address,
    abi: contract?.abi,
    functionName: "getPendingKYCRequestCount",
    query: { enabled: !!contract?.address },
  });

  return {
    // User functions
    status,
    requestKYC,
    
    // Admin functions
    approvedAddresses: (approvedAddresses as `0x${string}`[]) || [],
    pendingRequests: (pendingRequests as `0x${string}`[]) || [],
    approvedCount: (approvedCount as number) || 0,
    pendingCount: (pendingCount as number) || 0,
    
    // Transaction state
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
    
    // Refetch functions
    refetch: {
      approved: refetchApproved,
      requested: refetchRequested,
      approvedList: refetchApprovedList,
      pendingList: refetchPendingList,
    },
  };
}
