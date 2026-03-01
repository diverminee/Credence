# Credence — Lessons Learned

Rules accumulated from corrections and mistakes during development.
Claude reads this at session start. Each rule prevents a repeated error.

---

## How to Use This File
When Claude makes a mistake:
1. Correct it
2. Say: "Add this to lessons.md so you don't make that mistake again"
3. Claude proposes a rule, you approve, it gets appended below

Rules are numbered. Add new rules at the bottom.
Periodically review — archive rules that no longer apply.

---

## Rules

<!-- Example format:
### #1 — Always use custom errors, not require strings
**Context**: Used `require(condition, "message")` instead of custom error
**Rule**: Always use custom errors (e.g., `revert InvalidAmount()`) — they're cheaper on gas and consistent with the codebase pattern.
**Applies to**: All Solidity files in src/
-->

### #1 — Always read .claude/ files before doing anything
**Context**: Started a session by re-reading source files already in context instead of checking .claude/lessons.md and .claude/todo.md first. Wasted time and missed the established backlog.
**Rule**: At the start of every session (or when resuming after a break), the FIRST action is: read `.claude/lessons.md` and `.claude/todo.md`. These files contain the current project state, accumulated rules, and task priorities. Only after reading them should you touch source files or start implementing.
**Applies to**: Every session, no exceptions.
