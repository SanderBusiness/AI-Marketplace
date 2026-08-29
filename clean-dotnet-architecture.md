# Clean .NET Architecture

This is the reference architecture and clean-code style to use for every .NET solution: many small,
focused class-library projects grouped by responsibility, rather than one or two fat projects.

Confirmed consistent across three real projects (BelMaison, ShiftPlanner, CodeAssistant), which
independently converged on the same shape. **BelMaison is the ultimate reference example** — see its
`backend/` tree and `backend/CLAUDE.md`.

## Why

Each project has exactly one reason to change. DI wiring is automatic and convention-based rather than
manually maintained. Controllers stay thin/dumb so business logic is easy to find, test, and reuse
outside the web layer.

## Layout

- **`Domain.*`** — pure models/enums, no dependencies on other layers (e.g. `Domain.Core`,
  `Domain.Identity`, `Domain.<Feature>`).
- **`DAL.Core`** — shared EF Core: abstract `DbContext`, entity configs, extensions, constants;
  provider-agnostic.
- **`DAL.SqlServer` / `DAL.Sqlite`** — one project per provider, each with its own migrations and
  concrete `DbContext` subclass.
- **`BL.Core`** — shared DI attributes (`[Service]`, `[Handler]`, `[Helper]`/`[Scoped]`/`[Transient]`)
  and cross-cutting extensions. These attributes are scanned and auto-registered (e.g.
  `InjectAttributesAsScopedFromReferences()`) — no manual `services.AddScoped<T>()` calls.
- **One `BL.<Feature>` project per business capability** (e.g. `BL.Vacations`, `BL.Shifts`,
  `BL.Geocode`, `BL.API.Public`, `BL.Integrations.Jira`) — each containing:
  - `Handlers/` — one sealed class per use case, named `<Verb><Noun>Handler` (e.g.
    `GetPublicListingDetailHandler`, `CreateVacationRequestHandler`), exposing a single `Handle(...)`
    method. This is the RequestHandler pattern: one class = one use case, constructor-injected
    dependencies, no shared "service god class" with many methods.
  - `Controllers/` — thin `ControllerBase` classes whose actions do little more than resolve a handler
    via `[FromServices]` and call `.Handle(...)`; no business logic in controllers.
  - `Models/`, `Mappers/`, `Helpers/`, `Constants/` as needed, kept local to the feature.
- **`Integrations.*`** — one project per external system/data source (mirrors `BL.Integrations.*`
  naming in CodeAssistant, or bare `Integrations.<Source>` in BelMaison).
- **`Runnables.API`** (or `Runnable.API`) — the actual ASP.NET Core entry point; wires DI, hosts
  controllers, background workers.
- **`Tests/`** — mirrors the main tree one-for-one, one test project per corresponding source project.
- Solution file groups these into solution folders matching the physical folders (`BL/`, `DAL/`,
  `Domain/`, `Integrations/`, `Runnables/`, `Tests/`), not a flat list.

## Example

```
Domain/
  Domain.Core/
  Domain.Identity/
DAL/
  DAL.Core/
  DAL.SqlServer/
  DAL.Sqlite/
BL/
  BL.Core/
  BL.<Feature>/
    Handlers/
      GetXHandler.cs
      CreateXHandler.cs
    Controllers/
      XController.cs
    Models/
    Mappers/
Integrations/
  Integrations.<Source>/
Runnables/
  Runnables.API/
Tests/
  BL.<Feature>.Tests/
```

When scaffolding a new .NET project or advising on where new code should live, default to this layout
unless told otherwise.
