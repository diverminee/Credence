# Credence — Smart Contract Rules

**Applies to**: All Solidity files in `src/`

---

## Build Commands

```bash
forge build                  # compile contracts
forge test                   # run tests
make sync-abi               # copy ABIs to web/
```

---

## Required Patterns

### ✅ Always Use:
- `nonReentrant` modifier on all external state-changing functions
- `whenNotPaused` on fund-handling functions
- `SafeERC20` for token transfers
- Custom errors (e.g., `revert InvalidAmount()`) — NOT `require` strings
- Events for every state change
- Snapshot fee rates at creation time
- Support both ETH (`address(0)`) and ERC20 tokens

### ❌ Never Use:
- `delegatecall`, `selfdestruct`, `tx.origin`
- `require(condition, "message")` — use custom errors instead
- Skip tests for new functions

---

## Frontend Sync

After any Solidity change:
1. `make sync-abi`
2. Check `types/escrow.ts` mirrors `EscrowTypes.sol`
3. Run `cd web && pnpm typecheck`

---

## Contract Architecture

- **BaseEscrow**: Core escrow logic — create, fund, release, refund
- **DisputeEscrow**: Dispute resolution — raise, resolve, escalate, timeout
- **TradeInfraEscrow**: Trade infrastructure — delivery confirmation, oracle verification
