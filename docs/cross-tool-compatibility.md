# Cross-tool compatibility

Every plugin in this marketplace is built to work in **Claude Code**, **Codex CLI**, and
**GitHub Copilot**. This works because all three tools understand the same `SKILL.md`
shape (YAML frontmatter with `name`/`description`, then a markdown body) — so each
plugin keeps one shared `skills/` directory, and only the thin manifest file differs per
tool.

## Per-plugin files

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json        # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json        # Codex CLI manifest
├── plugin.json             # Agent Plugins 1.0 manifest (cross-client incl. Copilot)
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md        # shared by all three tools
│       └── references/     # small files, loaded only when relevant
└── README.md
```

## What each tool needs

### Claude Code

- Repo root needs `.claude-plugin/marketplace.json` listing every plugin (`name`,
  `source`, `description`).
- Each plugin needs `.claude-plugin/plugin.json` (only `name` is required; we also set
  `version`, `description`, `author`).
- Skills live at `plugins/<plugin>/skills/<skill>/SKILL.md`, invoked as
  `/<plugin-name>:<skill-name>` or auto-invoked by description match.
- Users add this marketplace with `/plugin marketplace add SanderBusiness/AI-Marketplace`,
  then `/plugin install <plugin-name>@ai-marketplace`.

### Codex CLI

- Plugin manifest lives at `plugins/<plugin>/.codex-plugin/plugin.json` (`name`,
  `version`, `description`, `skills` — a path to the shared `skills/` directory so content
  isn't duplicated).
- Codex also auto-discovers skills directly from `.agents/skills/<skill>/SKILL.md` at repo
  root, independent of any plugin — not used here since our skills live under
  `plugins/<name>/skills/`, referenced by the `.codex-plugin/plugin.json` path instead.
- Codex also reads `AGENTS.md` at repo root for general project instructions, capped at
  32 KiB by default (`project_doc_max_bytes` in `config.toml`).

### GitHub Copilot

- Uses the emerging cross-client **Agent Plugins 1.0** standard
  (`https://agent-plugins.org`): a plain `plugin.json` at the plugin root (not namespaced
  under a tool-specific directory), with `$schema`, `name`, `version` (semver),
  `description`, `author`, `license`, `keywords`, and a `skills` array of paths.
- **Hard limits confirmed from GitHub's docs — respect these when writing any skill:**
  - `SKILL.md` frontmatter `name`: **max 64 characters**, must exactly match the skill's
    directory name.
  - `SKILL.md` frontmatter `description`: **max 1024 characters**.
- Copilot also reads repo-level `.github/copilot-instructions.md` (freeform, no
  confirmed cap) and path-scoped `.github/instructions/*.instructions.md` (frontmatter:
  `applyTo` glob, required) in a *consuming* repository — not applicable to this
  marketplace repo itself, only to repos that install a plugin from here and want
  additional repo-specific instructions layered on top.

## Keep skill content tool-agnostic

Write `SKILL.md` and its `references/*.md` files with no assumption about which tool is
reading them — no Claude-specific or Copilot-specific phrasing. Tool-specific behavior
(how a skill is invoked, size limits, discovery paths) belongs in the manifests and in
this document, not in the skill content itself.
