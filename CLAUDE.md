# Credence — Claude Code Project Memory

## File Structure
```
CLAUDE.md                          ← you are here (auto-loaded by Claude Code)
.claude/
  lessons.md                       ← accumulated error rules (read at session start)
  todo.md                          ← task tracking & session notes
  commands/
    plan.md                        ← /project:plan [task]    — enter plan mode
    review.md                      ← /project:review         — pre-commit checklist
    wrap-up.md                     ← /project:wrap-up        — end-of-session ritual
    learn.md                       ← /project:learn [mistake] — capture a lesson

src/                               ← Solidity contracts
test/                              ← Foundry tests
script/                            ← Deployment scripts
lib/                               ← Git submodules (OZ, Chainlink, forge-std)
foundry.toml                       ← Foundry config

web/                               ← Next.js frontend
  src/
    app/                           ← App Router pages
    components/                    ← React components (providers/, escrow/, layout/, shared/)
    hooks/                         ← wagmi hooks (useCreateEscrow, useFundEscrow, etc.)
    lib/
      contracts/abis/              ← ABI JSON (synced from Foundry via `make sync-abi`)
      contracts/addresses.ts       ← Per-chain deployed addresses
      contracts/config.ts          ← wagmi contract configs
      wagmi.ts                     ← wagmi + viem client config
      constants.ts                 ← Domain constants mirroring Solidity
    types/escrow.ts                ← TypeScript types mirroring EscrowTypes.sol
```

**At session start**: read `.claude/lessons.md` for any project-specific rules.

---

## Project Overview
Programmable escrow infrastructure for international trade, built on Ethereum.
Replaces institutional trust (banks, intermediaries) with deterministic on-chain escrow.
Funds release via cryptographic proof of delivery, buyer confirmation, or arbitrated resolution.

## Tech Stack
- **Solidity 0.8.24** / Foundry (forge, cast, anvil)
- **EVM target**: Cancun
- **Compiler**: `via_ir = true`, optimizer 200 runs
- **Tests run serially** (`jobs = 1`) — deploy tests use `vm.setEnv` which shares OS env
- **Dependencies** (git submodules, NOT npm):
  - OpenZeppelin Contracts — `@openzeppelin/contracts=lib/openzeppelin-contracts/contracts`
  - Chainlink — `@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/`
  - forge-std

## Contract Architecture
```
TradeInfraEscrow (production entry point)
  └── DisputeEscrow (dispute + escalation logic)
        └── BaseEscrow (core escrow, KYC, reputation, documents, receivables)

Supporting:
  EscrowTypes          — shared enums (State, UserTier, DeploymentTier, EscrowMode) and structs
  ReputationLibrary    — pure tier/fee calculations
  CentralizedTradeOracle / ChainlinkTradeOracle — oracle implementations
  CredenceReceivable   — ERC-721 tokenized trade receivables
  ProtocolArbiterMultisig — multisig governance for escalated disputes
  ITradeOracle / IReceivableMinter — interfaces
```

## Key Domain Concepts
- **Escrow states**: DRAFT → FUNDED → RELEASED/REFUNDED/DISPUTED → ESCALATED
- **Two settlement modes**: CASH_LOCK (full upfront) and PAYMENT_COMMITMENT (partial collateral + maturity)
- **Fee model**: per-mille rates snapshotted at creation; tier-based (BRONZE 1.2%, SILVER 0.9%, GOLD 0.8%, DIAMOND 0.7%)
- **Collateral BPS range**: 1000–5000 (10%–50%), default 2000
- **Dispute flow**: party raises → arbiter has 14 days → escalate to protocol arbiter (7 days) → timeout refunds buyer
- **Document commitment**: 4-leaf Merkle tree (invoice, BOL, packing list, COO)
- **Deployment tiers**: TESTNET → LAUNCH → GROWTH → MATURE (one-way upgrades, each with escrow amount ceilings)

## Build & Test Commands
```bash
forge build                  # compile
forge test                   # run all tests (serial, jobs=1)
forge test -vvv              # verbose test output
forge test --match-path test/DeployCredenceTest.t.sol -vvv  # single test file
forge fmt                    # format code
forge snapshot               # gas snapshots
```

