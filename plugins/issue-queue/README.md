# Issue Queue

Work through several GitHub issues one by one, each with a clean context, so task 5 does not carry
the context of task 1. Lean on the orchestrator, one local commit per issue, one combined push at the end.

Skill: `work-issues` (see `skills/work-issues/SKILL.md`). Two modes:

- **Subagent** (default): one fresh Sonnet subagent per issue, run sequentially, short report back.
- **Terminal** (macOS Terminal.app): one visible interactive `claude` session per issue in auto mode, so you
  can follow it in colour and answer questions yourself. A marker file tells the orchestrator when it is done.

Usage: tell Claude "work through issues 94, 95, 97" or run `/issue-queue:work-issues`.
