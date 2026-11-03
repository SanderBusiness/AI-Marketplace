# Usage Optimizer

Rules for spending fewer tokens and less subscription quota without lowering quality: model
selection per task, lean subagent delegation, context and session management (`/clear`,
`/compact`, memory), and a before/after checklist.

See `skills/usage-optimizer/SKILL.md`. For always-on, machine-wide behaviour (cheap
default subagent model, global agents, a spawn-nudge hook) follow
`skills/usage-optimizer/references/machine-setup.md`; the plugin itself only teaches
the rules and is not required for that setup.
