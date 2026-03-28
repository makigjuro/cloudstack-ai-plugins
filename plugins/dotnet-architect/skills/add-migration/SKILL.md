---
name: add-migration
description: Create an EF Core migration for a specific microservice. Use after adding or modifying entities, DbSets, or entity configurations -- migration creation is mandatory for any schema change.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: true
---

# Add EF Core Migration

Create a new EF Core migration for a microservice's database context.

## Arguments

- `{Name}` -- Migration name in PascalCase (e.g., `AddOrdersTable`)
- `{Service}` -- Target microservice (ask if ambiguous)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `SERVICES` = `backend.services[]` (default: discover from `src/*/` directories containing `.Application/` subfolders)
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln` in `src/`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Service DbContext Discovery

If a service-to-DbContext mapping is not defined in `cloudstack.json`, auto-detect by searching for `*DbContext.cs` files:

```bash
grep -rn "class.*DbContext" src/{Service}/**/Infrastructure/ --include="*.cs"
```

Find the Infrastructure and Host projects:
```bash
find src/{Service} -name "*.Infrastructure.csproj" -o -name "*.Host.csproj"
```

## Process

### Step 1: Verify Changes

Before creating a migration, check that entity configurations are in place:

```bash
# Find the entity configuration
grep -rn "IEntityTypeConfiguration" src/{Service}/
```

### Step 2: Create Migration

Run from the Infrastructure project directory:

```bash
dotnet ef migrations add {Name} \
  --project src/{Service}/{Service}.Infrastructure \
  --startup-project src/{Service}/{Service}.Host \
  --output-dir Persistence/Migrations
```

If the startup project differs from the convention, search for the `.Host` project:
```bash
find src/{Service} -name "*.Host.csproj" -o -name "*.Host" -type d
```

### Step 3: Review Migration

Read the generated migration file and verify:
- Only expected changes are included
- No data loss operations (dropping columns/tables) without user confirmation
- Index names follow conventions
- Foreign keys are correct

```bash
# Find the latest migration
ls -t src/{Service}/**/Migrations/*.cs | head -2
```

### Step 4: Apply Migration (Optional)

Only apply if the user explicitly asks:

```bash
dotnet ef database update \
  --project src/{Service}/{Service}.Infrastructure \
  --startup-project src/{Service}/{Service}.Host
```

## After Creating

- Report the migration file path
- Show a summary of schema changes (tables created/altered, columns added/removed)
- Warn about any potentially destructive changes

## Error Handling

- **EF Core tools not installed:** Run `dotnet tool install --global dotnet-ef` and retry.
- **No pending model changes:** The migration will be empty -- warn the user and skip creation.
- **Startup project can't build:** Run `dotnet build` on the Host project first to surface errors.
- **Migration includes unexpected changes:** Warn about potential schema drift. Suggest verifying entity configurations match the intended changes.

## Related Skills

- `/add-entity` to create the entity and EF Core configuration first
- `/run-tests` to verify tests still pass after migration
