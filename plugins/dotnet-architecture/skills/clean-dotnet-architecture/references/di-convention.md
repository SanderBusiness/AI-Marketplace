# DI convention

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
