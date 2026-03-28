# dotnet-architect

A Claude Code plugin for .NET projects following hexagonal architecture with CQRS, DDD, and the Result pattern.

## What it provides

Scaffolding skills, architecture rules, and a code review agent for .NET microservice projects that use:

- Hexagonal architecture (Domain / Application / Infrastructure / Host layers)
- CQRS with WolverineFx
- Domain-Driven Design (entities, value objects, aggregate roots, domain events)
- Result pattern (no exceptions for business logic)
- EF Core + PostgreSQL
- FluentValidation
- Minimal API endpoints

## Skills

| Skill | Description |
|-------|-------------|
| `/add-entity` | Scaffold a domain entity with value object ID, aggregate root, factory method, domain event, repository interfaces, EF Core configuration, and migration |
| `/add-command` | Scaffold a CQRS command with handler, validator, and POST/PUT/DELETE endpoint |
| `/add-query` | Scaffold a CQRS query with handler and GET endpoint |
| `/add-event-handler` | Scaffold a WolverineFx event handler for domain or integration events |
| `/add-migration` | Create an EF Core migration for a microservice |
| `/check-architecture` | Verify hexagonal layer rules, Result pattern usage, CQRS conventions, and pending migrations |

## Rules

| Rule | Applies to | Description |
|------|-----------|-------------|
| `csharp-general` | `src/**/*.cs` | Commands, queries, error handling, async, DI, naming |
| `domain-layer` | `src/**/Domain/**/*.cs` | Zero dependencies, entities, aggregates, value objects, events |
| `endpoints` | `src/**/Endpoints/**/*.cs` | Minimal API structure, OpenAPI metadata, Result-to-HTTP |
| `validators` | `src/**/*Validator*.cs` | FluentValidation conventions |
| `infrastructure` | `src/**/Infrastructure/**/*.cs` | Repositories, EF Core, migrations, DI registration |
| `testing` | `tests/**/*.cs` | xUnit, NSubstitute, FluentAssertions, integration tests |
| `security-backend` | `src/**/*.cs` | Injection prevention, secrets, auth, JWT, input validation |

## Agents

| Agent | Model | Description |
|-------|-------|-------------|
| `reviewer` | Sonnet | Deep PR-level code review for security, architecture, and quality |

## Configuration

Skills auto-detect project structure by default. For explicit configuration, create a `cloudstack.json` in your project root:

```json
{
  "project": {
    "namespace": "MyCompany.MyProject"
  },
  "backend": {
    "solutionPath": "src/MyProject.sln",
    "sharedDomainPath": "src/Shared/MyProject.Domain",
    "sharedInfraPath": "src/Shared/MyProject.Infrastructure",
    "services": ["OrderService", "PaymentService", "NotificationService"]
  }
}
```

If `cloudstack.json` is absent, skills will:
- Detect the namespace from the `*.sln` filename or first `*.csproj` root namespace
- Find the Domain project by locating `**/Domain/` directories containing `Entities/`
- Find the Infrastructure project by locating `**/Shared.*Infrastructure/`
- Discover services from `src/*/` directories that contain `.Application/` subfolders
- Find the solution file by searching for `*.sln` in `src/`

## Installation

Add this plugin to your Claude Code project configuration. The skills, rules, and agents will be available automatically.

## Prerequisites

- .NET SDK (9.0+)
- EF Core tools (`dotnet tool install --global dotnet-ef`)
- PostgreSQL (for integration tests via Testcontainers)
