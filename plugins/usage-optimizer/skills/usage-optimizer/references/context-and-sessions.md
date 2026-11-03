# Context and sessions

Each request re-sends the whole context; long sessions get expensive per turn, and edits to earlier context force a re-cache. Keep context purposeful.

- `/clear`: the next task is unrelated to what is in context. Suggest it; the user decides. Never clear during unfinished work.
- `/compact`: long session, task still in progress, user stepping away or context is bloated with finished exploration. Give it focus ("keep the plan and failing test names"). Don't compact when context is still small and useful.
- Handoff note when ending or clearing mid-task (≤10 lines): goal, state, files touched, next step, open questions. Put it in the reply or a scratch file, not in memory.
- Start a fresh session for a new feature or after a long unrelated detour.
- Don't re-read files you just edited; don't re-run exploration whose result is already above.

Memory placement:
1. Global `~/.claude/CLAUDE.md`: short, always-true rules only (aim well under 200 lines).
2. Project `CLAUDE.md`: that repo's standards and commands.
3. Skills: situational workflows and detail, loaded on demand.
4. Not memory: task state, in-progress notes, anything derivable from the code or git.
Remove duplicates between levels, but never delete project standards just to shrink them.
