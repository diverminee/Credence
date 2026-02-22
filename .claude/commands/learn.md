Capture a lesson from a mistake or correction.

The mistake/correction is: $ARGUMENTS

Steps:
1. Read `.claude/lessons.md` to find the current highest rule number
2. Analyze the mistake: what went wrong, why, and how to prevent it
3. Append a new numbered rule to `.claude/lessons.md` in this format:
   ```
   ### #N — [Short descriptive title]
   **Context**: What happened — the specific mistake or incorrect assumption
   **Rule**: The concrete rule to follow going forward
   **Applies to**: Which files/patterns this rule covers
   ```
4. If this rule is important enough to surface every session, also add a one-line summary to the `LEARNED RULES` section at the bottom of `CLAUDE.md`
5. Confirm the rule was added and read it back
