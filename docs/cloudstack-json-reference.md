# cloudstack.json Reference

The `cloudstack.json` file is placed at your project root to configure how plugins discover services, paths, and conventions. All fields are optional — plugins auto-detect from your project structure when fields are missing.

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
| `dotnetVersion` | string | `9.0` | Target .NET version |
| `solutionPath` | string | auto-detect `*.sln` | Path to .sln file |
| `sharedDomainPath` | string | auto-detect | Path to shared Domain project |
| `sharedInfraPath` | string | auto-detect | Path to shared Infrastructure project |
| `services` | array | auto-detect | Microservice definitions (see below) |
| `orm` | `efcore` | `efcore` | ORM framework |
| `readQueryTool` | `dapper` \| `efcore` | `dapper` | Read-side query tool |
| `messaging` | `wolverinefx` \| `mediatr` \| `none` | `wolverinefx` | CQRS framework |
| `messageBroker` | `nats` \| `rabbitmq` \| `none` | `none` | Message broker |
| `resultPattern` | boolean | `true` | Whether handlers use Result\<T\> |
| `multiTenancy` | boolean | `false` | Whether entities include TenantId |

#### Service definition

```json
{
  "name": "OrderService",
  "path": "src/OrderService",
  "projectPrefix": "MyApp.OrderService",
  "dbContext": "OrderServiceDbContext",
  "schema": "order_service"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Service name in PascalCase |
| `path` | yes | Path to service root directory |
| `projectPrefix` | yes | C# project name prefix |
| `dbContext` | no | EF Core DbContext class name |
| `schema` | no | Database schema name |

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
| `router` | `react-router-v6` \| `react-router-v7` \| `tanstack-router` | `react-router-v6` | Router |
| `bundler` | `vite` \| `webpack` \| `next` | `vite` | Build tool |
| `devPort` | integer | `5173` | Dev server port |

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

### `conventions`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `branchFormat` | string | `{username}/{issue}-{slug}` | Branch naming pattern |
| `commitStyle` | `lowercase-imperative` \| `conventional-commits` | `lowercase-imperative` | Commit message style |
| `errorCodeStyle` | `SCREAMING_SNAKE_CASE` \| `PascalCase` \| `kebab-case` | `SCREAMING_SNAKE_CASE` | Error code format |

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
