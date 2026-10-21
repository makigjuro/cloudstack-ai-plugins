# dotnet-architect

**The backend layer of the [cloudstack reference architecture](../../README.md).** It scaffolds .NET microservices with hexagonal architecture and keeps them that way.

```
/plugin install dotnet-architect@cloudstack-ai-plugins
```

## The architecture it enforces

- **Layers:** Domain → Application → Infrastructure → Host. Domain depends on nothing.
- **DDD:** aggregate roots with private constructors and factory methods, typed value-object IDs, domain events. Repository interfaces live in Domain.
- **CQRS with WolverineFx:** commands go through FluentValidation and return a minimal response. Queries handle reads.
- **`Result<T>`** for business outcomes instead of exceptions, with entity-specific error codes.
- **Persistence:** EF Core + PostgreSQL. Every model change ships with its migration.
- **Endpoints:** Minimal APIs with OpenAPI metadata and authentication by default.

The diagrams are in [docs/architecture.md](../../docs/architecture.md).

## Skills

| Skill | What it creates |
|---|---|
| `/dotnet-architect:add-entity Order OrderService` | Entity, typed ID, domain event, repository interfaces, EF configuration, migration |
| `/dotnet-architect:add-command CreateOrder OrderService` | Command, handler, validator, POST/PUT/DELETE endpoint |
| `/dotnet-architect:add-query GetOrder OrderService` | Query, handler, GET endpoint |
| `/dotnet-architect:add-event-handler OrderCreated OrderService` | WolverineFx handler for domain or integration events |
| `/dotnet-architect:add-migration AddOrderStatus OrderService` | EF Core migration |
| `/dotnet-architect:generate-tests CreateOrderHandler OrderService` | xUnit unit tests and Testcontainers integration tests |
| `/dotnet-architect:check-architecture` | Quick check for layer violations, Result usage, CQRS conventions and pending migrations |

**Agent:** `dotnet-architect:reviewer` is the deep PR review for security, architecture and quality. It runs in `/dev-workflow:complete-task`.

## Convention skills

Claude applies these automatically when it edits matching files:

| Skill | Applies to |
|---|---|
| `csharp-conventions`, `backend-security` | `src/**/*.cs` |
| `domain-layer-rules` | `src/**/Domain/**/*.cs` |
| `infrastructure-layer-rules` | `src/**/Infrastructure/**/*.cs` |
| `endpoint-conventions` | `src/**/Endpoints/**/*.cs` |
| `validator-conventions` | `src/**/*Validator*.cs` |
| `dotnet-testing-conventions` | `tests/**/*.cs` |

## Configuration

```json
{
  "project": { "namespace": "MyCompany.MyProject" },
  "backend": {
    "solutionPath": "src/MyProject.sln",
    "services": [{ "name": "OrderService", "path": "src/OrderService" }]
  }
}
```

Without `cloudstack.json`, the skills detect the namespace from the solution, find Domain and Infrastructure projects, and discover services under `src/`. See the [cloudstack.json reference](../../docs/cloudstack-json-reference.md).

**Prerequisites:**
- .NET SDK (the reference stack targets .NET 10)
- `dotnet-ef` (`dotnet tool install --global dotnet-ef`)
- Docker, for Testcontainers integration tests
