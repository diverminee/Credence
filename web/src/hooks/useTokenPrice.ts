"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";

// Simple price cache - in production, use a proper price feed
const PRICE_CACHE: Record<string, number> = {
  "0x0000000000000000000000000000000000000000": 1850, // ETH ~$1850
  "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": 1.0, // USDC
  "0xdac17f958d2ee523a2206206994597c13d831ec7": 1.0, // USDT
  // Add more tokens as needed
};

const CHAIN_PRICES: Record<number, Record<string, number>> = {
  1: { // Ethereum Mainnet
    "0x0000000000000000000000000000000000000000": 1850,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": 1.0,
    "0xdac17f958d2ee523a2206206994597c13d831ec7": 1.0,
  },
  84532: { // Base Sepolia
    "0x0000000000000000000000000000000000000000": 1850,
    "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238": 1.0,
    "0x7169D38820dfd117C3FA1f22a697dBA58d90BA06": 1.0,
  },
  11155111: { // Sepolia
    "0x0000000000000000000000000000000000000000": 1850,
    "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238": 1.0,
    "0x7169D38820dfd117C3FA1f22a697dBA58d90BA06": 1.0,
  },
  31337: { // Local/Anvil
    "0x0000000000000000000000000000000000000000": 1850,
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": 1.0,
    "0xdac17f958d2ee523a2206206994597c13d831ec7": 1.0,
  },
};

interface UseTokenPriceOptions {
  token: string;
  amount: bigint;
  chainId?: number;
  enabled?: boolean;
}

function getTokenPrice(token: string, chainId?: number): number | null {
  const normalizedToken = token.toLowerCase();
  // Check chain-specific prices first
  if (chainId && CHAIN_PRICES[chainId]?.[normalizedToken]) {
    return CHAIN_PRICES[chainId][normalizedToken];
  }
  // Fall back to global cache
  if (PRICE_CACHE[normalizedToken]) {
    return PRICE_CACHE[normalizedToken];
  }
  // Default fallback - return 0 for unknown tokens
  return 0;
}

function calculateUsdValue(price: number | null, amount: bigint, token: string): number | null {
  if (price === null) return null;
  return Number(amount) * price / (token.toLowerCase() === "0x0000000000000000000000000000000000000000" ? 1e18 : 1e6);
}

export function useTokenPrice({ token, amount, chainId, enabled = true }: UseTokenPriceOptions) {
  // Normalize token address
  const normalizedToken = token.toLowerCase();
  
  const { data, isLoading, error } = useQuery({
    queryKey: ["tokenPrice", normalizedToken, chainId],
    queryFn: async () => getTokenPrice(normalizedToken, chainId),
    enabled: enabled && !!token && amount > 0n,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Calculate USD value
  const usdValue = useMemo(() => calculateUsdValue(data ?? null, amount, normalizedToken), [data, amount, normalizedToken]);

  return {
    price: data ?? null,
    usdValue,
    isLoading,
    error,
  };
}
