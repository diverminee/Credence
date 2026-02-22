Run a pre-commit review on all staged or recent changes.

Steps:
1. Run `git diff` (or `git diff --cached` if staged) to see all changes
2. Run `forge build` — confirm zero compilation errors
3. Run `forge test` — confirm all tests pass
4. Review each changed file against this checklist:

**Solidity Security**
- [ ] No reentrancy vectors (nonReentrant on external state-changing functions)
- [ ] Checks-effects-interactions pattern followed
- [ ] SafeERC20 used for all token transfers
- [ ] Custom errors used (not require strings)
- [ ] Events emitted for every state change
- [ ] No unchecked external calls without error handling
- [ ] Access control on admin functions (onlyOwner / modifiers)

**Smart Contract Logic**
- [ ] State machine transitions are valid (no impossible paths)
- [ ] ETH and ERC20 paths both handled where applicable
- [ ] Edge cases: zero amounts, zero addresses, self-referential parties
- [ ] Fee calculations use snapshotted rates, not live rates

**Code Quality**
- [ ] Changes are minimal — only what was asked
- [ ] No leftover debug code or commented-out blocks
- [ ] `forge fmt` has been run

Report findings. If issues found, list them with severity (critical / warning / nit).
