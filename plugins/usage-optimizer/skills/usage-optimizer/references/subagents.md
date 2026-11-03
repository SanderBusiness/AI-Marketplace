# Subagents

Delegate when: a sweep touches many files, work is independent and parallelisable, or output would flood the main context. Otherwise do it directly: a subagent starts cold, re-reads context and pays its own startup cost.

Before spawning:
1. Is the answer already in this session? Reuse it; re-investigate only if files changed.
2. Is another agent already on the same question? Don't duplicate.
3. Pick the cheapest model that can do the job (see model-selection.md). Implementing agents get `model: "sonnet"` explicitly.
4. Parallel only for genuinely independent tasks; keep to ~4.

Brief template (pass paths, not repo dumps):
```
Goal: <one question or change>
Relevant: <file paths / symbols>   Constraints: <conventions that matter>
Do not: edit files / widen the search (for read-only agents)
Report: answer first, then <=10 bullets as path:line + note. No code dumps. Mark uncertainty.
```
For implementers add: run the project's lint/build/tests and report pass/fail, not logs.

Verify an implementer's diff yourself rather than trusting its summary.
Agent definitions live in `~/.claude/agents/*.md` (user) or `.claude/agents/` (project); see machine-setup.md for templates.
