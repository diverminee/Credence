# Credence — Task Tracker

Current development tasks and progress.

---

## Active Sprint

*Nothing in progress - waiting for new task*

---

## Completed

- [x] Core escrow logic (BaseEscrow) — create, fund, release, refund
- [x] Dispute resolution (DisputeEscrow) — raise, resolve, escalate, timeout
- [x] Trade infrastructure (TradeInfraEscrow) — delivery confirmation, oracle verification
- [x] Payment commitment mode — collateral, fulfillment, default claims
- [x] Document commitment — Merkle tree, 4-leaf (invoice, BOL, packing, COO)
- [x] Reputation system — 4 tiers, fee rate discounts
- [x] KYC allowlisting — single and batch
- [x] ERC-721 receivable minting (CredenceReceivable)
- [x] Deployment tiers — TESTNET/LAUNCH/GROWTH/MATURE with amount ceilings
- [x] Oracle integration — centralized + Chainlink
- [x] Protocol arbiter multisig governance
- [x] Deployment scripts (local, Sepolia, Chainlink variant)
- [x] Test suite — 11 test files (13 test suites), 301 tests
- [x] CI/CD — GitHub Actions workflows (test + web)
- [x] Local deployment to LAUNCH tier
- [x] Emergency pause mechanism (OpenZeppelin Pausable)
- [x] Security hardening — configurable bounds, mutable admin addresses, settled NFT locks, oracle merkle root verification
- [x] UCP 600 / URDTT trade standards compliance reference
- [x] Subgraph schema (`subgraph/schema.graphql`)
- [x] Next.js frontend scaffolding — dashboard, escrow detail, disputes, receivables, admin pages, wagmi hooks, ABI sync pipeline
- [x] Amendment flow — proposeAmendment/approveAmendment/executeAmendment/cancelAmendment
- [x] Tolerance/variance field — toleranceBps on EscrowTransaction
- [x] Post-shipment adjustment — adjustSettlement() within tolerance
- [x] Partial drawing/release — releasedAmount, drawingCount tracking
- [x] Receivable routing to NFT holder — funds go to current owner via IERC721
- [x] ETH compatibility — receive() function

---

## Backlog

### Infrastructure & Deployment

- [ ] Frontend interface polish and feature completeness
- [ ] Testnet deployment (Sepolia / Base Sepolia)
- [ ] Third-party security audit
- [ ] Mainnet deployment
- [ ] Subgraph mapping handlers and deployment
- [ ] Secondary market integration for receivable NFTs
- [ ] Multi-chain deployment (Arbitrum, Base, Optimism)

### Trade Finance Gaps — Phase 2+: Future

- [ ] Revolving escrow — auto-reinstatement after settlement, escrow template concept
- [ ] Linked escrow architecture — back-to-back LC for intermediaries
- [ ] Pre-delivery advance mechanism — seller draws against confirmed escrow before shipping
- [ ] Extended document types — warehouse receipt, insurance certificate slots
- [ ] Forfaiting metadata — recourse terms on receivable NFT
- [ ] Reverse-escrow — seller posts collateral (performance guarantee, advance payment guarantee)
- [ ] Acceptance state — explicit acceptDocuments() for usance/acceptance credit
- [ ] Standby mode flag — standby LC variant with beneficiary draw-down

---

## Session Notes

*Session notes will be added here when using /project:wrap-up*
