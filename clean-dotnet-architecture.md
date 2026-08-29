# Clean .NET Architecture

Reference architecture and clean-code style for every .NET solution: many small, focused
class-library projects grouped by responsibility, rather than one or two fat projects.

## Why

Each project has exactly one reason to change. DI wiring is automatic and convention-based
rather than manually maintained. Controllers stay thin/dumb so business logic is easy to
find, test, and reuse outside the web layer.

## Guiding principle: many small projects, not few big ones

Default to splitting, not merging. Every class belongs in the one project whose
responsibility it matches — not in whichever project happens to be open, not in a
catch-all `Common`/`Shared`/`Utils` project, and not bolted onto an existing project just
because it's "close enough." When a new responsibility appears (a new external system, a
new business capability, a new data-access provider), create a new project for it rather
than growing an existing one to cover it.

Signs a project has grown too big and should be split:
- It has more than one reason to change (e.g. it mixes two unrelated business capabilities).
- Its name no longer describes everything inside it.
- Other projects depend on it only for a small part of what it contains.

Small projects cost nothing extra under the DI convention below — a new project just needs
its handlers/services tagged with the right attribute and referenced from the entry point;
nothing else needs to know it exists.

## Layout

- **`Domain.*`** — pure models/enums, no dependencies on other layers (e.g. `Domain.Core`,
  `Domain.Identity`, `Domain.<Feature>`).
- **`DAL.Core`** — shared EF Core: abstract `DbContext`, entity configs, extensions,
  constants; provider-agnostic.
- **`DAL.SqlServer` / `DAL.Sqlite`** — one project per provider, each with its own
  migrations and concrete `DbContext` subclass.
- **`BL.Core`** — shared DI attributes (`[Service]`, `[Handler]`, `[Helper]`) and
  cross-cutting extensions. See [DI convention](#di-convention) below.
- **One `BL.<Feature>` project per business capability** (e.g. `BL.Vacations`, `BL.Shifts`,
  `BL.Geocode`, `BL.API.Public`, `BL.Integrations.<Name>`) — each containing:
  - `Handlers/` — one sealed class per use case. See [Handler pattern](#handler-pattern).
  - `Controllers/` — thin `ControllerBase` classes. See [Controller pattern](#controller-pattern).
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

## Handler pattern

One sealed class per use case, named `<Verb><Noun>Handler`, exposing a single `Handle(...)`
method. Constructor-injected dependencies (primary constructors). No shared "service god
class" with many unrelated methods.

```csharp
[Handler]
public sealed class GetWidgetDetailHandler(AppDbContext db)
{
    public async Task<WidgetDetailDto?> Handle(Guid id, CancellationToken ct)
    {
        var widget = await db.Widgets
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.Id == id, ct);

        return widget?.ToDetailDto();
    }
}
```

## Controller pattern

Controllers resolve a handler via `[FromServices]` per action and do little more than call
`.Handle(...)`. No business logic in controllers — that all lives in the handler.

```csharp
[Controller, Route("Widgets")]
public sealed class WidgetsController : ControllerBase
{
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Detail(
        [FromServices] GetWidgetDetailHandler handler,
        Guid id,
        CancellationToken ct)
    {
        var dto = await handler.Handle(id, ct);
        return dto == null ? NotFound() : Ok(dto);
    }
}
```

## DI convention

Classes annotated with `[Service]`, `[Handler]`, or `[Helper]` are auto-registered as
scoped services — no manual `services.AddScoped<T>()` calls anywhere. `[Handler]` and
`[Service]` can simply derive from a base `[Scoped]` attribute; add a `[Transient]`
variant the same way if a feature ever needs transient lifetime.

```csharp
// Attributes
public class ScopedAttribute : Attribute { }
public sealed class HandlerAttribute : ScopedAttribute { }
public sealed class ServiceAttribute : ScopedAttribute { }
public sealed class HelperAttribute : ScopedAttribute { }

// Registration — scans the given assembly and everything it references
// for types carrying one of the attributes above, and registers each one
// (plus any interfaces it implements) as scoped.
public static class ServiceCollectionExtensions
{
    public static IServiceCollection InjectAttributesAsScopedFromReferences(
        this IServiceCollection services, Assembly rootAssembly)
    {
        foreach (var assembly in GetReferencedAssembliesRecursive(rootAssembly).Distinct())
        {
            var candidates = assembly.GetTypes()
                .Where(t => !t.IsAbstract && !t.IsInterface &&
                    (t.GetCustomAttribute<HandlerAttribute>() != null ||
                     t.GetCustomAttribute<ServiceAttribute>() != null ||
                     t.GetCustomAttribute<HelperAttribute>() != null));

            foreach (var type in candidates)
            {
                services.AddScoped(type);
                foreach (var iface in type.GetInterfaces())
                    services.AddScoped(iface, type);
            }
        }

        return services;
    }

    private static IEnumerable<Assembly> GetReferencedAssembliesRecursive(Assembly root)
    {
        var visited = new HashSet<string?>();
        var stack = new Stack<Assembly>();
        stack.Push(root);

        while (stack.Count > 0)
        {
            var current = stack.Pop();
            if (!visited.Add(current.FullName)) continue;
            yield return current;

            foreach (var reference in current.GetReferencedAssemblies())
            {
                try { stack.Push(Assembly.Load(reference)); }
                catch { /* ignore assemblies that can't be loaded */ }
            }
        }
    }
}
```

Call `services.InjectAttributesAsScopedFromReferences(typeof(Startup).Assembly)` once at
startup; every `[Handler]`/`[Service]`/`[Helper]` in the whole dependency graph gets wired
up automatically. Adding a new handler or service never requires touching DI registration
code.

## Always use the latest versions

Target the latest stable .NET SDK/runtime, and keep every NuGet package (and any other
tooling — EF Core, analyzers, SDKs, project file schema) on its latest stable version.
When scaffolding a new project or touching an existing one, check for and apply available
upgrades rather than leaving versions stale — don't pin to an older version without a
concrete reason.

## Applying this

When scaffolding a new .NET project, reviewing one, or advising on where new code should
live, default to this layout and these patterns unless told otherwise.
