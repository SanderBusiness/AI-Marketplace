# Model selection

| Task | Model |
|---|---|
| Locate files/classes/config, repo inspection, read a simple method | Haiku |
| Documentation lookup, straightforward web research, repetitive mechanical edits | Haiku |
| Implementation, debugging, refactoring, tests, meaningful code review | Sonnet |
| Hard architecture trade-offs, subtle cross-system reasoning, security-critical design | Opus |

Escalate to Opus only when you can state why: Sonnet already tried and failed, or the decision is hard to reverse and genuinely ambiguous. Escalate Haiku → Sonnet when a lookup turns into a judgment call or the result looks shaky.

Rules:
- Default is not Opus. Do not use Sonnet for simple tasks just because it is the session model.
- Avoid switching the main session model mid-task; changing it invalidates the prompt cache for the new model. Delegate to a differently-modelled subagent instead.
- Per subagent, resolution order (docs): Agent-call `model` param > agent file `model` > `CLAUDE_CODE_SUBAGENT_MODEL` > main model. The Agent-call param accepts only `haiku|sonnet|opus|fable`.
- The built-in `Explore` agent resolves to the Opus alias on subscription plans; override it with a user-level `Explore` agent that sets `model: haiku`.
- Quota weighting per model and for cache reads is not documented by Anthropic; do not assume. Use `/usage` to see what actually consumes quota.
