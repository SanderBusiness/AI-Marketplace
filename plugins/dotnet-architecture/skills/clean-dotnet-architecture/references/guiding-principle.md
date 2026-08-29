# Guiding principle: many small projects, not few big ones

Default to splitting, not merging. Every class belongs in the one project whose
responsibility it matches — not in whichever project happens to be open, not in a
catch-all `Common`/`Shared`/`Utils` project, and not bolted onto an existing project just
because it's "close enough." When a new responsibility appears (a new external system, a
new business capability, a new data-access provider), create a new project for it rather
than growing an existing one to cover it.

Signs a project has grown too big and should be split:

- It has more than one reason to change (e.g. it mixes two unrelated business
  capabilities).
- Its name no longer describes everything inside it.
- Other projects depend on it only for a small part of what it contains.

Small projects cost nothing extra under the DI convention (see `di-convention.md`) — a new
project just needs its handlers/services tagged with the right attribute and referenced
from the entry point; nothing else needs to know it exists.

**Why this matters:** each project ends up with exactly one reason to change. DI wiring is
automatic and convention-based rather than manually maintained. Controllers stay thin/dumb
so business logic is easy to find, test, and reuse outside the web layer.
