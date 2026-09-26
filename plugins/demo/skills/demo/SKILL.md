---
name: demo
description: Build a demo report for the current change in an npm web project — write Playwright tests per acceptance criterion, record videos and screenshots, capture before/after screenshots against the base branch, and publish an HTML page with a title, the demos, the before/after comparison, and an acceptance-criteria checklist showing what is implemented and proven. Load this when the user asks for a demo, a demo page/artifact, a walkthrough video, before/after screenshots, or proof that acceptance criteria are met. Only for projects with a package.json.
---

Produces one demo page per change, with four sections in this order:

1. **Title** — what was built (ticket/branch name plus a one-line summary).
2. **Demo** — recorded Playwright videos and step screenshots of the new behaviour.
3. **Before / After** — the same screens on the base branch and on the current change.
4. **Acceptance criteria** — every AC with its status and the evidence that proves it.

All generated media stays inside the project in a git-ignored `.demo/` folder and is
deleted once the page is published; leftovers from earlier demos are cleared before each
new run. Everything shown must come from real runs. Never mark an AC as proven without a passing
test that asserts it, and never reuse or invent screenshots.

Workflow — load each reference when you reach that step:

1. **`references/preflight.md`** — verify this is an npm project (stop if there is no
   `package.json`), find the dev/start script and port, and collect the title and the
   acceptance criteria. Load first, always.
2. **`references/playwright-setup.md`** — install/configure Playwright in a way that
   doesn't disturb an existing e2e setup, and write one spec per AC with video and step
   screenshots. Load before writing any test.
3. **`references/before-after.md`** — check out the base ref in a separate worktree, run
   it side by side with the current code, and capture the same screens on both. Load
   when capturing the comparison.
4. **`references/acceptance-criteria.md`** — rules for mapping ACs to tests and choosing
   each AC's status (proven / implemented but not proven / failing / not implemented).
   Load before filling in the AC section.
5. **`references/report.md`** — how to assemble the page from `assets/report-template.html`,
   handle media files, publish it, and clean up the local media afterwards. Load last.

`scripts/collect-results.mjs` turns the Playwright JSON report into a manifest of tests,
statuses, videos and screenshots (and converts videos to MP4 when `ffmpeg` exists), so the
page is built from test output rather than from memory.
