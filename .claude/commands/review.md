# /project:review — Pre-commit checklist

**Usage**: `/project:review`

## Steps:
1. Run `git diff` to see changes
2. Check `.claude/lessons.md` for rule violations
3. If Solidity changed: `forge build && forge test`
4. If frontend changed: `cd web && pnpm lint`

## Checklist:

**Always:**
- [ ] Check lessons.md rules against changes
- [ ] Verify minimal changes (no extra refactoring)

**If Solidity:**
- [ ] `forge build` passes
- [ ] `forge test` passes
- [ ] `forge fmt` passes
- [ ] nonReentrant on state changes
- [ ] Events for state changes

**If Frontend:**
- [ ] `pnpm lint` passes
- [ ] `pnpm typecheck` passes

## Report:
```
Review: [PASS/FAIL]
Issues: [list if any]
Verdict: READY / FIX FIRST
```
