"use client";

import { useState, useEffect, useCallback } from "react";
import { useAccount, useChainId, useBalance, useToken } from "wagmi";

interface TokenBalance {
  token: string;
  symbol: string;
  balance: bigint;
  formatted: string;
  usdValue?: number;
}

interface UseRealTimeBalancesOptions {
  tokens: string[]; // Array of token addresses
  enabled?: boolean;
  refreshInterval?: number; // in milliseconds
}

export function useRealTimeBalances({
  tokens,
  enabled = true,
  refreshInterval = 15000, // Default 15 seconds
}: UseRealTimeBalancesOptions) {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const [balances, setBalances] = useState<TokenBalance[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Fetch balance for a single token
  const fetchBalance = useCallback(async (token: string) => {
    try {
      if (token === "0x0000000000000000000000000000000000000000" || token === "0x") {
        // Native ETH balance
        const balance = await fetch(`/api/balance?address=${address}&chainId=${chainId}`)
          .then(res => res.json());
        return {
          token,
          symbol: "ETH",
          balance: BigInt(balance.balance || 0),
          formatted: balance.formatted || "0",
        };
      } else {
        // ERC20 token balance - would need an API or contract call
        return {
          token,
          symbol: "Token",
          balance: 0n,
          formatted: "0",
        };
      }
    } catch (err) {
      return {
        token,
        symbol: "???",
        balance: 0n,
        formatted: "0",
      };
    }
  }, [address, chainId]);

  // Poll for balance updates
  useEffect(() => {
    if (!enabled || !isConnected || !address) {
      setBalances([]);
      setIsLoading(false);
      return;
    }

    const fetchBalances = async () => {
      setIsLoading(true);
      try {
        const results = await Promise.all(tokens.map(fetchBalance));
        setBalances(results);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to fetch balances"));
      } finally {
        setIsLoading(false);
      }
    };

    // Initial fetch
    fetchBalances();

    // Set up polling
    const interval = setInterval(fetchBalances, refreshInterval);

    return () => clearInterval(interval);
  }, [address, chainId, enabled, isConnected, tokens, refreshInterval, fetchBalance]);

  // Calculate total USD value
  const totalUsdValue = balances.reduce((sum, b) => sum + (b.usdValue || 0), 0);

  return {
    balances,
    totalUsdValue,
    isLoading,
    error,
    refetch: () => {
      setIsLoading(true);
      Promise.all(tokens.map(fetchBalance)).then(results => {
        setBalances(results);
        setIsLoading(false);
      });
    },
  };
}

// Hook for real-time price updates
export function useRealTimePrice(token: string, enabled = true) {
  const chainId = useChainId();
  const [price, setPrice] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!enabled || !token) return;

    const fetchPrice = async () => {
      setIsLoading(true);
      try {
        // In production, fetch from price oracle or API
        // For now, return mock prices
        const mockPrices: Record<string, number> = {
          "0x0000000000000000000000000000000000000000": 1850,
          "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": 1.0,
          "0xdac17f958d2ee523a2206206994597c13d831ec7": 1.0,
        };
        setPrice(mockPrices[token.toLowerCase()] || 0);
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to fetch price"));
      } finally {
        setIsLoading(false);
      }
    };

    fetchPrice();
    const interval = setInterval(fetchPrice, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, [token, enabled, chainId]);

  return { price, isLoading, error };
}
