---
name: add-event-handler
description: Scaffold a WolverineFx event handler for domain events or integration events. Use whenever the user wants to react to domain events, publish messages, send notifications, update read models, or add async side effects.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__context7__resolve-library-id, mcp__context7__query-docs
user-invocable: true
argument-hint: "{EventName} [Service]"
---

# Add Event Handler

When the user asks to add an event handler, scaffold a WolverineFx handler for a domain or integration event.

## Arguments

- `{EventName}` -- Name of the event to handle (e.g., `OrderCreatedEvent`)
- `{Service}` -- Target microservice (ask if ambiguous)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `NAMESPACE` = `project.namespace` (default: detect from `*.sln` name or first `*.csproj` root namespace)
- `DOMAIN_PATH` = `backend.sharedDomainPath` (default: find directory matching `**/Domain/` containing `Entities/`)
- `SERVICES` = `backend.services[]` (default: discover from `src/*/` directories containing `.Application/` subfolders)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## 1. Find the Event

Search for the event class:
```bash
grep -rn "class {EventName}" src/
```

If the event doesn't exist, suggest running `/add-entity` first or create it inline.

## 2. Event Handler (`Application/Events/{EventName}Handler.cs`)

```csharp
namespace {Namespace}.{Service}.Application.Events;

public class {EventName}Handler
{
    // Constructor-inject repositories, services, or ILogger<T>

    public async Task Handle({EventName} @event, CancellationToken cancellationToken)
    {
        // React to the event:
        // - Update read models
        // - Send notifications
        // - Publish integration events
        // - Trigger side effects
    }
}
```

For handlers that publish to a message broker:

```csharp
public class {EventName}Handler
{
    private readonly IMessagePublisher _messagePublisher;
    private readonly ILogger<{EventName}Handler> _logger;

    public {EventName}Handler(IMessagePublisher messagePublisher, ILogger<{EventName}Handler> logger)
    {
        _messagePublisher = messagePublisher;
        _logger = logger;
    }

    public async Task Handle({EventName} @event, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling {Event} for {Id}", nameof({EventName}), @event.Id);

        await _messagePublisher.PublishAsync(
            "{domain}.events.{event-type}",
            @event,
            cancellationToken);
    }
}
```

## 3. Integration Event (if cross-service)

If the handler needs to publish an event for other services:

```csharp
namespace {Namespace}.{Service}.Application.Events;

public record {Name}IntegrationEvent(
    Guid Id,
    // relevant fields
    DateTimeOffset OccurredAt);
```

## Checklist

- [ ] Handler class in `Application/Events/` folder
- [ ] Event parameter named `@event` (reserved keyword escaping)
- [ ] CancellationToken propagated
- [ ] Logging at appropriate level
- [ ] No return value (event handlers are fire-and-forget)
- [ ] Idempotent handling (events may be delivered more than once)
- [ ] No exceptions thrown for business logic (log and continue)

## Guidelines

- WolverineFx discovers handlers by convention -- no explicit registration needed
- One handler per event per concern (don't mix read model updates with notifications)
- Use `ILogger` for observability, not `Console.WriteLine`
- For message broker subjects/topics, follow the project's naming conventions

## Output

After scaffolding, report:
```
## Scaffolded: {EventName}Handler

Files created:
- `src/{Service}/{Service}.Application/Events/{EventName}Handler.cs`
{if integration event:}
- `src/{Service}/{Service}.Application/Events/{Name}IntegrationEvent.cs`

Next: Run `/run-tests` to verify handler registration.
```

## Error Handling

- **Event class not found:** Suggest running `/add-entity` first to create the entity and its domain events.
- **Message publisher interface missing:** Check if `IMessagePublisher` is registered in the service's DI. If not, it may need to be added to the Infrastructure layer.

## Related Skills

- `/add-entity` to create the domain entity and events first
- `/add-command` if the handler needs to trigger a command
