"use client";

import { useState, useEffect } from "react";
import { useChainId, useEstimateGas } from "wagmi";
import { parseEther } from "viem";

// Gas estimation helper hook
export function useGasEstimate({
  enabled = false,
  chainId,
}: {
  enabled?: boolean;
  chainId?: number;
}) {
  const [gasEstimate, setGasEstimate] = useState<bigint | null>(null);
  const [isEstimating, setIsEstimating] = useState(false);

  // Rough gas estimates for different operations (in gas units)
  const GAS_ESTIMATES: Record<string, number> = {
    fund: 100000,
    fundEth: 50000,
    commitDocuments: 150000,
    confirmDelivery: 80000,
    fulfillCommitment: 120000,
    claimDefaulted: 100000,
    raiseDispute: 80000,
    resolveDispute: 60000,
    escalate: 50000,
    claimTimeout: 60000,
    createEscrow: 200000,
  };

  // Estimate gas cost in native token
  const getGasEstimate = (operation: string) => {
    const gasUnits = GAS_ESTIMATES[operation] || 100000;
    // Rough estimate: 20 Gwei for L2, 50 Gwei for L1
    const gwei = chainId === 1 ? 50n : 20n;
    return BigInt(gasUnits) * gwei;
  };

  return {
    getGasEstimate,
    gasEstimate,
    isEstimating,
  };
}

// Format gas cost for display
export function formatGasCost(gasCost: bigint, chainId?: number): string {
  const gwei = chainId === 1 ? 50 : 20; // Gwei
  const costInGwei = Number(gasCost) / 1e9;
  const costInEth = costInGwei * gwei / 1e9;
  
  if (costInEth < 0.001) {
    return `~$${(costInEth * 1850).toFixed(4)}`; // Assuming $1850/ETH
  }
  return `~${costInEth.toFixed(4)} ETH ($${(costInEth * 1850).toFixed(2)})`;
}
