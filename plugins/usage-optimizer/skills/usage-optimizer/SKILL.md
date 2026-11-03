---
name: usage-optimizer
description: Reduce Claude Code token and quota usage while keeping quality — choose the cheapest suitable model (Haiku/Sonnet/Opus), decide whether a subagent or parallel agents are worth it, size subagent context and reports, and manage /clear, /compact, memory and handoffs. Load when planning delegation, spawning subagents, a session is getting long or expensive, switching tasks, hitting usage limits, or setting up cost-efficient Claude Code configuration.
---

Goal: lowest usage that does not cost correctness. Never trade quality or verification for tokens.

Quick rules (load a reference only when the situation matches):
- Do it yourself if it is a few Grep/Read calls. Delegate only broad sweeps, truly independent parallel work, or output that would flood context.
- Haiku: find/locate, explore, doc lookup, simple research. Sonnet: implement, debug, refactor, real review. Opus: hard architecture, or Sonnet has demonstrably struggled.
- Brief subagents with goal + file paths + constraints; demand a short structured report. One agent per question; reuse earlier findings.
- Unrelated new task → suggest `/clear`. Long break mid-task → suggest `/compact`. Never do either unprompted mid-work.

References:
- **`references/model-selection.md`** — task → model table, escalation and de-escalation triggers. Load when choosing a model or setting an agent's `model`.
- **`references/subagents.md`** — when to delegate, parallelism limits, brief and report templates, reuse. Load before spawning any subagent.
- **`references/context-and-sessions.md`** — `/clear` vs `/compact`, handoff notes, memory placement, cache behaviour. Load when a session is long, switching tasks, or organising memory/CLAUDE.md.
- **`references/exploration-and-research.md`** — cheap code exploration and research workflows, avoiding repeat reads. Load for codebase investigation or web/doc research.
- **`references/machine-setup.md`** — verified machine-wide configuration (env vars, global agents, hook, CLAUDE.md block) with copy-paste templates. Load when asked to configure or audit a machine/repo for usage.
- **`references/checklist.md`** — before/after checklist for judging whether sessions got cheaper. Load when evaluating usage.
