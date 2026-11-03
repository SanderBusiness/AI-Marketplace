# Before/after checklist

Run `/usage` and compare a comparable week before vs after.

- [ ] Share of usage attributed to subagents (esp. general-purpose) went down, or those agents now run Haiku.
- [ ] No `Explore` runs on Opus (user-level `Explore` agent in place).
- [ ] Trivial lookups done directly, not via subagents.
- [ ] No two agents investigated the same thing; parallel agents ≤ ~4 and independent.
- [ ] Subagent reports were short and structured; no whole-repo handoffs.
- [ ] Unrelated tasks started after `/clear` or in a new session.
- [ ] Long sessions compacted before breaks; fewer "re-cached after earlier messages changed" tokens.
- [ ] Opus used only with a stated reason.
- [ ] Quality unchanged: tests/builds still run, diffs still reviewed, no rework from a too-weak model.
Judge by real `/usage` numbers; don't assume savings.
