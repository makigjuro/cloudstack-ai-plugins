# cloudstack-ai-plugins

Claude Code plugin marketplace for full-stack cloud engineering. Install any combination of plugins to get an AI-powered engineering toolkit for .NET + React + Azure projects.

## Plugins

| Plugin | Skills | Agents | Rules | What It Does |
|--------|--------|--------|-------|-------------|
| [dotnet-architect](plugins/dotnet-architect/) | 6 | 1 | 7 | Hexagonal architecture scaffolding, CQRS, domain entities, migrations, code review |
| [react-developer](plugins/react-developer/) | 4 | 0 | 2 | React feature modules, Playwright screenshots, smoke testing |
| [cloud-infra](plugins/cloud-infra/) | 6 | 1 | 1 | Terraform modules, Helm charts, infra linting, infrastructure review |
| [dev-workflow](plugins/dev-workflow/) | 13 | 4 | 4 | PRD to PR workflow, quality gates, parallel code review, git conventions |

Install all four for the complete "cloud engineer" experience, or pick individual plugins for your stack.

## Quick Start

### 1. Add the marketplace

```
/plugin marketplace add makigjuro/cloudstack-ai-plugins
```

### 2. Install plugins

```
/plugin install dotnet-architect@cloudstack-ai-plugins
/plugin install react-developer@cloudstack-ai-plugins
/plugin install cloud-infra@cloudstack-ai-plugins
/plugin install dev-workflow@cloudstack-ai-plugins
```

### 3. Configure your project (optional)

Create a `cloudstack.json` at your project root to customize paths, namespaces, and conventions. Without it, plugins auto-detect from your project structure.

```json
{
  "$schema": "https://raw.githubusercontent.com/makigjuro/cloudstack-ai-plugins/main/schema/cloudstack.schema.json",
  "project": {
    "name": "MyProject",
    "namespace": "MyProject"
  },
  "backend": {
    "solutionPath": "src/MyProject.sln",
    "services": [
      { "name": "OrderService", "path": "src/OrderService", "projectPrefix": "MyProject.OrderService" }
    ]
  },
  "frontend": {
    "path": "web",
    "devPort": 5173
  },
  "infrastructure": {
    "chartsPath": "deploy/charts",
    "terraformPath": "infra/terraform/modules"
  }
}
```

See [cloudstack.json reference](docs/cloudstack-json-reference.md) for all available fields.

### 4. Use the skills

```
/dotnet-architect:add-entity Device OrderService
/dotnet-architect:add-command CreateOrder OrderService
/react-developer:add-feature orders
/cloud-infra:add-helm-chart order-service
/dev-workflow:complete-task
```

## How It Works

### Convention over configuration

Plugins read `cloudstack.json` for project-specific values (namespaces, service names, paths). If the file doesn't exist, they auto-detect from your project structure:

- **Solution path**: Finds `*.sln` in `src/`
- **Services**: Discovers directories with `.Application/` subfolders
- **Frontend path**: Defaults to `web/`
- **Helm charts**: Defaults to `deploy/charts/`
- **Terraform modules**: Defaults to `infra/terraform/modules/`

### Plugin independence

Each plugin works standalone. `dev-workflow` adapts based on which other plugins are installed:

- **With dotnet-architect**: `complete-task` runs .NET build, lint, architecture checks
- **With react-developer**: `complete-task` runs frontend type-check, lint, browser verification
- **With cloud-infra**: `complete-task` runs Helm lint, Terraform validate
- **Without any**: `complete-task` still handles git workflow, PR creation, and code review

### MCP server compatibility

Skills are designed to work with or without MCP servers:

- **context7** (recommended): Library documentation lookup for EF Core, TanStack Query, etc.
- **playwright** (recommended for react-developer): Browser automation for screenshots and verification
- **github-mcp-server** (optional): Structured GitHub operations (falls back to `gh` CLI)

## Supported Stack

**Current (v0.1):**
- Backend: .NET 9, C#, hexagonal architecture, EF Core, WolverineFx
- Frontend: React 18+, TypeScript, TanStack Query, Zustand, shadcn/ui
- Infrastructure: Terraform, Helm, Azure/AKS, GitHub Actions
- Local dev: .NET Aspire or Docker Compose

**Planned:**
- Additional frontend frameworks (Vue, Angular)
- Additional cloud providers (AWS, GCP)
- Additional backend frameworks (Go, Node.js)

## Project Structure

```
cloudstack-ai-plugins/
├── .claude-plugin/marketplace.json    # Marketplace manifest
├── schema/cloudstack.schema.json      # JSON Schema for cloudstack.json
├── plugins/
│   ├── dotnet-architect/              # .NET hexagonal architecture
│   ├── react-developer/              # React frontend
│   ├── cloud-infra/                  # Terraform + Helm
│   └── dev-workflow/                 # Workflow orchestration
├── templates/
│   └── cloudstack.json               # Starter config
└── docs/                             # Documentation
```

## Contributing

Contributions welcome! See [plugin development guide](docs/plugin-development.md).

## License

MIT
