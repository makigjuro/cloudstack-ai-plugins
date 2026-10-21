# cloudstack.json Reference

`cloudstack.json` maps the reference architecture onto your project. It lives at the project root and tells the plugins where your services, frontend and infrastructure are and which conventions you follow. Generate it with `/dev-workflow:init`. All fields are optional — plugins auto-detect from your project structure when fields are missing.

## Schema

Add the `$schema` field for IDE autocompletion:

```json
{
  "$schema": "https://raw.githubusercontent.com/makigjuro/cloudstack-ai-plugins/main/schema/cloudstack.schema.json"
}
```

## Fields

### `project`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | *required* | Project display name |
| `namespace` | string | *required* | Root C# namespace prefix |
| `description` | string | — | One-line project description |

### `repository`

Auto-detected from `git remote -v` if omitted.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `owner` | string | auto-detect | GitHub org or username |
| `name` | string | auto-detect | Repository name |
| `defaultBranch` | string | `main` | Default branch name |

### `backend`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `framework` | `dotnet` | `dotnet` | Backend framework |
| `dotnetVersion` | string | `10.0` | Target .NET version |
| `solutionPath` | string | auto-detect `*.sln` | Path to .sln file |
| `sharedDomainPath` | string | auto-detect | Path to shared Domain project |
| `sharedInfraPath` | string | auto-detect | Path to shared Infrastructure project |
| `services` | array | auto-detect | Microservice definitions (see below) |
| `orm` | `efcore` | `efcore` | ORM framework |
| `readQueryTool` | `dapper` \| `efcore` | `dapper` | Read-side query tool |
| `messaging` | `wolverinefx` \| `mediatr` \| `none` | `wolverinefx` | CQRS framework |
| `messageBroker` | `nats` \| `rabbitmq` \| `none` | `none` | Message broker |
| `messagingConventions.publisherInterface` | string | `IMessagePublisher` | Publisher abstraction injected in event handlers |
| `messagingConventions.subjectPrefix` | string | — | Root of the message subject hierarchy (skills grep it to map event topology) |
| `resultPattern` | boolean | `true` | Whether handlers use Result\<T\> |
| `multiTenancy` | boolean | `false` | Whether entities include TenantId |
| `devPort` | integer | — | Backend API port during local development |
| `sharedPaths` | string[] | — | Shared code paths; a change here makes `/run-tests` run the full suite |

#### Service definition

```json
{
  "name": "OrderService",
  "path": "src/OrderService",
  "projectPrefix": "MyApp.OrderService",
  "dbContext": "OrderServiceDbContext",
  "schema": "order_service",
  "aliases": ["os", "orders"],
  "labels": ["order-service"],
  "testProjects": {
    "unit": ["tests/MyApp.OrderService.Tests"],
    "integration": ["tests/MyApp.OrderService.Tests.Integration"]
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Service name in PascalCase |
| `path` | yes | Path to service root directory |
| `projectPrefix` | yes | C# project name prefix |
| `dbContext` | no | EF Core DbContext class name |
| `schema` | no | Database schema name |
| `aliases` | no | Short names accepted by skills (`/run-tests os`) |
| `labels` | no | GitHub issue labels for tasks touching this service |
| `testProjects` | no | Explicit unit/integration test project paths when they don't follow the `{projectPrefix}.Tests.*` convention; an explicitly empty array means the service has no tests of that kind |

### `frontend`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `framework` | `react` \| `vue` \| `none` | `react` | Frontend framework |
| `path` | string | `web` | Path to frontend project |
| `language` | `typescript` \| `javascript` | `typescript` | Language |
| `stateManagement.server` | `tanstack-query` \| `swr` \| `none` | `tanstack-query` | Server state library |
| `stateManagement.client` | `zustand` \| `redux` \| `none` | `zustand` | Client state library |
| `uiLibrary` | `shadcn` \| `mui` \| `antd` \| `none` | `shadcn` | UI component library |
| `styling` | `tailwind` \| `css-modules` \| `styled-components` | `tailwind` | Styling approach |
| `router` | `react-router-v7` \| `tanstack-router` \| `react-router-v6` | `react-router-v7` | Router |
| `bundler` | `vite` \| `webpack` \| `next` | `vite` | Build tool |
| `devPort` | integer | `5173` | Dev server port |
| `defaultRoute` | string | `/` | Route opened when none is specified |
| `routerFile` | string | auto-detect | Route definitions file, if detection misfires |
| `smokeRoutes` | string[] | — | Known-critical routes for `/smoke-test`, supplements auto-detection |

### `infrastructure`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cloud` | `azure` \| `aws` \| `gcp` | `azure` | Cloud provider |
| `iac` | `terraform` \| `pulumi` \| `none` | `terraform` | IaC tool |
| `iacWrapper` | `terragrunt` \| `none` | `none` | IaC wrapper |
| `terraformPath` | string | `infra/terraform/modules` | Terraform modules path |
| `terragruntPath` | string | — | Terragrunt config path |
| `kubernetes` | `aks` \| `eks` \| `gke` \| `none` | `none` | Kubernetes flavor |
| `charts` | `helm` \| `kustomize` \| `none` | `helm` | Chart tool |
| `chartsPath` | string | `deploy/charts` | Helm charts path |
| `containerRegistry` | string | — | Container registry URL |
| `namespace` | string | — | Kubernetes namespace |
| `cicd` | `github-actions` \| `azure-devops` \| `gitlab-ci` | `github-actions` | CI/CD platform |

### `localDev`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `orchestrator` | `aspire` \| `docker-compose` \| `none` | `docker-compose` | Local orchestration |
| `appHostPath` | string | — | .NET Aspire AppHost project path |
| `composePath` | string | — | docker-compose.yml path |
| `dashboardPort` | integer | — | Aspire dashboard port |
| `apiPort` | integer | `5000` | Backend API port |
| `ports` | object | — | Named ports for local infra dependencies, e.g. `{ "nats": 4222, "valkey": 6379 }` |
| `authConfig.storageKey` | string | — | localStorage key of the persisted auth store |
| `authConfig.state` | object | — | State object injected for localStorage-based auth |
| `authConfig.formFields` | object | — | Login form field values for UI-flow auth, e.g. `{ "apiKey": "dev-api-key-1" }` |

### `conventions`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `branchFormat` | string | `{username}/{issue}-{slug}` | Branch naming pattern |
| `commitStyle` | `lowercase-imperative` \| `conventional-commits` | `lowercase-imperative` | Commit message style |
| `errorCodeStyle` | `SCREAMING_SNAKE_CASE` \| `PascalCase` \| `kebab-case` | `SCREAMING_SNAKE_CASE` | Error code format |
| `terraformNaming` | string | — | IaC resource naming pattern, e.g. `{project}-{resource}-{env}-{location_short}` |
| `projectPrefix` | string | — | Short project prefix used in resource names |
| `locationShort` | object | — | Region → short-code map, e.g. `{ "westeurope": "weu" }` |

### `validators`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `mcpServer` | string | — | Name of a project MCP server exposing batch architecture-validation tools (`detect_changes`, `validate_all_layers`, `check_all_migrations`, `check_result_pattern`). When set, `/check-architecture`, `/code-review`, and `/complete-task` call `mcp__{server}__{tool}` and fall back to shell checks when absent. |

## Minimal Example

For a simple single-service project:

```json
{
  "project": { "name": "MyApp", "namespace": "MyApp" },
  "backend": { "solutionPath": "src/MyApp.sln" }
}
```

## Full Example

See [templates/cloudstack.json](../templates/cloudstack.json) for a complete example.
