End-of-session wrap-up ritual.

Steps:
1. Run `forge build && forge test` — confirm everything is green
2. Run `git status` and `git diff` to see all uncommitted changes
3. Read `.claude/todo.md` and update it:
   - Mark completed items as `[x]`
   - Add any newly discovered tasks to the backlog
   - Under "## Session Notes", add a new entry:
     ```
     ### YYYY-MM-DD
     **Changes**: Bullet list of what was done
     **Open items**: Anything left unfinished
     **Handoff**: Context the next session needs to know
     ```
4. Read `.claude/lessons.md` — if any corrections happened this session, confirm they were captured as rules
5. Summarize the session to the user: what shipped, what's pending, any risks
