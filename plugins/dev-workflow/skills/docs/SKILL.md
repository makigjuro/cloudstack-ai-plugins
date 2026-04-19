---
name: docs
description: Generate or update project documentation from code -- API docs, service docs, architecture docs, or runbooks. Use after adding endpoints, entities, events, or infrastructure changes, or when documentation may be stale.
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, mcp__claude_ai_Mermaid_Chart__validate_and_render_mermaid_diagram
user-invocable: true
argument-hint: "[service|api|architecture|domain|runbook|all]"
---

# Generate / Update Documentation

Generate or update markdown documentation by analyzing the actual codebase. Never fabricate -- every statement must be backed by code you've read.

## Arguments

- `{target}` -- What to document. One of:
  - `service {name}` -- Full service documentation (endpoints, events, config)
  - `api {service}` -- API endpoint reference for a service
  - `architecture` -- Update the technical architecture doc
  - `domain` -- Update the domain model doc
  - `runbook {service}` -- Operational runbook (health checks, alerts, troubleshooting)
  - `quickstart` -- Update the quickstart / getting started guide
  - `all` -- Regenerate all outdated docs

If no argument given, detect what's changed since last docs update and suggest what needs refreshing.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `NAMESPACE` = `project.namespace`
- `SOLUTION` = `backend.solutionPath`
- `SERVICES` = `backend.services[]`
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TERRAFORM_PATH` = `infrastructure.terraformPath`

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Detect Scope

If no target specified:
```bash
# Find docs that may be stale -- compare last doc commit vs last code commit
git log -1 --format=%H -- docs/
git log -1 --format=%H -- src/ ${FRONTEND_PATH} ${CHARTS_PATH} ${TERRAFORM_PATH}

# Show what code changed since docs were last updated
git diff {last-docs-commit}..HEAD --stat -- src/ ${FRONTEND_PATH} ${CHARTS_PATH} ${TERRAFORM_PATH}
```

Present the user with a summary of what's changed and recommend which docs to update.

### Step 2: Gather Evidence

Read the actual code -- do NOT guess or use stale memory. For each doc type:

**Service doc (`docs/services/{service-name}/README.md`):**
1. Read `src/{Service}/{Service}.Host/Program.cs` -- DI, middleware, config sections
2. Read `src/{Service}/{Service}.Host/Endpoints/` -- all endpoint files
3. Read `src/{Service}/{Service}.Application/Commands/` -- all command records
4. Read `src/{Service}/{Service}.Application/Queries/` -- all query records
5. Read `src/{Service}/{Service}.Infrastructure/DependencyInjection.cs` -- external dependencies
6. Read `src/{Service}/{Service}.Infrastructure/Persistence/Configurations/` -- DB schema
7. Grep for messaging subjects/topics in the service
8. Read Helm chart values if present: `${CHARTS_PATH}/{service-name}/values.yaml`
9. Read `appsettings.json` in the Host project -- configuration keys

**API doc (`docs/services/{service-name}/api.md`):**
1. Read all endpoint files in `src/{Service}/{Service}.Host/Endpoints/`
2. Read corresponding command/query records for request/response shapes
3. Read validators for constraints
4. Extract: method, route, request body, response body, status codes, auth requirements

**Architecture doc (`docs/architecture/technical-architecture.md`):**
1. Read all `Program.cs` files for service topology
2. Read app host / orchestrator config for service discovery and dependencies
3. Read `${TERRAFORM_PATH}/` for infrastructure components
4. Read `${CHARTS_PATH}/` for deployment topology
5. Grep for inter-service communication patterns (HTTP clients, messaging subjects)

**Domain model doc (`docs/architecture/domain-model.md`):**
1. Read all entities in the shared domain layer
2. Read all value objects in the shared domain layer
3. Read all domain events in the shared domain layer
4. Read EF Core configurations for relationships and constraints

**Runbook (`docs/services/{service-name}/runbook.md`):**
1. Read `Program.cs` for health check endpoints
2. Read `${CHARTS_PATH}/{service-name}/values.yaml` for resource limits, probes, env vars
3. Read `${CHARTS_PATH}/{service-name}/templates/` for alerts, HPA config
4. Grep for error codes and error handling patterns
5. Read integration test factory for dependencies (DB, messaging, cache, storage)

**Quickstart (`docs/quickstart.md`):**
1. Read app host / orchestrator config for local dev setup
2. Read `docker-compose*.yml` if present
3. Read `${FRONTEND_PATH}/package.json` for frontend setup
4. Read `Directory.Build.props` for SDK requirements
5. Verify all commands by checking they reference real files/scripts

### Step 3: Generate Documentation

Write the documentation to the appropriate path. Follow these rules:

**Structure:**
- Use the existing file if updating -- preserve sections the user may have manually edited
- Add a metadata comment at the top: `<!-- Generated from code by /docs on {date}. Do not edit generated sections. -->`
- Mark auto-generated sections with `<!-- BEGIN GENERATED -->` / `<!-- END GENERATED -->` markers
- Leave non-generated sections untouched when updating

**Content rules:**
- Every endpoint, entity, event, and config key must come from actual code you read
- Include code references: `See: src/{Service}/.../FileName.cs`
- Use tables for structured data (endpoints, config keys, events)
- Include Mermaid diagrams for architecture and entity relationships where helpful
- Keep descriptions concise -- one sentence per item unless complexity warrants more

### Step 4: Verify

After generating:
1. Check all file paths referenced in the doc actually exist
2. Check all endpoint routes match what's in the code
3. Check all config keys match what's in appsettings / values.yaml
4. Validate any Mermaid diagrams using `mcp__claude_ai_Mermaid_Chart__validate_and_render_mermaid_diagram` -- fix syntax errors before writing
5. Report what was generated/updated and word count

## Output Formats

### Service Doc Template

```markdown
<!-- Generated from code by /docs on {date}. Do not edit generated sections. -->
# {Service Name}

