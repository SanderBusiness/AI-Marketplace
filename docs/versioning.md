# Versioning

Semantic versioning (`MAJOR.MINOR.PATCH`) everywhere a `version` field exists:

- **Marketplace** (`.claude-plugin/marketplace.json`) — bump when the set of plugins
  changes (add/remove a plugin) or the marketplace-level schema changes. Not tied to any
  individual plugin's version.
- **Plugin** (`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `plugin.json`) —
  all three manifests for a given plugin must carry the **same version number**, bumped
  together in the same commit:
  - **MAJOR** — a breaking change to the plugin's guidance that contradicts prior advice
    (e.g. reversing a pattern, renaming a skill).
  - **MINOR** — new guidance added (a new reference file, a new rule) without
    contradicting what's already there.
  - **PATCH** — wording fixes, typo corrections, clarifications with no change in
    substance.
- **Skills** have no separate version field (`SKILL.md` frontmatter doesn't support one
  across any of the three tools) — a skill's version is implicitly its plugin's version.

When bumping a plugin's version, update all three manifest files
(`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `plugin.json`) in the same
commit so they never drift out of sync.
