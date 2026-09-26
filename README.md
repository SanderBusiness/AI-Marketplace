# AI Marketplace

Sander's marketplace of reusable AI coding-agent plugins — guidance, conventions, and
patterns meant to be shared across projects instead of re-explained every time. Plugins support
**Claude Code** and **Codex CLI**; Copilot plugin compatibility is unverified.

## Structure

```
AI-Marketplace/
├── README.md
├── .claude-plugin/
│   └── marketplace.json        # Claude Code marketplace index — lists every plugin
├── docs/
│   ├── cross-tool-compatibility.md   # what each tool needs, and why
│   ├── versioning.md                 # semver conventions
│   └── adding-a-plugin.md            # step-by-step guide for a new plugin
└── plugins/
    └── <plugin-name>/
        ├── .claude-plugin/plugin.json    # Claude Code manifest
        ├── .codex-plugin/plugin.json     # Codex CLI manifest
        ├── plugin.json                   # Codex-compatible root manifest (same as namespaced manifest)
        ├── README.md
        └── skills/
            └── <skill-name>/
                ├── SKILL.md               # short overview, shared by all three tools
                └── references/            # detail, split by topic, loaded only when needed
```

Skill content lives in one place per plugin (`skills/`) and is kept deliberately short
and split into small, situationally-loaded files — `SKILL.md` is a table of contents, not
the content itself. Each tool gets its own thin manifest pointing at that shared content
rather than three copies of the same guidance.

## Plugins

| Plugin | Description |
|---|---|
| [`coolify`](./plugins/coolify) | Manage self-hosted Coolify servers over SSH. |
| [`newrelic`](./plugins/newrelic) | Query and troubleshoot New Relic (logs, errors, NRQL, agent setup) using credentials from environment variables. |
| [`dotnet-architecture`](./plugins/dotnet-architecture) | Clean .NET solution architecture: small per-responsibility projects, one-class-per-use-case handlers, thin controllers, attribute-based DI. |

## Using this marketplace

**Claude Code:**
```
/plugin marketplace add SanderBusiness/AI-Marketplace
/plugin install dotnet-architecture@ai-marketplace
```

**Codex CLI:**
```bash
codex plugin marketplace add https://github.com/SanderBusiness/AI-Marketplace
codex plugin add dotnet-architecture@ai-marketplace
codex plugin add coolify@ai-marketplace
codex plugin add newrelic@ai-marketplace
```
Start a new Codex thread after installing to pick up the skills. To refresh an existing
installation, run `codex plugin marketplace upgrade ai-marketplace`, then repeat the
`codex plugin add` commands.

**GitHub Copilot:** plugin installation is unverified after correcting the root manifest
for Codex. See `docs/cross-tool-compatibility.md` for the format conflict and shared skills.

## Adding a plugin

See [`docs/adding-a-plugin.md`](./docs/adding-a-plugin.md).

## Versioning

See [`docs/versioning.md`](./docs/versioning.md) — semver, bumped consistently across all
three manifest files per plugin.
