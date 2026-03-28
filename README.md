# cloudstack-ai-plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Plugins](https://img.shields.io/badge/plugins-4-purple)](plugins/)
[![Skills](https://img.shields.io/badge/skills-29-green)](plugins/)
[![Agents](https://img.shields.io/badge/agents-6-orange)](plugins/)
[![.NET 10](https://img.shields.io/badge/.NET-10-512BD4)](https://dotnet.microsoft.com/)
[![React 19](https://img.shields.io/badge/React-19-61DAFB)](https://react.dev/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC)](https://www.terraform.io/)

> AI-powered full-stack cloud engineer for Claude Code. 29 skills, 6 agents, 14 rules across 4 plugins.

```
/plugin marketplace add makigjuro/cloudstack-ai-plugins
```

Claude Code plugin marketplace for full-stack cloud engineering. Install any combination of plugins to get an AI-powered engineering toolkit for .NET + React + Azure projects.

## Plugin Marketplace

```mermaid
graph TB
    subgraph marketplace["cloudstack-ai-plugins marketplace"]
        direction TB

        subgraph dotnet["dotnet-architect"]
            d1["add-entity"]
            d2["add-command"]
            d3["add-query"]
            d4["add-event-handler"]
            d5["add-migration"]
            d6["check-architecture"]
            d7(["reviewer agent"])
            d8[/"7 rules"/]
        end

        subgraph react["react-developer"]
            r1["add-feature"]
            r2["screenshot"]
            r3["verify-feature"]
            r4["smoke-test"]
            r5[/"2 rules"/]
        end

        subgraph infra["cloud-infra"]
            i1["add-terraform-module"]
            i2["add-helm-chart"]
            i3["infra-lint"]
            i4["infra-apply"]
            i5["infra-plan"]
            i6["complete-infra"]
            i7(["infra-reviewer agent"])
            i8[/"1 rule"/]
        end

        subgraph workflow["dev-workflow"]
            w1["prd"]
            w2["plan-feature"]
            w3["create-tasks"]
            w4["start-work"]
            w5["complete-task"]
            w6["create-pr"]
            w7["run-tests / lint / docs"]
            w8["code-review / diagnose"]
            w9(["4 agents"])
            w10[/"4 rules + 3 hooks"/]
        end
    end

    config["cloudstack.json"]
    project["Your Project"]

    config -->|configures| marketplace
    marketplace -->|scaffolds &amp; validates| project

    style dotnet fill:#4B0082,color:#fff
    style react fill:#0E7490,color:#fff
    style infra fill:#7C3AED,color:#fff
    style workflow fill:#1D4ED8,color:#fff
    style config fill:#F59E0B,color:#000
    style project fill:#10B981,color:#fff
```

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

## Reference Architecture

These plugins encode a battle-tested architecture for cloud-native .NET microservices. Below is a visual guide to the patterns enforced and scaffolded by the plugins.

### Hexagonal Architecture (per microservice)

Each microservice follows hexagonal (ports & adapters) architecture with strict layer dependency rules. The `dotnet-architect` plugin scaffolds and enforces this structure.

```mermaid
graph LR
    subgraph external["External World"]
        api["REST API<br/>Minimal API Endpoints"]
        mq["Message Broker<br/>NATS / RabbitMQ"]
        ui["Frontend<br/>React SPA"]
    end

    subgraph host["Host Layer"]
        endpoints["Endpoints/"]
        middleware["Middleware/"]
        program["Program.cs"]
    end

    subgraph app["Application Layer"]
        commands["Commands/<br/>Create, Update, Delete"]
        queries["Queries/<br/>GetById, List, Search"]
        validators["Validators/<br/>FluentValidation"]
        events["Event Handlers/<br/>WolverineFx"]
        contracts["Contracts/<br/>DTOs, Responses"]
    end

    subgraph domain["Domain Layer"]
        entities["Entities/<br/>Aggregate Roots"]
        valueobjects["Value Objects/<br/>Typed IDs"]
        domainevents["Domain Events/"]
        abstractions["Abstractions/<br/>Repository Interfaces"]
    end

    subgraph infrastructure["Infrastructure Layer"]
        repos["Persistence/<br/>EF Core Repositories"]
        dbcontext["DbContext<br/>+ Configurations"]
        external_svc["External Services/<br/>Blob Storage, APIs"]
        di["DependencyInjection.cs"]
    end

    subgraph data["Data Stores"]
        db[("PostgreSQL<br/>+ TimescaleDB")]
        cache[("Redis / Valkey")]
        blob[("Azure Blob<br/>Storage")]
    end

    ui --> api
    api --> endpoints
    mq --> events

    endpoints --> commands
    endpoints --> queries
    commands --> validators
    commands --> entities
    commands --> abstractions
    queries --> abstractions
    events --> entities

    entities --> valueobjects
    entities --> domainevents

    abstractions -.->|implemented by| repos
    repos --> dbcontext
    repos --> db
    external_svc --> cache
    external_svc --> blob

    style domain fill:#10B981,color:#fff,stroke:#059669
    style app fill:#3B82F6,color:#fff,stroke:#2563EB
    style infrastructure fill:#8B5CF6,color:#fff,stroke:#7C3AED
    style host fill:#F59E0B,color:#000,stroke:#D97706
    style external fill:#6B7280,color:#fff,stroke:#4B5563
    style data fill:#374151,color:#fff,stroke:#1F2937
```

**Layer dependency rules** (enforced by `check-architecture`):

```mermaid
graph BT
    domain["Domain Layer<br/><i>Entities, Value Objects, Events<br/>Repository Interfaces</i>"]
    app["Application Layer<br/><i>Commands, Queries, Validators<br/>Event Handlers, DTOs</i>"]
    infra["Infrastructure Layer<br/><i>EF Core Repos, External Services<br/>DI Registration</i>"]
    host["Host Layer<br/><i>Endpoints, Middleware<br/>Program.cs</i>"]

    host -->|depends on| app
    host -->|depends on| infra
    infra -->|depends on| domain
    infra -->|depends on| app
    app -->|depends on| domain

    host -.-x|FORBIDDEN| domain
    domain -.-x|ZERO dependencies| app
    app -.-x|FORBIDDEN| host
    domain -.-x|ZERO dependencies| infra

    style domain fill:#10B981,color:#fff
    style app fill:#3B82F6,color:#fff
    style infra fill:#8B5CF6,color:#fff
    style host fill:#F59E0B,color:#000
```

- **Domain** has zero dependencies on any other layer
- **Application** depends only on Domain (never Host or Infrastructure)
- **Infrastructure** implements Domain interfaces (repository pattern)
- **Host** wires everything together via DI and exposes endpoints

### CQRS Flow

Commands (writes) and queries (reads) follow separate paths through the architecture. The `add-command` and `add-query` skills scaffold these patterns.

```mermaid
sequenceDiagram
    participant Client
    participant Endpoint
    participant Validator
    participant Handler
    participant Repository
    participant DB as Database
    participant Events as Event Bus

    rect rgb(59, 130, 246, 0.1)
    Note over Client,Events: Command Flow (Write)
    Client->>Endpoint: POST /api/orders
    Endpoint->>Validator: Validate CreateOrderCommand
    Validator-->>Endpoint: ValidationResult
    Endpoint->>Handler: Handle(CreateOrderCommand)
    Handler->>Repository: Add(order)
    Repository->>DB: INSERT
    DB-->>Repository: OK
    Handler->>Events: Publish(OrderCreatedEvent)
    Handler-->>Endpoint: Result of OrderId
    Endpoint-->>Client: 201 Created
    end

    rect rgb(16, 185, 129, 0.1)
    Note over Client,Events: Query Flow (Read)
    Client->>Endpoint: GET /api/orders/123
    Endpoint->>Handler: Handle(GetOrderQuery)
    Handler->>Repository: GetById(id)
    Repository->>DB: SELECT (Dapper)
    DB-->>Repository: Row
    Repository-->>Handler: OrderDto
    Handler-->>Endpoint: Result of OrderDto
    Endpoint-->>Client: 200 OK
    end
```

**Key patterns:**
- Commands go through validation before reaching the handler
- Handlers return `Result<T>` instead of throwing exceptions
- Domain events are published after successful state changes
- Queries use Dapper for fast, optimized reads (separate from EF Core writes)

### Development Workflow

The `dev-workflow` plugin orchestrates the full software development lifecycle. Every step has a corresponding skill.

```mermaid
graph LR
    subgraph plan["Plan"]
        prd["prd"]
        planf["plan-feature"]
    end

    subgraph track["Track"]
        tasks["create-tasks"]
        start["start-work"]
    end

    subgraph build["Build"]
        entity["add-entity"]
        cmd["add-command"]
        query["add-query"]
        feat["add-feature"]
        helm["add-helm-chart"]
        tf["add-terraform-module"]
    end

    subgraph verify["Verify"]
        arch["check-architecture"]
        tests["run-tests"]
        lint["lint"]
        screenshot["verify-feature"]
    end

    subgraph complete["Complete"]
        ct["complete-task"]
        review["code-review"]
        qa["task-check"]
        pr["create-pr"]
    end

    prd --> tasks
    planf --> tasks
    tasks --> start
    start --> build
    build --> verify
    verify --> ct
    ct --> review
    ct --> qa
    review --> pr
    qa --> pr

    style plan fill:#7C3AED,color:#fff
    style track fill:#2563EB,color:#fff
    style build fill:#059669,color:#fff
    style verify fill:#D97706,color:#fff
    style complete fill:#DC2626,color:#fff
```

### Complete-Task Pipeline

The `complete-task` skill runs a multi-phase pipeline with parallel execution and dynamic agent composition. Phases are gated by change detection — if you only changed frontend code, backend checks are skipped.

```mermaid
graph TD
    start(["complete-task"])

    subgraph phase0["Phase 0: Pre-flight"]
        preflight["Branch check<br/>Clean tree<br/>Issue extraction"]
        detect["Change detection<br/>git diff --name-only"]
    end

    subgraph phase1["Phase 1: Parallel Build"]
        direction LR
        backend_build["dotnet build<br/>{SOLUTION}"]
        frontend_check["npm run type-check<br/>{FRONTEND_PATH}"]
    end

    subgraph phase2["Phase 2: Migrations"]
        migrations["EF Core pending<br/>migration check"]
    end

    subgraph phase3["Phase 3: Parallel Lint + Test"]
        direction LR
        backend_lint["dotnet format<br/>+ unit tests"]
        frontend_lint["ESLint<br/>+ prettier"]
        infra_lint["helm lint<br/>+ terraform fmt"]
    end

    subgraph phase4["Phase 4: Integration Tests"]
        integration["Docker-based<br/>integration tests"]
    end

    subgraph phase5["Phase 5: Browser Verify"]
        browser["Playwright<br/>screenshot + console check"]
    end

    subgraph phase6["Phase 6: Parallel Agent Review"]
        direction LR
        reviewer(["reviewer<br/>Security + Architecture"])
        verifier(["verifier<br/>Acceptance Criteria"])
        doc_checker(["doc-checker<br/>Stale Docs"])
        infra_reviewer(["infra-reviewer<br/>Terraform + Helm"])
    end

    subgraph phase7["Phase 7: Fix Loop"]
        fix["Fix issues<br/>Re-run affected tracks<br/>Max 3 iterations"]
    end

    subgraph phase8["Phase 8: Create PR"]
        pr["Push branch<br/>Create pull request"]
    end

    start --> phase0
    phase0 --> phase1
    phase1 --> phase2
    phase2 --> phase3
    phase3 --> phase4
    phase4 --> phase5
    phase5 --> phase6
    phase6 --> phase7
    phase7 --> phase8

    detect -.->|HAS_BACKEND| backend_build
    detect -.->|HAS_FRONTEND| frontend_check
    detect -.->|HAS_FRONTEND| browser
    detect -.->|HAS_INFRA| infra_lint
    detect -.->|HAS_INFRA| infra_reviewer

    style phase0 fill:#6B7280,color:#fff
    style phase1 fill:#2563EB,color:#fff
    style phase2 fill:#7C3AED,color:#fff
    style phase3 fill:#D97706,color:#fff
    style phase4 fill:#059669,color:#fff
    style phase5 fill:#0E7490,color:#fff
    style phase6 fill:#DC2626,color:#fff
    style phase7 fill:#92400E,color:#fff
    style phase8 fill:#10B981,color:#fff
```

### Cloud Infrastructure

The `cloud-infra` plugin targets this production architecture. Terraform modules provision the cloud resources, Helm charts deploy the workloads.

```mermaid
graph TB
    subgraph dev["Developer Workstation"]
        claude["Claude Code<br/>+ cloudstack plugins"]
        git["Git Push"]
    end

    subgraph cicd["GitHub Actions CI/CD"]
        build_ci["Build + Test"]
        docker["Container Build<br/>ghcr.io"]
        deploy_ci["Deploy Pipeline"]
    end

    subgraph iac["Infrastructure as Code"]
        tf["Terraform Modules<br/>infra/terraform/modules/"]
        tg["Terragrunt<br/>infra/terragrunt/{env}/"]
        helm["Helm Charts<br/>deploy/charts/"]
    end

    subgraph azure["Azure Cloud"]
        subgraph aks["AKS Cluster"]
            subgraph ns["Kubernetes Namespace"]
                svc1["Service A<br/>Deployment + Service"]
                svc2["Service B<br/>Deployment + Service"]
                svc3["Service C<br/>Deployment + Service"]
                ingress["Ingress Controller"]
            end
        end

        subgraph data["Managed Services"]
            pg[("PostgreSQL<br/>Flexible Server")]
            nats_svc["NATS<br/>JetStream"]
            redis_svc["Redis / Valkey<br/>Cache"]
            blob_svc["Blob Storage<br/>Artifacts"]
            kv["Key Vault<br/>Secrets"]
        end

        subgraph monitor["Observability"]
            otel["OpenTelemetry<br/>Collector"]
            grafana["Grafana<br/>Dashboards"]
            loki["Loki<br/>Logs"]
            tempo["Tempo<br/>Traces"]
            prom["Prometheus<br/>Metrics"]
        end
    end

    subgraph frontend["Frontend"]
        spa["React SPA<br/>Static Hosting / CDN"]
    end

    claude --> git
    git --> build_ci
    build_ci --> docker
    docker --> deploy_ci
    deploy_ci --> helm

    tf --> azure
    tg --> tf
    helm --> ns

    ingress --> svc1
    ingress --> svc2
    ingress --> svc3
    svc1 --> pg
    svc1 --> nats_svc
    svc2 --> redis_svc
    svc3 --> blob_svc
    aks --> kv

    svc1 --> otel
    svc2 --> otel
    svc3 --> otel
    otel --> prom
    otel --> loki
    otel --> tempo
    prom --> grafana
    loki --> grafana
    tempo --> grafana

    spa --> ingress

    style dev fill:#1D4ED8,color:#fff
    style cicd fill:#7C3AED,color:#fff
    style iac fill:#D97706,color:#fff
    style aks fill:#2563EB,color:#fff
    style ns fill:#3B82F6,color:#fff
    style data fill:#059669,color:#fff
    style monitor fill:#0E7490,color:#fff
    style frontend fill:#10B981,color:#fff
    style azure fill:#0078D4,color:#fff
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
- Backend: .NET 10, C# 14, hexagonal architecture, EF Core 10, WolverineFx
- Frontend: React 19, TypeScript, TanStack Query, Zustand, shadcn/ui
- Infrastructure: Terraform, Helm, Azure/AKS, GitHub Actions
- Local dev: .NET Aspire or Docker Compose

**Planned:**
- Additional frontend frameworks (Vue, Angular)
- Additional cloud providers (AWS, GCP)
- Additional backend frameworks (Go, Node.js)

## Repository Structure

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
└── docs/
    ├── getting-started.md             # Installation guide
    ├── architecture.md                # Reference architecture deep-dive
    ├── cloudstack-json-reference.md   # Configuration reference
    └── plugin-development.md          # Contributing guide
```

## Documentation

- [Getting Started](docs/getting-started.md) -- Installation and first steps
- [Reference Architecture](docs/architecture.md) -- Deep-dive into the patterns and conventions
- [cloudstack.json Reference](docs/cloudstack-json-reference.md) -- All configuration fields
- [Plugin Development](docs/plugin-development.md) -- How to contribute

## Contributing

Contributions welcome! See [plugin development guide](docs/plugin-development.md).

## License

MIT
