# Credence — Architecture Overview

**Read this file at the START of every task.**

---

## Project Overview

**Credence** — Programmable escrow infrastructure for international trade on Ethereum.

- **Backend**: Solidity 0.8.24 / Foundry
- **Frontend**: Next.js 16 / wagmi v2 / viem v2
- **Architecture**: TradeInfraEscrow → DisputeEscrow → BaseEscrow

---

## Files Structure

```
src/
  core/           # BaseEscrow, DisputeEscrow, TradeInfraEscrow
  interfaces/     # ITradeOracle, IReceivableMinter
  libraries/     # EscrowTypes, ReputationLibrary
test/             # Foundry tests
script/           # Deployment scripts
web/              # Next.js frontend
  src/
    app/          # pages
    components/   # React components
    hooks/        # wagmi hooks
    lib/          # ABIs, config
```

---

## Key Technical Details

- **Escrow States**: DRAFT → FUNDED → RELEASED/REFUNDED/DISPUTED → ESCALATED
- **Modes**: CASH_LOCK (full upfront), PAYMENT_COMMITMENT (partial collateral)
- **Fee Tiers**: BRONZE 1.2%, SILVER 0.9%, GOLD 0.8%, DIAMOND 0.7%
- **Collateral BPS**: 1000-5000 (10%-50%)
- **Dispute**: 14 days arbiter → 7 days protocol arbiter
- **Deployment Tiers**: TESTNET → LAUNCH → GROWTH → MATURE

---

## Recent Features Added (v2)

- Amendment flow (propose/approve/execute amendments)
- Tolerance/variance (toleranceBps field)
- Partial drawing/release (releasedAmount, drawingCount)
- Receivable routing to NFT holder
- receive() for ETH compatibility
