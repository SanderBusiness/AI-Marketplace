---
name: work-issues
description: Work through several GitHub issues one by one, each in a clean context (a fresh Sonnet subagent, or its own visible Terminal window in auto mode), so no task carries the context of the previous ones. Use when the user gives a list of issues or says "work through the open issues", "do these tasks one by one", "with a clean agent each time", or wants to save tokens/context across many tasks.
---

Goal: finish N issues without one growing context. The orchestrator (you) stays thin: it picks the order, starts one worker per issue, reads a short report, checks the diff, and moves on. Workers never see each other's work except through git history.

## 1. Plan the queue

1. List the issues: `gh issue list --state open --json number,title,labels` (or use the numbers the user gave).
2. **Group before ordering.** Read every issue briefly (title, body, comments: `gh issue view N --comments`, or one `gh issue list --json number,title,body`). Put issues in ONE group (one worker, one design, one commit series) when they:
   - need one shared design or data model (e.g. a feature plus its admin page plus its cost tracking);
   - change the same component, page or API in ways that would overwrite each other if done separately;
   - reference each other, or one is a follow-up or phase of another;
   - are the same bug seen from two angles.
   Keep issues apart when they only touch the same folder, are independent bugs, or are large mechanical changes (framework or runtime upgrades, mass renames): those get their own worker and run when nothing else is in flight.
   A group has at most ~3 issues. Larger: split in phases, each phase a group. State the groups to the user in one short list (group, issues, why) and proceed; do not wait for approval unless a grouping is a real judgement call.
   For a group, first let the worker (or you, when it is small) write a short shared design (data model, API, UI, what is out of scope), then implement all issues of the group against that design, one commit per issue where practical. This avoids rewriting the result of task A to fit task B.
3. Order the groups: small bugs first, then features; oldest first when equal. Independent groups touching the same area go next to each other.
4. **Skip and report** (do not start) issues that are hard to reverse or outward-facing: moving or renaming the repo or org, deploys that change data, deleting things, anything needing credentials you do not have. Say why in one line.
5. Research or design questions are fine: tell the worker to return findings or an options comparison instead of code.
6. Do not ask for a go per issue when the user already said to proceed. Ask only for real owner decisions.

## 2. Pick the mode

- **Subagent mode** (default): `Agent` with `subagent_type: "general-purpose"` and `model: "sonnet"`, one per issue, **sequentially** (wait for the completion notice before starting the next). Never two at once: they share one working tree and one `main`.
- **Terminal mode** (macOS, when the user wants to watch or answer questions): run `scripts/launch-terminal.sh <issue[,issue...]> <repo-dir> <work-dir>` from this skill's folder (a group is comma-separated, e.g. `89,92,93`; its marker is `done-89-92-93`). It names the session `gh #<issue>` (`claude --name`, e.g. `gh #95` or `gh #89,92,93`), so the issue key shows in the window title, the prompt box and `/resume`. It opens a Terminal.app window with an interactive `claude --permission-mode auto --model sonnet` session. The session touches `<work-dir>/done-<issue>` as its last step. Wait with a background command, not polling:
  `until [ -f <work-dir>/done-<N> ]; do sleep 5; done; echo done`
  (`run_in_background: true`, `timeout` 600000; re-arm if it expires and the task is still running). Use a scratch dir for `<work-dir>`.
  Still one window at a time, same reason. Test that the first window actually opens before relying on it.

## 3. Brief each worker (subagent mode)

Give the goal, not a history. Keep it to:

- repo path and branch; the issue number(s) of the group (the worker reads each with `gh issue view N --comments`) and why they are grouped;
- for a group: "write a short shared design first, then implement all issues against it, one commit per issue";
- "follow the repo's CLAUDE.md strictly" (translations, legal texts, tests, lint, typecheck);
- "build on recent local commits if they touch the same area (`git log -10`)";
- "if already done, change nothing and say so; if it needs an owner decision, stop and report instead of guessing";
- constraints: **do not push**, **do not mutate production data**, commit locally with the attribution lines required in the current session;
- the report format: status, what changed (`path:line` bullets), tests run, whether legal/i18n texts were checked, open questions. No code dumps.

## 4. Between issues

- Read only the short report. Check `git log -1 --stat` for the commit; open the diff only when the report looks off.
- Write one line to the user per finished issue: issue, status, commit hash, open question if any.
- Collect open questions and decisions for the end instead of interrupting, unless the next issue depends on the answer.
- If a worker stalls or fails, report it and continue with the next issue; do not retry endlessly.

## 5. Finish

- One summary table: issue, status (done / already done / needs decision / skipped), commit, tests.
- List the owner decisions that are open.
- Do **not** push per issue. Push once at the end, and only if the user's rules allow it (repos with a "single combined push" rule: one push of everything, after the user agrees).
- **Close finished issues after the push**, without asking: `gh issue close N --comment "Done in <hash>: <one line>"`. Close only issues that are really done and pushed. Leave open, and say why: an unconfirmed root cause, an open product decision, a research-only outcome, or an on-hold marker. Never delete issues. If the push fails, close nothing.
- Suggest `/clear` before the user switches to unrelated work.

## Why this saves tokens

Each worker starts cold with a ~15 line brief and a few thousand tokens of context instead of inheriting every earlier task. The orchestrator only ever holds the short reports. Sonnet does the implementing; Opus is not needed for the loop itself.
