---
name: web-design-guidelines
description: Review UI code against Vercel's Web Interface Guidelines (accessibility, focus states, forms, animation, typography, content handling, performance, navigation state, touch, theming, i18n, hydration, copy). Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices", and after building or reworking a screen.
---

# Web Interface Guidelines

Review files for compliance with Vercel's Web Interface Guidelines and report findings as
`file:line - issue`.

## How it works

1. Get the latest rules: fetch
   `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`
   (WebFetch, or `curl -sfL` when there is no fetch tool). If that fails, use the copy in
   `references/web-interface-guidelines.md`.
2. Read the files to review (the argument, or the files changed on the branch; ask when it's
   unclear).
3. Check them against every rule; the fetched text also defines the output format.
4. Report grouped by file, terse, `file:line` so the locations are clickable. When asked to
   fix, apply the fixes and re-check.

## Project conventions win

The guidelines are general. Where a project has its own rule, follow the project:
- Copy: the "Title Case for headings/buttons" rule is English style. Dutch and French UI copy
  keeps sentence case.
- Design system: a project's component library (e.g. MUI) already provides labels, focus rings
  and hover states; flag only what it doesn't cover.

## References

- `references/web-interface-guidelines.md` — snapshot of the rules (vercel-labs/web-interface-guidelines
  @ e3d624baaf29), used only when the live file can't be fetched.
- `references/LICENSE` — MIT license of the original (Vercel Labs). Adapted from
  vercel-labs/agent-skills `skills/web-design-guidelines`.
