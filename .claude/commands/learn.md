# /project:learn — Capture a lesson

**Usage**: `/project:learn [what went wrong]`

## Steps:
1. Read `.claude/lessons.md` to find current highest rule number
2. Analyze the mistake and create a rule
3. Append to `.claude/lessons.md`:
   ```markdown
   ### #N — [Title]
   **Context**: What happened
   **Rule**: What to do instead
   **Applies to**: Files/patterns
   ```
4. Also add one-line summary to CLAUDE.md under "LEARNED RULES"

## Example:
```
/project:learn forgot to add nonReentrant modifier
```
