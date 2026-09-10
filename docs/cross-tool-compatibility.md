# Cross-tool compatibility

Plugins support **Claude Code** and **Codex CLI**. **GitHub Copilot** plugin
compatibility is unverified; see the root manifest notes below. This works because all three tools understand the same `SKILL.md`
shape (YAML frontmatter with `name`/`description`, then a markdown body) — so each
plugin keeps one shared `skills/` directory, and only the thin manifest file differs per
tool.

**Priority order: Claude Code first, Codex CLI second, GitHub Copilot third.** Claude
Code and Codex support must never be compromised for Copilot's sake. If a future
requirement (e.g. a stricter length limit, a schema constraint) can't be satisfied by all
three at once, Copilot support is what gets dropped or degraded — not Claude Code or
Codex. The root manifest format is one such conflict; see below.

## Per-plugin files

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json        # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json        # Codex CLI manifest
├── plugin.json             # Codex-compatible root manifest (same as .codex-plugin/plugin.json)
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
  `version`, `description`, `author`, `interface`, and `skills`). Set `skills` to
  `./skills/`: paths resolve from the plugin root, not the `.codex-plugin/` directory.
  The shared skill content is not duplicated. Include display name, short and long
  descriptions, developer name, category, capabilities, and default prompts in `interface`.
- Codex also auto-discovers skills directly from `.agents/skills/<skill>/SKILL.md` at repo
  root, independent of any plugin — not used here since our skills live under
  `plugins/<name>/skills/`, referenced by the `.codex-plugin/plugin.json` path instead.
- Codex also reads `AGENTS.md` at repo root for general project instructions, capped at
  32 KiB by default (`project_doc_max_bytes` in `config.toml`).

### Root manifest precedence and GitHub Copilot

The installed Codex CLI reads root `plugin.json` before `.codex-plugin/plugin.json`.
Keep both files identical and Codex-compatible: `author` is an object and `skills`
is the string `"./skills/"`. A root manifest with a string author or an array of skill
paths prevents Codex installation even when the namespaced manifest is valid.

The previous Agent Plugins 1.0 root manifest has therefore been replaced, following
this repository's Claude Code > Codex > Copilot priority. Copilot plugin installation
with the new manifest has not been verified. The shared SKILL.md files remain usable
by skill-capable clients; preserve the 64-character skill name and 1024-character
description limits. Do not claim verified Copilot plugin compatibility without testing.

## Keep skill content tool-agnostic

Write `SKILL.md` and its `references/*.md` files with no assumption about which tool is
reading them — no Claude-specific or Copilot-specific phrasing. Tool-specific behavior
(how a skill is invoked, size limits, discovery paths) belongs in the manifests and in
this document, not in the skill content itself.
