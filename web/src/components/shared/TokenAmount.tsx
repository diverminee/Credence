import { formatEther } from "@/lib/utils";
import { ZERO_ADDRESS } from "@/lib/constants";
import { useTokenPrice } from "@/hooks/useTokenPrice";
import { useChainId } from "wagmi";
import { useState, useEffect } from "react";

export interface TokenAmountProps {
  amount: bigint;
  token: string;
  showFiat?: boolean;
  className?: string;
}

export function TokenAmount({ amount, token, showFiat = true, className = "" }: TokenAmountProps) {
  const chainId = useChainId();
  const { usdValue, isLoading: isLoadingPrice } = useTokenPrice({ 
    token, 
    amount,
    chainId,
  });
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const symbol = token === ZERO_ADDRESS ? "ETH" : "Token";
  const isEth = token === ZERO_ADDRESS;
  const decimals = isEth ? 18 : 6;
  const displayAmount = Number(amount) / (10 ** decimals);

  // Format fiat value
  const fiatDisplay = mounted && usdValue !== null 
    ? `$${usdValue.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    : null;

  return (
    <span className={`font-mono text-[#D9AA90] ${className}`}>
      {displayAmount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 6 })} {symbol}
      {showFiat && fiatDisplay && (
        <span className="ml-2 text-[#A68A7A] text-sm">
          ({fiatDisplay})
        </span>
      )}
    </span>
  );
}
