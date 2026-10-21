---
name: csharp-conventions
description: General C# conventions for the hexagonal .NET services — record commands/queries, Result-based error handling, async, multi-tenancy, DI registration, and naming. Apply whenever writing or editing C# code under src/.
user-invocable: false
paths:
  - "src/**/*.cs"
---

# C# General Rules

## Commands & Queries
- Define as `record` types (immutable): `public record CreateOrderCommand(Guid TenantId, string Name);`
- Handlers return `Result<T>` or `Result`, never throw exceptions for business logic
- Handler signature: `public async Task<Result<TResponse>> Handle(TCommand command, CancellationToken cancellationToken)`

## Error Handling
- Use `Result<T>` from the shared infrastructure layer
- Error codes in SCREAMING_SNAKE_CASE: `"ORDER_ALREADY_EXISTS"`, `"CUSTOMER_NOT_FOUND"`
- Use typed `ErrorType` enum: Validation, NotFound, Conflict, Unauthorized, Forbidden, Failure, Unexpected
- Never throw exceptions for expected business failures

## Async
- All I/O is async with `CancellationToken` propagated
- Suffix async methods with `Async`: `GetByIdAsync()`, `AddAsync()`
- Always await or return tasks, never fire-and-forget without explicit intent

## Multi-tenancy
- `TenantId` is a first-class value object, present on commands and entities
- Filter queries by tenant where applicable

## DI Registration
- Services registered as scoped: `services.AddScoped<IService, Service>()`

## Naming
- `_camelCase` for private fields
- Folders match namespace segments
