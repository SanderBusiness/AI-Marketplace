---
name: clean-dotnet-architecture
description: Reference architecture for .NET solutions — many small class-library projects grouped by responsibility, a one-class-per-use-case Handler pattern, thin controllers, and attribute-based DI. Load this when scaffolding a new .NET project or solution, reviewing an existing .NET solution's project structure, deciding which project a new class belongs in, or writing/reviewing ASP.NET Core controllers or handler classes.
---

Use this skill whenever you're structuring a .NET solution, deciding where a new class
belongs, or writing a controller/handler pair. Prefer **many small, focused projects**
grouped by responsibility over a few large ones — see `references/guiding-principle.md`
for when to split.

Read only the reference file(s) relevant to the task at hand:

- **`references/project-layout.md`** — the standard solution/project layout (`Domain.*`,
  `DAL.*`, `BL.Core`, `BL.<Feature>`, `Integrations.*`, `Runnables.*`, `Tests/`). Load when
  scaffolding a new solution or deciding which project a class belongs in.
- **`references/guiding-principle.md`** — why to default to splitting projects rather than
  merging them, and the signs a project has grown too big. Load when unsure whether
  something needs its own new project.
- **`references/handler-pattern.md`** — the one-class-per-use-case `Handle(...)` pattern.
  Load when writing or reviewing business logic.
- **`references/controller-pattern.md`** — thin controllers, and why handlers must be
  injected with `[FromServices]` per action, not via the constructor. Load when writing or
  reviewing an ASP.NET Core controller.
- **`references/di-convention.md`** — the `[Service]`/`[Handler]`/`[Helper]` attribute
  scanning convention that replaces manual `services.AddScoped<T>()` calls. Load when
  wiring up DI or adding a new service/handler class.
- **`references/versioning-and-tooling.md`** — always target the latest stable .NET
  SDK/runtime and NuGet package versions. Load when scaffolding a project or checking
  dependency versions.
