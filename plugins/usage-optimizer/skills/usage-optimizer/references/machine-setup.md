# Machine-wide setup (verified against Claude Code docs, v2.1.x)

Makes the policy apply to every repo without installing this plugin anywhere. Back up `~/.claude/settings.json` and `~/.claude/CLAUDE.md` first and merge, don't overwrite.

## 1. `~/.claude/settings.json`
```json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku",
    "CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS": "4"
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent",
        "hooks": [ { "type": "command", "command": "python3 ~/.claude/hooks/agent-spawn-nudge.py", "timeout": 5 } ] }
    ]
  }
}
```
- `CLAUDE_CODE_SUBAGENT_MODEL` is only a default: an agent file's `model` and the Agent-call `model` param both beat it. So implementing subagents must be spawned with `model: "sonnet"`.
- There is no settings key for subagent concurrency; the env var is the mechanism.

## 2. `~/.claude/agents/` (user scope; applies everywhere)
- `Explore.md` — `model: haiku`, `tools: Read, Grep, Glob, Bash`, brief read-only search prompt. The docs state a user-level `Explore` overrides the built-in (which is Opus on subscriptions).
- `researcher.md` — `model: haiku`, adds WebFetch/WebSearch, sourced <300-word summaries.
- `reviewer.md` — `model: sonnet`, read-only, severity-ranked findings.
Frontmatter needs only `name` and `description`; `model` accepts `haiku|sonnet|opus|fable`, a full ID, or `inherit`. Overriding `general-purpose`/`Plan` by name is not documented; rely on the env var instead.

## 3. `~/.claude/hooks/agent-spawn-nudge.py`
PreToolUse hook on `Agent`; reads the tool input from stdin and, when a general-purpose call has no `model` or the prompt exceeds ~6000 chars, prints `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"<hint>"}}`. It never blocks and emits nothing otherwise, so it costs no tokens in normal use.

## 4. `~/.claude/CLAUDE.md`
Append a ≤10-line "Resource use" block: do trivial lookups directly; model table in one line; brief + short-report rule; ≤4 parallel agents; suggest `/clear`/`/compact`, never auto. Details stay in this skill.

## Not worth adding
Hooks on every prompt or tool call (they add context each turn); forcing all subagents to one model (`CLAUDE_CODE_SUBAGENT_MODEL_FORCE`) which breaks deliberate Sonnet/Opus agents.
