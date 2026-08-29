# Handler pattern

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

See `di-convention.md` for how `[Handler]` gets a class auto-registered, and
`controller-pattern.md` for how controllers consume handlers.
