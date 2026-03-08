# Credence — Frontend Rules

**Applies to**: All frontend files in `web/`

---

## Tech Stack

- Next.js 16 (App Router)
- wagmi v2 / viem v2
- TypeScript
- pnpm

---

## Build Commands

```bash
cd web && pnpm dev          # start dev server
cd web && pnpm build        # production build
cd web && pnpm lint         # ESLint
cd web && pnpm typecheck    # TypeScript check
```

---

## Frontend Sync Pipeline

After any Solidity change:
1. Run `make sync-abi` to copy ABIs to `web/src/lib/`
2. Check `types/escrow.ts` mirrors `EscrowTypes.sol`
3. Run `cd web && pnpm typecheck`

---

## Key Frontend Patterns

### Wagmi Hooks
- Use `useWriteContract` for state-changing functions
- Use `useReadContract` for view functions
- Use `useWaitForTransactionReceipt` for transaction confirmation

### Escrow Types
Frontend types should mirror Solidity structs:
- `EscrowTransaction` → `EscrowTransaction` type
- `EscrowState` enum values must match Solidity

---

## Component Structure

```
web/src/
├── app/          # Next.js pages (app router)
├── components/   # React components
│   ├── escrow/   # Escrow-specific components
│   ├── dispute/  # Dispute components
│   ├── admin/    # Admin components
│   ├── shared/   # Shared UI components
│   └── providers/# Context providers (Web3, Theme)
├── hooks/        # wagmi/viem hooks
├── lib/          # ABIs, configs, utilities
└── types/        # TypeScript type definitions
```

---

## Testing

```bash
cd web && pnpm test         # run unit tests
cd web && pnpm e2e          # run Playwright e2e tests
```