{One-paragraph description of what this service does.}

## API Endpoints

<!-- BEGIN GENERATED -->
| Method | Route | Description | Auth |
|--------|-------|-------------|------|
| POST | `/api/{resource}` | Create a new resource | API Key |
| GET | `/api/{resource}/{id}` | Get resource by ID | API Key |
<!-- END GENERATED -->

## Commands & Queries

<!-- BEGIN GENERATED -->
### Commands
| Command | Description | Handler |
|---------|-------------|---------|
| `CreateResourceCommand` | Creates a new resource | `CreateResourceHandler` |

### Queries
| Query | Description | Handler |
|-------|-------------|---------|
| `GetResourceByIdQuery` | Retrieves resource by ID | `GetResourceByIdHandler` |
<!-- END GENERATED -->

## Domain Events Published

<!-- BEGIN GENERATED -->
| Event | Trigger | Key Data |
|-------|---------|----------|
| `ResourceCreatedEvent` | Resource.Create() | ResourceId, TenantId |
<!-- END GENERATED -->

## Messaging Subjects

<!-- BEGIN GENERATED -->
| Subject | Type | Direction | Description |
|---------|------|-----------|-------------|
| `{project}.{resource}.events.<type>` | Persistent | Outbound | Resource events |
<!-- END GENERATED -->

## Configuration

<!-- BEGIN GENERATED -->
| Key | Description | Default | Required |
|-----|-------------|---------|----------|
| `ConnectionStrings:{name}` | Database connection | -- | Yes |
<!-- END GENERATED -->

## Dependencies

<!-- BEGIN GENERATED -->
- **PostgreSQL** -- State persistence
- **Messaging** -- Event publishing
<!-- END GENERATED -->
```

### API Doc Template

```markdown
<!-- Generated from code by /docs on {date}. Do not edit generated sections. -->
# {Service Name} API Reference

Base URL: `/api/{resource}`

<!-- BEGIN GENERATED -->
## POST /api/{resource}

Create a new resource.

**Request Body:**
\`\`\`json
{
  "name": "string",
  "metadata": "string | null"
}
\`\`\`

**Response (201):**
\`\`\`json
{
  "id": "guid",
  "name": "string",
  "createdAt": "datetime"
}
\`\`\`

**Error Codes:**
| Code | Status | Description |
|------|--------|-------------|
| `RESOURCE_ALREADY_EXISTS` | 409 | Resource with this ID already exists |
| `NAME_REQUIRED` | 400 | Name is missing or empty |

**Validation Rules:**
- `name` -- Required, max 200 characters
<!-- END GENERATED -->
```

### Runbook Template

```markdown
<!-- Generated from code by /docs on {date}. Do not edit generated sections. -->
# {Service Name} Runbook

## Health Checks

| Endpoint | Type | Description |
|----------|------|-------------|
| `/health/live` | Liveness | Process is running |
| `/health/ready` | Readiness | Dependencies accessible |

## Dependencies

| Dependency | Failure Impact | Recovery |
|------------|---------------|----------|
| PostgreSQL | Full outage | Readiness probe fails, pod restarts |
| Messaging | Event publishing stops | Circuit breaker, retries |

## Resource Limits

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 500m |
| Memory | 256Mi | 512Mi |

## Common Issues

### {Error Code}
- **Symptom:** {what the user sees}
- **Cause:** {root cause}
- **Resolution:** {steps to fix}

## Alerts

| Alert | Severity | Condition | Runbook Action |
|-------|----------|-----------|----------------|
```

## Guidelines

- Accuracy over completeness -- skip a section rather than guess
- Update, don't replace -- preserve manually-written content outside generated markers
- Reference code -- every fact should be traceable to a source file
- Keep it scannable -- tables, headers, and short paragraphs over walls of text
- Date everything -- the metadata comment helps track staleness
