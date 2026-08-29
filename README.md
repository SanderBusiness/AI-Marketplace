# AI Marketplace

Sander's marketplace of reusable AI coding-agent plugins — guidance, conventions, and
patterns meant to be shared across projects instead of re-explained every time. Every
plugin works in **Claude Code**, **Codex CLI**, and **GitHub Copilot**.

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
        ├── plugin.json                   # Agent Plugins 1.0 manifest (Copilot, cross-client)
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
| [`dotnet-architecture`](./plugins/dotnet-architecture) | Clean .NET solution architecture: small per-responsibility projects, one-class-per-use-case handlers, thin controllers, attribute-based DI. |

## Using this marketplace

**Claude Code:**
```
/plugin marketplace add SanderBusiness/AI-Marketplace
/plugin install dotnet-architecture@ai-marketplace
```

**Codex CLI / GitHub Copilot:** install the plugin from its `plugins/<name>/` directory
per that tool's plugin-loading mechanism — see `docs/cross-tool-compatibility.md` for the
manifest each one reads.

## Adding a plugin

See [`docs/adding-a-plugin.md`](./docs/adding-a-plugin.md).

## Versioning

See [`docs/versioning.md`](./docs/versioning.md) — semver, bumped consistently across all
three manifest files per plugin.
