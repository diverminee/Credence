# Credence — NEVER Touch These

**CRITICAL**: These rules are absolute prohibitions. Violating them risks funds.

---

## Smart Contract Hard Rules

### ❌ NEVER Use:
- `delegatecall` — can lead to complete protocol takeover
- `selfdestruct` — destroys contracts, traps funds
- `tx.origin` — vulnerable to phishing attacks
- `require(condition, "message")` — use custom errors instead

### ❌ NEVER Skip:
- `nonReentrant` modifier on any external state-changing function
- Events for state changes (breaks offchain indexing)
- Tests for new functions

---

## Security Non-Negotiables

- Always use `nonReentrant` on external state-changing functions
- Always use `whenNotPaused` on fund-handling functions
- Always use SafeERC20 for token transfers
- Always use custom errors (not require strings)
- Always snapshot fee rates at creation time
- Always support both ETH (`address(0)`) and ERC20 tokens

---

## State Machine Invariants

**NEVER** manually transition escrow states except through defined functions:
- `fundEscrow()` → DRAFT → FUNDED
- `release()` → FUNDED → RELEASED
- `refund()` → FUNDED → REFUNDED
- `raiseDispute()` → FUNDED → DISPUTED
- `resolveDispute()` → DISPUTED → RESOLVED

---

## Never Refactor Without Reason

- Don't "clean up" working code
- Don't rename variables for style only
- Don't change patterns that work
- Only modify what's necessary for the task
