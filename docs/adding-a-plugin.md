# Adding a new plugin

1. Create `plugins/<plugin-name>/` (kebab-case name).
2. Add the three manifests, all with the same `name` and starting at `version: "1.0.0"`:
   - `plugins/<plugin-name>/.claude-plugin/plugin.json`
   - `plugins/<plugin-name>/.codex-plugin/plugin.json` (`skills` field points at
     `../skills`)
   - `plugins/<plugin-name>/plugin.json` (Agent Plugins 1.0 — `skills` field is an array
     of paths, e.g. `["./skills/<skill-name>"]`)
3. Add one directory per skill under `plugins/<plugin-name>/skills/<skill-name>/`:
   - `SKILL.md` with frontmatter `name` (must equal the directory name, ≤64 characters —
     Copilot's hard limit) and `description` (≤1024 characters — also Copilot's limit).
     Keep the body short: an overview plus a bullet list of `references/*.md` files and
     when to load each one.
   - `references/*.md` — the actual detail, one topic per file, loaded only when the
     situation calls for it. Don't put everything in `SKILL.md` itself.
4. Add `plugins/<plugin-name>/README.md` — a couple of sentences plus a pointer to the
   skill(s).
5. Register the plugin in the repo-root `.claude-plugin/marketplace.json`'s `plugins`
   array (`name`, `source: "./plugins/<plugin-name>"`, `description`).
6. See `versioning.md` for how to version it and `cross-tool-compatibility.md` for why
   three manifest files exist.
