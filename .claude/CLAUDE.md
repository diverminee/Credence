# Credence — AI Agent Instructions

**Read this file at the START of every task.** This is my instruction manual for working on this project.

---

## Quick Start (What To Do First)

1. **Read this file** — you're doing it now ✅
2. **Check `.claude/todo.md`** — see what's in progress
3. **Check `.claude/lessons.md`** — learn from past mistakes
4. **Run `forge build`** — verify project compiles

---

## Project Overview

**Credence** — Programmable escrow infrastructure for international trade on Ethereum.

- **Backend**: Solidity 0.8.24 / Foundry
- **Frontend**: Next.js 16 / wagmi v2 / viem v2
- **Architecture**: TradeInfraEscrow → DisputeEscrow → BaseEscrow

---

## Commands You Can Trigger

| Trigger | What Happens |
|---------|--------------|
| `/project:plan [task]` | Enter plan mode, create structured todo list |
| `/project:review` | Run pre-commit checklist (forge build, test, lint) |
| `/project:wrap-up` | End session: update todo, summarize, git status |
| `/project:learn [mistake]` | Capture a lesson from a correction |

---

## My Workflow Rules

### 1. Start Every Task By:
- Reading CLAUDE.md (done ✅)
- Checking `.claude/todo.md` for context
- Running `forge build` to ensure clean state

### 2. Before Writing Code:
- `/project:plan [task]` for anything 3+ steps
- Identify files to modify
- Identify state machine changes (if any)
- Plan tests needed

### 3. After Writing Code:
- **Always** run `forge build && forge test`
- If frontend changed: `cd web && pnpm lint`
- Use `/project:review` before done

### 4. End Every Session:
- Run `/project:wrap-up`
- Update `.claude/todo.md`
- Summarize to user what was done

---

## Smart Contract Rules

✅ **Always**:
- Use `nonReentrant` on external state-changing functions
- Use `whenNotPaused` on fund-handling functions
- Use SafeERC20 for token transfers
- Use custom errors (not require strings)
- Emit events for every state change
- Snapshot fee rates at creation time
- Support both ETH (address(0)) and ERC20

❌ **Never**:
- Introduce reentrancy vectors
- Use `delegatecall`, `selfdestruct`, `tx.origin`
- Skip tests for new functions

---

## Key Technical Details

- **Escrow States**: DRAFT → FUNDED → RELEASED/REFUNDED/DISPUTED → ESCALATED
- **Modes**: CASH_LOCK (full upfront), PAYMENT_COMMITMENT (partial collateral)
- **Fee Tiers**: BRONZE 1.2%, SILVER 0.9%, GOLD 0.8%, DIAMOND 0.7%
- **Collateral BPS**: 1000-5000 (10%-50%)
- **Dispute**: 14 days arbiter → 7 days protocol arbiter
- **Deployment Tiers**: TESTNET → LAUNCH → GROWTH → MATURE

---

## Build Commands

```bash
forge build                  # compile contracts
forge test                   # run tests
make sync-abi               # copy ABIs to web/
cd web && pnpm dev          # frontend
```

---

## Recent Features Added (v2)

- Amendment flow (propose/approve/execute amendments)
- Tolerance/variance (toleranceBps field)
- Partial drawing/release (releasedAmount, drawingCount)
- Receivable routing to NFT holder
- receive() for ETH compatibility

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

## Frontend Sync

After any Solidity change:
1. `make sync-abi`
2. Check `types/escrow.ts` mirrors EscrowTypes.sol
3. Run `cd web && pnpm typecheck`

---

## Lesson Capture

When you make a mistake or user corrects you:
1. Run `/project:learn [what happened]`
2. Rule gets added to `.claude/lessons.md`
3. Also appears in LEARNED RULES section below

---

## LEARNED RULES

*Rules captured from mistakes will appear here*
