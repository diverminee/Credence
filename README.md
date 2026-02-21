# Credence

> Production-grade escrow infrastructure for international trade on Ethereum.

Credence secures real-world trade transactions on-chain. Funds are locked in a smart contract escrow, a centralized oracle confirms delivery, and a two-tier dispute system handles disagreements — all without a bank, broker, or middleman collecting rent on the transaction.

---

## Table of Contents

- [Credence](#credence)
  - [Table of Contents](#table-of-contents)
  - [Why Credence](#why-credence)
  - [Supported Tokens](#supported-tokens)
  - [Architecture](#architecture)
  - [Core Features](#core-features)
  - [KYC \& Access Control](#kyc--access-control)
    - [How it works](#how-it-works)
    - [Owner functions](#owner-functions)
  - [Oracle](#oracle)
    - [CentralizedTradeOracle](#centralizedtradeoracle)
  - [Reputation \& Fee Tiers](#reputation--fee-tiers)
  - [Dispute Resolution](#dispute-resolution)
  - [Contract Reference](#contract-reference)
    - [`TradeInfraEscrow`](#tradeinfraescrow)
    - [Constructor Parameters](#constructor-parameters)
    - [Environment Variables (deploy script)](#environment-variables-deploy-script)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Install](#install)
    - [Build](#build)
    - [Local Node](#local-node)
  - [Testing](#testing)
  - [Deployment](#deployment)
    - [Local (Anvil)](#local-anvil)
    - [Testnet / Mainnet](#testnet--mainnet)
  - [Security](#security)
    - [Design Safeguards](#design-safeguards)
    - [Audit](#audit)
    - [Known Limitations](#known-limitations)
  - [Roadmap](#roadmap)
  - [Contributing](#contributing)
  - [License](#license)

---

## Why Credence

Traditional cross-border trade depends on a chain of intermediaries — correspondent banks, trade finance desks, letters of credit, and escrow agents — each adding cost, delay, and counterparty risk. A standard letter of credit alone can take 5–10 business days to issue, cost 0.5–3% of the transaction value in bank fees, and require mountains of paperwork that still get lost or forged.

Credence eliminates that stack entirely.

| Problem in traditional trade         | How Credence handles it                                                                                              |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| **Bank LC fees (0.5–3%)**            | Protocol fees start at 1.2% and fall to 0.7% as reputation grows — no bank margin on top                             |
| **5–10 day settlement**              | Funds release the moment the oracle confirms delivery or the buyer clicks confirm — settlement is instant            |
| **Counterparty risk**                | Funds are locked in a non-custodial smart contract; neither party can unilaterally withdraw                          |
| **Dispute takes weeks / litigation** | On-chain arbitration resolves in 14 days at primary level, 7 additional days at protocol level                       |
| **Geographic limitation**            | Any two parties with an Ethereum wallet and KYC approval can trade — no correspondent bank network required          |
| **Currency conversion friction**     | Trade in USDC or USDT and eliminate FX exposure entirely; escrow and release happen in the same stable token         |
| **Opaque fee structures**            | Fee rate is snapshotted at escrow creation and permanently visible on-chain — no surprise deductions                 |
| **Reputation locked in one bank**    | On-chain reputation is portable and public; DIAMOND traders pay less regardless of which bank their counterpart uses |
| **Forgeable paperwork**              | Trade data is hashed and verified by the oracle against an immutable on-chain record                                 |

---

## Supported Tokens

Credence supports native **ETH** and any **ERC20 token**. The recommended tokens — those seeded into the on-chain allowlist at deployment — are:

| Token    | Network         | Address                                      |
| -------- | --------------- | -------------------------------------------- |
| **ETH**  | Any EVM chain   | `address(0)`                                 |
| **USDC** | Mainnet         | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| **USDT** | Mainnet         | `0xdAC17F958D2ee523a2206206994597C13D831ec7` |
| **USDC** | Sepolia testnet | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` |
| **USDT** | Sepolia testnet | `0x7169D38820dfd117C3FA1f22a697dBA58d90BA06` |

**Why USDC and USDT for international trade?**

- Both are USD-pegged and broadly liquid across exchanges and OTC desks.
- Eliminates FX risk between invoice and settlement — buyer locks $50,000 USDC, seller receives $50,000 USDC minus the protocol fee.
- USDC is regulated under US money transmission law (Circle); USDT is the most liquid stablecoin by volume. Both are accepted collateral across DeFi and CEX rails, making liquidation or conversion straightforward for either party.
- Far cheaper to move than a SWIFT wire: a USDC transfer on Ethereum costs a few dollars of gas versus $25–50 per SWIFT message plus ~2 days settlement.

The allowlist is a soft recommendation layer — the escrow contract accepts any ERC20. The owner can add new tokens via `addApprovedToken()` as the stablecoin landscape evolves.

---

## Architecture

```
src/
├── CentralizedTradeOracle.sol   # Owner-controlled oracle registry
├── core/
│   ├── BaseEscrow.sol           # Abstract base: state, KYC, token registry, fund logic
│   ├── DisputeEscrow.sol        # Dispute & escalation layer
│   └── TradeInfraEscrow.sol     # Main entry point (delivery confirm + oracle)
├── interfaces/
│   └── ITradeOracle.sol         # Oracle interface
└── libraries/
    ├── EscrowTypes.sol          # Shared enums and structs
    └── ReputationLibrary.sol    # Pure fee/tier calculation functions
```

**Inheritance chain:**

```
BaseEscrow (abstract)
    └── DisputeEscrow
            └── TradeInfraEscrow   ← deploy this
```

`TradeInfraEscrow` is the production-facing contract. It inherits all escrow state management from `BaseEscrow` (including KYC and token registry) and all dispute logic from `DisputeEscrow`, adding delivery confirmation and oracle settlement on top.

---

## Core Features

| Feature              | Description                                                                         |
| -------------------- | ----------------------------------------------------------------------------------- |
| ETH & ERC20 escrows  | Pass `address(0)` for native ETH or any ERC20 token address                         |
| Stable token support | USDC and USDT seeded as recommended tokens at deployment                            |
| KYC gate             | Both buyer and seller must be KYC-approved before an escrow can be created          |
| Token allowlist      | On-chain registry of recommended tokens; queryable by frontends and integrators     |
| Oracle settlement    | `confirmByOracle()` verifies a `tradeDataHash` against the on-chain oracle registry |
| Manual confirmation  | `confirmDelivery()` lets the buyer release funds directly                           |
| Dispute initiation   | Either party can raise a dispute on any `FUNDED` escrow                             |
| Two-tier arbitration | Primary arbiter (14 days) → protocol arbiter escalation (7 days)                    |
| Timeout claims       | If an arbiter misses their deadline, either party can reclaim funds                 |
| Reputation system    | Trade history tracked on-chain; tiers and fees update automatically                 |
| Abuse prevention     | Dispute rate limiting — 10+ initiations or >50% loss rate blocks further disputes   |
| Amount bounds        | Min: 1,000 units — Max: 10,000,000 tokens (prevents dust and overflow edge cases)   |

---

## KYC & Access Control

Credence includes a basic on-chain KYC gate managed by the contract owner (the deploying address or a delegated admin).

### How it works

- `kycApproved[address]` — mapping from address to approval status.
- `createEscrow()` reverts with `NotKYCApproved()` if either the buyer (`msg.sender`) or the seller is not approved.
- KYC status does not affect funding, disputes, or settlement — only escrow creation.

### Owner functions

```solidity
// Approve or revoke a single address
escrow.setKYCStatus(address user, bool approved)

// Bulk onboarding
escrow.batchSetKYCStatus(address[] users, bool approved)

// Transfer admin rights (e.g. to a multisig)
escrow.transferOwnership(address newOwner)
```

The KYC layer is intentionally minimal. It is designed to be extended by plugging in an off-chain verification provider (e.g. Synaps, Fractal, Civic) which calls the above functions once a user completes identity verification. The contract itself does not store personal data.

---

## Oracle

Credence uses a centralized oracle with a clean pluggable interface (`ITradeOracle`). The deployed implementation is `CentralizedTradeOracle`.

### CentralizedTradeOracle

An owner-controlled on-chain registry. The Credence backend (or a multisig) calls `submitVerification()` after independently confirming that shipment or delivery data matches the trade record.

```solidity
// Backend submits confirmation
oracle.submitVerification(bytes32 tradeDataHash, bool result)

// Escrow queries during confirmByOracle()
oracle.verifyTradeData(bytes32 tradeDataHash) → bool
```

**Flow:**

1. Buyer and seller agree on trade terms off-chain; a `tradeDataHash` capturing those terms is committed to the escrow at creation.
2. When delivery is claimed, the Credence backend independently verifies the shipment proof and calls `submitVerification(hash, true)`.
3. Anyone (typically an automated relayer) calls `confirmByOracle(escrowId)` on the escrow contract. The escrow queries the oracle, and if verified, releases funds to the seller.

The oracle owner can be changed to a multisig via `oracle.transferOwnership(address)`.

---

## Reputation & Fee Tiers

Every address accumulates a reputation score from its completed escrows. Fees are deducted from the escrowed amount at release and forwarded to the `feeRecipient`.

| Tier        | Requirement                              | Protocol Fee |
| ----------- | ---------------------------------------- | ------------ |
| **BRONZE**  | New user / low activity                  | 1.2%         |
| **SILVER**  | ≥ 5 successful trades                    | 0.9%         |
| **GOLD**    | ≥ 20 successful trades, ≤ 1 dispute loss | 0.8%         |
| **DIAMOND** | ≥ 50 successful trades, 0 dispute losses | 0.7%         |

The tier is evaluated at escrow creation and snapshotted in the `feeRate` field, locking fee terms for the lifetime of that escrow regardless of subsequent reputation changes.

On a $100,000 USDC trade: a BRONZE user pays $1,200 in protocol fees; a DIAMOND user pays $700. For high-volume importers and exporters, the fee reduction compounds meaningfully over time.

---

## Dispute Resolution

Credence uses a two-tier escalation model to prevent arbitration deadlock.

```
FUNDED ──► DISPUTED ──► (arbiter resolves within 14 days)
                │
                └──► ESCALATED ──► (protocol arbiter resolves within 7 days)
                          │
                          └──► timeout → either party reclaims funds
```

1. **Raise** — buyer or seller calls `raiseDispute()`, opening a 14-day window for the designated `arbiter`.
2. **Resolve** — arbiter calls `resolveDispute(ruling)`. Ruling `1` releases to seller; ruling `2` refunds buyer.
3. **Escalate** — if the arbiter does not act within 14 days, either party escalates to the `protocolArbiter` (multisig recommended), opening a fresh 7-day window.
4. **Timeout** — if the protocol arbiter also fails to act, either party can call `claimTimeout()` to recover funds.

The `disputesInitiated` and `disputesLost` mappings feed directly into reputation calculations and the abuse-prevention rate-limiter.

---

## Contract Reference

### `TradeInfraEscrow`

| Function                             | Access                 | Description                                       |
| ------------------------------------ | ---------------------- | ------------------------------------------------- |
| `createEscrow(...)`                  | KYC-approved addresses | Create a new `DRAFT` escrow                       |
| `fund(id)`                           | Buyer                  | Move escrow to `FUNDED` state                     |
| `confirmDelivery(id)`                | Buyer                  | Release funds to seller                           |
| `confirmByOracle(id)`                | Anyone                 | Settle via oracle hash verification               |
| `raiseDispute(id)`                   | Buyer / Seller         | Transition to `DISPUTED`                          |
| `resolveDispute(id, ruling)`         | Arbiter                | Resolve primary dispute                           |
| `escalateToProtocol(id)`             | Buyer / Seller         | Move to `ESCALATED` after primary arbiter timeout |
| `resolveEscalation(id, ruling)`      | Protocol Arbiter       | Final on-chain resolution                         |
| `claimTimeout(id)`                   | Buyer / Seller         | Recover funds after full escalation timeout       |
| `setKYCStatus(user, approved)`       | Owner                  | Approve or revoke KYC for an address              |
| `batchSetKYCStatus(users, approved)` | Owner                  | Bulk KYC updates                                  |
| `addApprovedToken(token)`            | Owner                  | Add a token to the recommended list               |
| `removeApprovedToken(token)`         | Owner                  | Remove a token from the recommended list          |
| `transferOwnership(newOwner)`        | Owner                  | Hand off admin rights                             |
| `getUserTier(addr)`                  | View                   | Returns the `UserTier` enum for an address        |
| `getUserTierName(addr)`              | View                   | Returns tier as a human-readable string           |

### Constructor Parameters

```solidity
constructor(
    address _oracleAddress,   // ITradeOracle implementation
    address _feeRecipient,    // Receives protocol fees on release
    address _protocolArbiter  // Final escalation authority (multisig recommended)
)
// msg.sender becomes the contract owner (KYC admin + token registry admin)
```

### Environment Variables (deploy script)

| Variable           | Default          | Description                                       |
| ------------------ | ---------------- | ------------------------------------------------- |
| `PRIVATE_KEY`      | Anvil key #0     | Deployer private key                              |
| `FEE_RECIPIENT`    | Anvil address #1 | Address that collects protocol fees               |
| `PROTOCOL_ARBITER` | Anvil address #2 | Final escalation arbiter (use a multisig)         |
| `ORACLE_OWNER`     | Deployer address | Address authorized to call `submitVerification()` |
| `USDC_ADDRESS`     | Sepolia USDC     | USDC address seeded into token allowlist          |
| `USDT_ADDRESS`     | Sepolia USDT     | USDT address seeded into token allowlist          |

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

```shell
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Install

```shell
git clone <repo-url>
cd credence
forge install
```

### Build

```shell
forge build
```

### Local Node

```shell
anvil
```

---

## Testing

```shell
# Run all tests (serial mode — required due to vm.setEnv in deploy tests)
forge test

# Verbose output with gas usage
forge test -vvv

# Run a specific test file
forge test --match-path test/TradeInfraEscrowTest.t.sol -vvv

# Gas snapshot
forge snapshot
```

| Test File                    | Covers                                                           |
| ---------------------------- | ---------------------------------------------------------------- |
| `BaseEscrowTest.t.sol`       | Escrow creation, funding, KYC checks, token allowlist, ownership |
| `DisputeEscrowTest.t.sol`    | Dispute flow, escalation, timeouts, rate limiting                |
| `TradeInfraEscrowTest.t.sol` | Delivery confirmation, oracle settlement, reputation tiers       |
| `DeployCredenceTest.t.sol`   | Deployment script, env var overrides, post-deploy interactions   |

121 tests, 0 failures.

> Tests run with `jobs = 1` (set in `foundry.toml`). The deploy test suite uses `vm.setEnv` to test environment variable overrides; parallel execution creates race conditions on the shared OS process environment.

---

## Deployment

### Local (Anvil)

```shell
# Start a local node in a separate terminal
anvil

# Deploy using default Anvil keys
forge script script/DeployCredence.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

### Testnet / Mainnet

```shell
export PRIVATE_KEY=<your_deployer_key>
export FEE_RECIPIENT=<fee_recipient_address>
export PROTOCOL_ARBITER=<multisig_address>
export ORACLE_OWNER=<backend_eoa_or_multisig>

# Optional: override token addresses for the target network
export USDC_ADDRESS=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48   # mainnet USDC
export USDT_ADDRESS=0xdAC17F958D2ee523a2206206994597C13D831ec7   # mainnet USDT

forge script script/DeployCredence.s.sol \
  --rpc-url <rpc_url> \
  --broadcast \
  --verify
```

The script deploys `CentralizedTradeOracle` and `TradeInfraEscrow` in sequence, then seeds the token allowlist with ETH, USDC, and USDT. The deployer's address becomes both the escrow owner and defaults to the oracle owner (override with `ORACLE_OWNER`).

**Post-deploy checklist:**

- [ ] KYC-onboard initial traders via `batchSetKYCStatus()`
- [ ] Transfer oracle ownership to the backend EOA or operational multisig: `oracle.transferOwnership(backendEOA)`
- [ ] Transfer escrow ownership to a governance multisig: `escrow.transferOwnership(multisig)`
- [ ] Verify contracts on Etherscan using `--verify`

---

## Security

### Design Safeguards

- **Reentrancy** — all state-changing external functions use `nonReentrant`.
- **Role separation** — buyer, seller, arbiter, protocol arbiter, and fee recipient are strictly distinct; the constructor enforces this.
- **KYC gate** — both escrow parties must be approved before funds can be committed.
- **Phantom escrow prevention** — the `escrowExists` mapping blocks attacks on non-existent IDs.
- **Fee snapshot** — fee rate is locked at escrow creation; no mid-flight manipulation is possible.
- **Dispute rate limiting** — users with ≥ 10 disputes initiated, or a >50% loss rate (with ≥ 3 losses), are blocked from raising further disputes.
- **Amount bounds** — `MIN_ESCROW_AMOUNT = 1,000` and `MAX_ESCROW_AMOUNT = 10,000,000e18` prevent dust attacks and arithmetic overflow edge cases.
- **Non-custodial** — no admin can unilaterally drain funds; all fund movements require a valid state transition.

### Audit

An automated security analysis report generated by [Aderyn](https://github.com/Cyfrin/aderyn) is available at [`report.md`](report.md).

> A formal third-party audit has not yet been conducted. **Do not deploy to mainnet with real funds until a professional audit is completed.**

### Known Limitations

- `CentralizedTradeOracle` is centralized by design — the oracle owner is a single EOA or multisig. A compromised oracle owner can submit false verifications. Migrate to a decentralized oracle (Chainlink Functions) for trustless operation.
- The `protocolArbiter` should be a multisig (e.g. Gnosis Safe), not a single EOA.
- Contracts are immutable by design — re-deployment is required for any upgrades.

---

## Roadmap

- [x] Centralized `ITradeOracle` implementation (`CentralizedTradeOracle`)
- [x] USDC / USDT token allowlist
- [x] KYC gate on escrow creation
- [ ] Multi-sig protocol arbiter integration (Gnosis Safe)
- [ ] Frontend interface for trade participants
- [ ] Testnet deployment (Sepolia / Base Sepolia)
- [ ] Third-party security audit
- [ ] Decentralized oracle migration (Chainlink Functions)
- [ ] Mainnet deployment
- [ ] Subgraph indexing for trade history & analytics

---

## Contributing

Contributions are welcome. Please follow these steps:

1. Fork the repository and create a feature branch (`git checkout -b feat/your-feature`).
2. Write or update tests for any changed behaviour — all tests must pass (`forge test`).
3. Format code before opening a PR (`forge fmt`).
4. Open a pull request with a clear description of the change and its motivation.

For significant changes or new features, please open an issue first to discuss the approach before implementation.

---

## License

This project is licensed under the [MIT License](LICENSE).
