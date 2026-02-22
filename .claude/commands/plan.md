Enter plan mode for the task described in $ARGUMENTS.

Steps:
1. Read `.claude/todo.md` for current project state
2. Read `.claude/lessons.md` for relevant rules that apply
3. Identify which contracts, tests, and scripts are affected
4. Write a plan to `.claude/todo.md` under "## Active Sprint" with checkable items:
   - [ ] Each discrete implementation step
   - [ ] Tests to add or update
   - [ ] `forge build && forge test` verification
5. For each step, note: files touched, state transitions affected, security considerations
6. Present the plan for approval before writing any code

If the task touches escrow state transitions, explicitly map:
- Which states are valid entry points
- Which states result from the change
- What reverts should be tested
