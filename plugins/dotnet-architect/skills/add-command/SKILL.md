---
name: add-command
description: Scaffold a new CQRS command with handler, validator, and POST endpoint following project conventions. Use whenever the user wants to add a write operation, mutation, POST/PUT/DELETE endpoint, or any state-changing action to a microservice.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__plugin_dotnet-architect_context7__resolve-library-id, mcp__plugin_dotnet-architect_context7__query-docs
user-invocable: true
argument-hint: "{CommandName} [Service]"
---

# Add CQRS Command

When the user asks to add a new command, scaffold the following files in the correct microservice. Ask which service if ambiguous.

If the command involves non-trivial FluentValidation rules (async validators, cross-field validation, collection rules) or WolverineFx middleware, use context7 to look up the current docs before writing.

## Arguments

- `{Name}` -- Command name in PascalCase (e.g., `CreateOrder`, `AssignRole`)
- `{Service}` -- Target microservice. Ask if ambiguous.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `NAMESPACE` = `project.namespace` (default: detect from `*.sln` name or first `*.csproj` root namespace)
- `SERVICES` = `backend.services[]` (default: discover from `src/*/` directories containing `.Application/` subfolders)
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln` in `src/`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Prerequisites

- The target microservice must exist under `src/`
- An Endpoints file should exist at `Host/Endpoints/` (if not, create one)
- If the command operates on an entity that doesn't exist yet, run `/add-entity` first

## 1. Command Record (`Application/Commands/{CommandName}.cs`)

```csharp
namespace {Namespace}.{Service}.Application.Commands;

public record {Name}Command({parameters});
```

## 2. Response Record (same file or `Application/Contracts/`)

```csharp
public record {Name}Response({response fields});
```

## 3. Handler (`Application/Commands/{Name}Handler.cs`)

```csharp
namespace {Namespace}.{Service}.Application.Commands;

public class {Name}Handler
{
    // Constructor-inject repositories, services and IValidator<{Name}Command>

    public async Task<Result<{Name}Response>> Handle({Name}Command command, CancellationToken cancellationToken)
    {
        // 1. Validate input: run the FluentValidation validator and return
        //    Result.Failure<{Name}Response>(validation.ToValidationError()) if invalid
        // 2. Check business rules (e.g. uniqueness -> Error.Conflict)
        // 3. Create/modify domain entities via factory methods or aggregate methods
        //    (domain guards throw ArgumentException only for programmer errors -- input is already validated)
        // 4. Persist via repository
        // 5. Return Result.Success or Result.Failure with SCREAMING_SNAKE error code
    }
}
```

`Result`/`Error` live in the shared infrastructure project (`{Namespace}.Shared.Infrastructure.Results`), not in Domain -- Domain has zero dependencies.
```

## 4. Validator (`Application/Validators/{Name}Validator.cs`)

```csharp
namespace {Namespace}.{Service}.Application.Validators;

public class {Name}Validator : AbstractValidator<{Name}Command>
{
    public {Name}Validator()
    {
        // RuleFor(x => x.Field).NotEmpty().WithErrorCode("ERROR_CODE");
    }
}
```

## 5. Endpoint (add to existing `Host/Endpoints/{Domain}Endpoints.cs`)

```csharp
group.MapPost("/{route}", {Name})
    .WithName("{Name}")
    .WithSummary("...")
    .WithDescription("...")
    .Produces<{Name}Response>(StatusCodes.Status201Created)
    .ProducesProblem(StatusCodes.Status400BadRequest)
    .ProducesProblem(StatusCodes.Status409Conflict);

private static async Task<IResult> {Name}(
    [FromBody] {Name}Request request,
    [FromServices] {Name}Handler handler,
    ClaimsPrincipal user,
    CancellationToken cancellationToken)
{
    // TenantId comes from the token claim, never from the request body
    var command = new {Name}Command(user.GetTenantId(), ...);
    var result = await handler.Handle(command, cancellationToken);
    return result.ToHttpResult(created => $"/api/{route}/{created.Id}"); // 201 + Location
}
```

For non-creating commands (PUT/DELETE) use `result.ToHttpResult()` (200, or 204 for a non-generic `Result`). Do not add `.WithOpenApi()` -- it is deprecated in .NET 10.

If the shared `ResultExtensions` lacks the Created overload, add it next to the existing `ToHttpResult` methods:
```csharp
// using HttpResults = Microsoft.AspNetCore.Http.Results; (avoids clashing with the .Results namespace)
/// <summary>201 Created with a Location header built from the created value.</summary>
public static IResult ToHttpResult<T>(this Result<T> result, Func<T, string> createdLocation)
{
    ArgumentNullException.ThrowIfNull(createdLocation);
    return result.IsSuccess
        ? HttpResults.Created(createdLocation(result.Value), result.Value)
        : result.Error.ToProblem();
}
```

## 6. DI Registration

Register the handler in the service's `AddInfrastructure` or `Program.cs`:
```csharp
services.AddScoped<{Name}Handler>();
```

## Checklist
- [ ] Command record is immutable
- [ ] Handler returns `Result<T>`, no thrown exceptions for business logic
- [ ] Error codes are SCREAMING_SNAKE_CASE
- [ ] Validator uses FluentValidation
- [ ] Endpoint has OpenAPI metadata (WithName, WithSummary, WithDescription, Produces) -- no `.WithOpenApi()`
- [ ] Creating POST returns 201 with Location via `ToHttpResult(locationFn)`
- [ ] Handler registered in DI
- [ ] CancellationToken propagated through all async calls

## Output

After scaffolding, report:
```
## Scaffolded: {Name}Command

Files created/modified:
- `src/{Service}/{Service}.Application/Commands/{Name}Command.cs`
- `src/{Service}/{Service}.Application/Commands/{Name}Handler.cs`
- `src/{Service}/{Service}.Application/Validators/{Name}Validator.cs`
- `src/{Service}/{Service}.Host/Endpoints/{Domain}Endpoints.cs` (modified)
- `src/{Service}/{Service}.Host/Program.cs` or DI registration (modified)

Next: Run `/run-tests` to verify, or `/add-query` if you also need a read endpoint.
```

## Error Handling

- **Endpoints file doesn't exist:** Create a new `{Domain}Endpoints.cs` with the route group boilerplate.
- **DI registration file not found:** Add `services.AddScoped<{Name}Handler>()` directly to `Program.cs`.
- **Namespace conflicts:** Check existing commands in the folder before creating -- prompt the user if a similar command already exists.

## Related Skills

- `/add-entity` if the command creates a new entity type
- `/add-event-handler` to react to domain events raised by this command
- `/add-query` if you also need a read endpoint for the same resource
