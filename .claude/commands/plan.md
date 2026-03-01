# /project:plan — Plan a new task

**Usage**: `/project:plan [task description]`

## Steps:
1. Read `.claude/todo.md` for current state
2. Read `.claude/lessons.md` for rules
3. Identify affected files and state changes
4. Create todo list in `.claude/todo.md` under "## Active Sprint"
5. Present plan to user for approval

## For Smart Contracts:
- Map state transitions (entry → exit states)
- Identify tests to add/update
- Note security considerations

## Example:
```
/project:plan add new oracle integration
```