## Deployment
```bash
# Local (anvil)
forge script script/DeployCredence.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Sepolia
forge script script/DeployCredence.s.sol --rpc-url ${SEPOLIA_RPC_URL} --broadcast --verify

# Chainlink oracle variant
USE_CHAINLINK_ORACLE=true forge script script/DeployCredence.s.sol --rpc-url ${SEPOLIA_RPC_URL} --broadcast --verify
```

## Current Deployment (LAUNCH tier)
```
ORACLE_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
ESCROW_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
RECEIVABLE_ADDRESS=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

## Testing Patterns
- Base test helper: `test/EscrowTestBase.sol` — shared setup, helpers, mock deployment
- Mocks in `test/mocks/`: MockERC20, MockOracle, MockFunctionsRouter, HashSpecificMockOracle
- All tests inherit from EscrowTestBase or use forge-std Test directly
- Use `vm.prank()` / `vm.startPrank()` for caller impersonation
- Use `vm.warp()` for time manipulation (disputes, maturity)
- Use `vm.expectRevert()` with custom error selectors for negative tests

## Frontend (web/)

### Tech Stack
- **Next.js 16** App Router, TypeScript, Tailwind CSS v4
- **wagmi v2** + **viem v2** for contract interaction
- **RainbowKit v2** for wallet connection
- **TanStack Query v5** for data fetching

### Frontend Build Commands
```bash
cd web && pnpm dev              # start dev server
cd web && pnpm build            # production build
cd web && pnpm lint             # ESLint
cd web && pnpm typecheck        # tsc --noEmit
make sync-abi                   # copy ABIs: Foundry out/ → web/src/lib/contracts/abis/
make sync-env                   # copy addresses: .env.deployed → web/.env.local
make build-web                  # sync ABIs + build frontend
```

### ABI Sync Rule
After any contract changes, run `make sync-abi` before frontend work.
ABI files in `web/src/lib/contracts/abis/` are committed to git.

### Frontend Architecture
- **Pages**: `app/` — dashboard, escrow/[id], disputes, receivables, admin
- **Components**: `components/` — providers (Web3Provider), escrow UI, dispute UI, layout (Header), shared (StateChip, AddressDisplay, TierBadge, TokenAmount)
- **Hooks**: `hooks/` — useEscrowRead, useUserStats, useCreateEscrow, useFundEscrow, useEscrowActions (confirm, dispute, escalate, etc.)
- **Contract layer**: `lib/contracts/` — ABIs, addresses per chain, wagmi config objects
- **Types**: `types/escrow.ts` — mirrors EscrowTypes.sol (manually maintained)

### Frontend Verification
- After contract changes: `make sync-abi && cd web && pnpm typecheck`
- After frontend changes: `cd web && pnpm build`

---

## Workflow Rules

### 1. Plan Before Building
Enter plan mode for any non-trivial task (3+ steps or architectural impact).
- Use `/project:plan [task]` or write plan to `.claude/todo.md` with checkable items
- For smart contracts: always identify which state transitions change, what tests need updating, and security implications
- If something goes wrong mid-implementation, STOP and re-plan

### 2. Verification Before Done
- After every change: `forge build && forge test` — no exceptions
- For state machine changes: verify all valid state transitions still work AND invalid ones still revert
- Ask: "Would this pass a security audit review?"
- Diff behavior between main and changes when relevant

### 3. Self-Improvement Loop
- After ANY correction from the user: use `/project:learn [what happened]` to capture the rule
- Rules accumulate in `.claude/lessons.md`
- Review `.claude/lessons.md` at session start for relevant context

### 4. Smart Contract Discipline
- Never introduce reentrancy vectors — always use nonReentrant on external state-changing functions
- Follow checks-effects-interactions pattern
- Use SafeERC20 for all token transfers
- Custom errors over require strings (gas efficiency + clarity)
- Events for every state change
- Snapshot values at creation time, not at resolution time (fee rate pattern)
- Token-agnostic: always support both ETH (address(0)) and ERC20 paths

### 5. Minimal Impact
- Changes touch only what's necessary
- No refactoring beyond what was asked
- Fix root causes, not symptoms
- Simple solutions over clever ones

### 6. Task Tracking
- Plan in `.claude/todo.md`, track progress as you go
- Capture corrections and learnings in `.claude/lessons.md`
- End sessions with `/project:wrap-up` — summarize changes, note open items

## LEARNED RULES
<!-- Rules will be added here as they accumulate from lessons.md -->
<!-- Format: "- RULE: [description] (source: lessons.md #N)" -->
