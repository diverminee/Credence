# Credence — AI Workflow & Backend Rules

**Read this file at the START of every task.**

---

## Quick Start (What To Do First)

1. **Read `.clinerules/` files** — you're doing this now ✅
2. **Run `forge build`** — verify project compiles
3. **Check project state** — review todo/backlog if applicable

---

## Workflow Rules

### 1. Start Every Task By:
- Reading `.clinerules/` files for context
- Running `forge build` to ensure clean state

### 2. Before Writing Code:
- Plan tasks with clear steps (3+ steps = structured approach)
- Identify files to modify
- Identify state machine changes (if any)
- Plan tests needed

### 3. After Writing Code:
- **Always** run `forge build && forge test`
- If frontend changed: `cd web && pnpm lint`

### 4. End Every Session:
- Verify with `forge build && forge test`
- Run `git status` to see changes
- Summarize to user what was done

---

## Session Management

- **Always read .clinerules/ files first** — they contain project context
- **Verify build passes** before making any changes
- **Keep changes minimal** — avoid unnecessary refactoring

---

## Build Verification

Always run these before considering a task complete:

**For Solidity changes:**
```bash
forge build
forge test
forge fmt
```

**For Frontend changes:**
```bash
cd web && pnpm lint
cd web && pnpm typecheck
```

---

## Learned Rules

When a mistake is made:
1. Correct the mistake
2. Document the lesson in a new section below
3. Update rules to prevent recurrence

### Existing Rules:
- **Rule #1**: Always read .clinerules/ files before doing anything — they contain project state, accumulated rules, and task priorities.
