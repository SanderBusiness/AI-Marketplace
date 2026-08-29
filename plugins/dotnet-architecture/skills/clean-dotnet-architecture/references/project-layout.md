# Project layout

- **`Domain.*`** — pure models/enums, no dependencies on other layers (e.g. `Domain.Core`,
  `Domain.Identity`, `Domain.<Feature>`).
- **`DAL.Core`** — shared EF Core: abstract `DbContext`, entity configs, extensions,
  constants; provider-agnostic.
- **`DAL.SqlServer` / `DAL.Sqlite`** — one project per provider, each with its own
  migrations and concrete `DbContext` subclass.
- **`BL.Core`** — shared DI attributes (`[Service]`, `[Handler]`, `[Helper]`) and
  cross-cutting extensions. See `di-convention.md`.
- **One `BL.<Feature>` project per business capability** (e.g. `BL.Vacations`, `BL.Shifts`,
  `BL.Geocode`, `BL.API.Public`, `BL.Integrations.<Name>`) — each containing:
  - `Handlers/` — one sealed class per use case. See `handler-pattern.md`.
  - `Controllers/` — thin `ControllerBase` classes. See `controller-pattern.md`.
  - `Models/`, `Mappers/`, `Helpers/`, `Constants/` as needed, kept local to the feature.
- **`Integrations.*`** — one project per external system/data source.
- **`Runnables.API`** (or `Runnable.API`) — the actual ASP.NET Core entry point; wires DI,
  hosts controllers, background workers.
- **`Tests/`** — mirrors the main tree one-for-one, one test project per corresponding
  source project.
- The solution file groups these into solution folders matching the physical folders
  (`BL/`, `DAL/`, `Domain/`, `Integrations/`, `Runnables/`, `Tests/`), not a flat list.

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
