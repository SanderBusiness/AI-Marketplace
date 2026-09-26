# Preflight

## 1. npm project check

- A `package.json` must exist at the project root (or the app's package in a monorepo).
  If there is none, **stop** and tell the user this skill only supports npm projects.
- Detect the package manager from the lockfile: `package-lock.json` → npm,
  `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb`/`bun.lock` → bun. Use it for
  every install/run command (examples below use npm).
- The app must be servable locally. Look in `scripts` for, in order: `dev`, `start`,
  `preview` (after `build`), `serve`. If none exists, ask the user how the app is started.
- Work out the port and how to override it — needed to run base and current side by side:

  | Stack | Default | Override |
  |---|---|---|
  | Vite / SvelteKit / Astro | 5173 / 4321 | `npm run dev -- --port 3101 --strictPort` |
  | Next.js | 3000 | `npm run dev -- -p 3101` |
  | Create React App | 3000 | `PORT=3101 npm start` |
  | Angular CLI | 4200 | `npm start -- --port 3101` |
  | Nuxt | 3000 | `npm run dev -- --port 3101` |

  Otherwise read the script and config to find it.
- Note anything the app needs to boot: `.env*` files, a backend/API, seeded data, a
  login. If login is required, ask for test credentials or an existing auth setup (e.g. a
  Playwright `storageState`); never hardcode real credentials into committed specs — read
  them from environment variables.

## 2. Title

Derive, then confirm with the user only if unclear:
- ticket key and name from the branch (`feature/ABC-123-new-filter`) or PR title;
- a one-line summary of what changed, from the diff (`git diff <base>...HEAD --stat`)
  and commit messages.

## 3. Acceptance criteria

Sources, in order of preference:
1. ACs the user gives in the request.
2. The linked ticket or PR description, if accessible.
3. A spec/story file in the repo referenced by the branch or commits.

If none can be found, ask the user for them. Do not invent ACs from the diff — if the
user explicitly asks you to derive them, label them "derived from the code, not from a
ticket" in the report.

Number them `AC1`, `AC2`, … in the given order and keep the original wording; the test
titles and the report both use these numbers.

## 4. Base ref

The "before" is the merge-base with the main branch:
`git merge-base HEAD origin/main` (or `main`/`master`/`develop`, whichever the repo
uses). If the change is uncommitted on the main branch itself, the base is `HEAD` and the
"after" is the working tree. Record the short SHA of both for the report.

## 5. Output location

Everything the run generates — videos, screenshots, Playwright's `test-results`, the JSON
report, the base-ref worktree and the assembled page — lives inside the project in
`.demo/<slug>/` (slug = kebab-case of the ticket key or branch). Never write demo output to
a temp directory or anywhere outside the project.

Before the first run, make sure `.demo/` is in the project's `.gitignore` (the root one, or
the app package's in a monorepo); add it if missing and verify with
`git check-ignore -q .demo/x && echo ignored`. Specs and the demo Playwright config are
committed; `.demo/` never is.

**Clear old demo evidence first.** Before a new run, delete leftovers from earlier demos,
whatever change they were for — they are never reused:
- every folder under `.demo/` (stop dev servers still serving from a `.demo/*/base-src`
  worktree, then `git worktree remove --force` each one and `git worktree prune`);
- untracked, git-ignored output of earlier demo or recorded acceptance runs elsewhere in
  the project, such as `test-results/`, `playwright-report/`, or a suite's own
  `screenshots/`/`videos/` folder. Check with `git ls-files <dir>` and
  `git check-ignore` first: only delete what is **not tracked**; committed screenshots or
  reports stay.

Report what was removed and how much space it freed (`du -sh`).

The folder is temporary: it is deleted once the page is published (see `report.md`,
"Clean up").
