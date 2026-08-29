# Controller pattern

Controllers resolve a handler via `[FromServices]` per action and do little more than call
`.Handle(...)`. No business logic in controllers — that all lives in the handler.

Always inject handlers as an action-method parameter with `[FromServices]`, never through
the controller's constructor. Constructor injection would give every action on the
controller access to every handler, even the ones it doesn't use — `[FromServices]` scopes
each handler to only the one action that actually calls it.

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
