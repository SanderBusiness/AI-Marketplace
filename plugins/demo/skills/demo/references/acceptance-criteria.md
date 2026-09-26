# Acceptance criteria: status and evidence

Every AC gets exactly one status, decided from test results — not from reading the code.

| Status | When | Evidence shown |
|---|---|---|
| **Proven** | Its test(s) passed and the assertions check what the AC states. | Test title, video, screenshots. |
| **Implemented, not proven** | The code implements it, but it can't be verified in the browser (e.g. an email is sent, a log is written, a backend-only rule, performance). | Where in the code (file:line), and what would prove it (unit/integration test, manual check). |
| **Failing** | A test for it exists and fails. | Error message, screenshot at failure, video. |
| **Not implemented** | No code for it exists in the diff. | Short explanation. |

Rules:
- An AC with several tests (`AC3a`, `AC3b`) is **Proven** only if all pass; otherwise
  **Failing**.
- A test that passes but only partly covers the AC wording (e.g. the AC says "on mobile
  and desktop" and only desktop was tested) is **Implemented, not proven**, with a note on
  the gap — or add the missing test.
- Skipped or flaky tests (passed only on retry) are not proof. Retries are off in the demo
  config for this reason.
- Never soften an assertion to turn **Failing** into **Proven**.

## Summary line

At the top of the AC section show a count, e.g. "4 of 5 acceptance criteria proven, 1
implemented without browser proof". If anything is **Failing** or **Not implemented**,
say so in the page subtitle as well — a reader skimming the title must not assume
everything is done.
