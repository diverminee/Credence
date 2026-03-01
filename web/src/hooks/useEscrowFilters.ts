"use client";

import { useState, useMemo } from "react";
import { EscrowTransaction, EscrowState, EscrowMode } from "@/types/escrow";

export interface EscrowFilters {
  search: string;
  state: EscrowState | "all";
  mode: EscrowMode | "all";
  token: string | "all";
  dateRange: {
    start: Date | null;
    end: Date | null;
  };
  amountRange: {
    min: bigint | null;
    max: bigint | null;
  };
  party: "buyer" | "seller" | "arbiter" | "all";
  sortBy: "created" | "amount" | "state";
  sortOrder: "asc" | "desc";
}

const DEFAULT_FILTERS: EscrowFilters = {
  search: "",
  state: "all",
  mode: "all",
  token: "all",
  dateRange: { start: null, end: null },
  amountRange: { min: null, max: null },
  party: "all",
  sortBy: "created",
  sortOrder: "desc",
};

export function useEscrowFilters(initialFilters: Partial<EscrowFilters> = {}) {
  const [filters, setFilters] = useState<EscrowFilters>({
    ...DEFAULT_FILTERS,
    ...initialFilters,
  });

  const updateFilter = <K extends keyof EscrowFilters>(
    key: K,
    value: EscrowFilters[K]
  ) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  const resetFilters = () => {
    setFilters(DEFAULT_FILTERS);
  };

  const hasActiveFilters = useMemo(() => {
    return (
      filters.search !== "" ||
      filters.state !== "all" ||
      filters.mode !== "all" ||
      filters.token !== "all" ||
      filters.dateRange.start !== null ||
      filters.dateRange.end !== null ||
      filters.amountRange.min !== null ||
      filters.amountRange.max !== null ||
      filters.party !== "all"
    );
  }, [filters]);

  return {
    filters,
    updateFilter,
    resetFilters,
    hasActiveFilters,
  };
}

export function filterEscrows(escrows: EscrowTransaction[], filters: EscrowFilters, userAddress?: string): EscrowTransaction[] {
  let result = [...escrows];

  // Search filter (by escrow ID or trade ID)
  if (filters.search) {
    const searchLower = filters.search.toLowerCase();
    result = result.filter(
      (e) =>
        e.escrowId.toString().includes(searchLower) ||
        e.tradeId.toLowerCase().includes(searchLower) ||
        e.buyer.toLowerCase().includes(searchLower) ||
        e.seller.toLowerCase().includes(searchLower)
    );
  }

  // State filter
  if (filters.state !== "all") {
    result = result.filter((e) => Number(e.state) === filters.state);
  }

  // Mode filter
  if (filters.mode !== "all") {
    result = result.filter((e) => Number(e.mode) === filters.mode);
  }

  // Token filter
  if (filters.token !== "all") {
    result = result.filter((e) => e.token.toLowerCase() === filters.token.toLowerCase());
  }

  // Party filter
  if (filters.party !== "all" && userAddress) {
    const address = userAddress.toLowerCase();
    switch (filters.party) {
      case "buyer":
        result = result.filter((e) => e.buyer.toLowerCase() === address);
        break;
      case "seller":
        result = result.filter((e) => e.seller.toLowerCase() === address);
        break;
      case "arbiter":
        result = result.filter((e) => e.arbiter.toLowerCase() === address);
        break;
    }
  }

  // Amount range filter
  if (filters.amountRange.min !== null) {
    result = result.filter((e) => e.amount >= filters.amountRange.min!);
  }
  if (filters.amountRange.max !== null) {
    result = result.filter((e) => e.amount <= filters.amountRange.max!);
  }

  // Date range filter
  if (filters.dateRange.start !== null) {
    const startTimestamp = BigInt(Math.floor(filters.dateRange.start.getTime() / 1000));
    result = result.filter((e) => e.createdAt >= startTimestamp);
  }
  if (filters.dateRange.end !== null) {
    const endTimestamp = BigInt(Math.floor(filters.dateRange.end.getTime() / 1000));
    result = result.filter((e) => e.createdAt <= endTimestamp);
  }

  // Sorting
  result.sort((a, b) => {
    let comparison = 0;
    switch (filters.sortBy) {
      case "created":
        comparison = Number(a.createdAt - b.createdAt);
        break;
      case "amount":
        comparison = Number(a.amount - b.amount);
        break;
      case "state":
        comparison = Number(a.state - b.state);
        break;
    }
    return filters.sortOrder === "asc" ? comparison : -comparison;
  });

  return result;
}
