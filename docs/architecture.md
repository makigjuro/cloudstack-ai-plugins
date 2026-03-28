# Reference Architecture

This document describes the software and cloud architecture that the cloudstack-ai-plugins encode. Every skill, rule, and agent in this marketplace is built to scaffold, enforce, and review these patterns.

## Overview

The reference architecture is a cloud-native microservices platform built on .NET, React, and Azure. It uses hexagonal architecture for backend services, CQRS for command/query separation, and event-driven communication between services.

```mermaid
graph TB
    subgraph clients["Clients"]
        spa["React SPA"]
        mobile["Mobile App"]
        external_api["External API Consumers"]
    end

    subgraph gateway["API Gateway / Ingress"]
        ingress["Kubernetes Ingress<br/>TLS Termination + Routing"]
    end

    subgraph services["Microservices"]
        svc_a["Service A<br/>.NET 10"]
        svc_b["Service B<br/>.NET 10"]
        svc_c["Service C<br/>.NET 10"]
    end

    subgraph messaging["Async Messaging"]
        broker["Message Broker<br/>NATS JetStream / RabbitMQ"]
    end

    subgraph persistence["Data Stores"]
        pg[("PostgreSQL")]
        redis[("Redis / Valkey")]
        blob[("Blob Storage")]
    end

    subgraph observability["Observability Stack"]
        otel["OpenTelemetry"]
        grafana["Grafana + Loki + Tempo"]
    end

    clients --> gateway
    gateway --> services
    services <--> messaging
    services --> persistence
    services --> otel
    otel --> grafana

    style clients fill:#6B7280,color:#fff
    style gateway fill:#F59E0B,color:#000
    style services fill:#3B82F6,color:#fff
    style messaging fill:#7C3AED,color:#fff
    style persistence fill:#059669,color:#fff
    style observability fill:#0E7490,color:#fff
```

## Hexagonal Architecture

Every microservice follows hexagonal (ports & adapters) architecture. This pattern isolates business logic from infrastructure concerns, making services testable, maintainable, and adaptable.

### Project Structure

Each service consists of four projects:

```
ServiceName/
├── ServiceName.Domain/           # Pure business logic, zero dependencies
├── ServiceName.Application/      # Use cases (commands, queries, events)
├── ServiceName.Infrastructure/   # External integrations (DB, APIs, cache)
└── ServiceName.Host/             # HTTP endpoints, DI wiring, startup
```

Plus shared projects used by all services:

```
Shared/
├── {Namespace}.Domain/                    # Shared entities, value objects, events
└── {Namespace}.Shared.Infrastructure/     # Result types, auth, resilience
```

### Layer Responsibilities

```mermaid
graph LR
    subgraph host["Host Layer"]
        endpoints["Endpoints/<br/>Minimal API route groups"]
        middleware["Middleware/<br/>Auth, error handling, logging"]
        program["Program.cs<br/>DI container, pipeline config"]
    end

    subgraph app["Application Layer"]
        commands["Commands/<br/>State-changing operations"]
        queries["Queries/<br/>Read-only data retrieval"]
        validators["Validators/<br/>Input validation rules"]
        events["Event Handlers/<br/>Async side effects"]
        contracts["Contracts/<br/>Request/response DTOs"]
    end

    subgraph domain["Domain Layer"]
        entities["Entities/<br/>Business objects with behavior"]
        valueobjects["Value Objects/<br/>Typed IDs, immutable values"]
        domainevents["Domain Events/<br/>State change notifications"]
        abstractions["Abstractions/<br/>Repository interfaces"]
    end

    subgraph infrastructure["Infrastructure Layer"]
        repos["Persistence/<br/>EF Core + Dapper"]
        dbconfig["Entity Configurations/<br/>Table mappings"]
        external_svc["External Services/<br/>HTTP clients, storage"]
        di["DependencyInjection.cs<br/>Service registration"]
    end

    endpoints --> commands
    endpoints --> queries
    commands --> validators
    commands --> entities
    commands --> abstractions
    queries --> abstractions
    events --> entities

    abstractions -.->|implemented by| repos
    repos --> dbconfig

    style domain fill:#10B981,color:#fff,stroke:#059669
    style app fill:#3B82F6,color:#fff,stroke:#2563EB
    style infrastructure fill:#8B5CF6,color:#fff,stroke:#7C3AED
    style host fill:#F59E0B,color:#000,stroke:#D97706
```

### Layer Dependency Rules

These rules are enforced by the `check-architecture` skill and the `reviewer` agent:

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

| Rule | Why |
|------|-----|
| Domain has zero dependencies | Business logic never changes because of a database or framework switch |
| Application cannot reference Host | Use cases must be invokable from any entry point (HTTP, CLI, message handler) |
| Infrastructure implements Domain interfaces | Dependency inversion -- domain defines the contract, infra fulfills it |
| Host cannot reference Domain directly | All access goes through Application layer handlers |

## CQRS Pattern

Commands (writes) and queries (reads) follow separate paths. This enables independent optimization -- writes use EF Core with change tracking, reads use Dapper for raw performance.

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

### Key Design Decisions

**Result pattern over exceptions.** Handlers return `Result<T>` for business logic outcomes. Exceptions are reserved for truly exceptional situations (network failures, bugs). This makes error handling explicit and testable.

```csharp
// Command handler returns Result<T>
public async Task<Result<OrderId>> Handle(CreateOrderCommand command) {
    var customer = await _repo.GetById(command.CustomerId);
    if (customer is null)
        return Result<OrderId>.Failure(Errors.Customer.NotFound);

    var order = Order.Create(customer.Id, command.Items);
    await _repo.Add(order);
    return Result<OrderId>.Success(order.Id);
}
```

**Typed IDs.** Every entity uses a value object ID instead of raw `Guid`. This prevents accidentally passing an `OrderId` where a `CustomerId` is expected.

```csharp
public class OrderId : ValueObject {
    public Guid Value { get; init; }
    public static OrderId New() => new(Guid.NewGuid());
}
```

**Domain events.** State changes publish events that other handlers can react to asynchronously. This decouples services and enables event-driven workflows.

## Frontend Architecture

The React frontend follows a feature-based module structure. Each feature is self-contained with its own pages, components, and API integration.

```
web/src/
├── api/
│   ├── client.ts              # Axios singleton with auth interceptors
│   ├── types/                 # Shared API types
│   └── services/              # Per-domain API clients
│       ├── orders.api.ts
│       └── customers.api.ts
├── features/
│   ├── orders/
│   │   ├── pages/             # Route-level components
│   │   └── components/        # Feature-specific components
│   └── customers/
│       ├── pages/
│       └── components/
├── hooks/api/                 # TanStack Query hooks
├── stores/                    # Zustand client state
└── routes/                    # React Router configuration
```

**State management split:**
- **Server state** (TanStack Query): API data with automatic caching, refetching, and invalidation
- **Client state** (Zustand): UI preferences, auth tokens, ephemeral state

## Cloud Infrastructure

The infrastructure layer uses Terraform for provisioning and Helm for workload deployment, with a clear separation between the two concerns.

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

### Terraform Module Structure

Each cloud resource gets its own module. Modules are composed via Terragrunt dependency graphs.

```
infra/terraform/modules/
├── resource-group/         # Azure resource group
├── aks-cluster/           # AKS with node pools
├── postgresql/            # Flexible Server
├── redis/                 # Cache for Redis
├── storage-account/       # Blob storage
├── key-vault/             # Secrets management
└── container-registry/    # GHCR or ACR
```

**Conventions:**
- One resource per module, named `"this"`
- Naming: `{project}-{resource}-{env}-{location_short}`
- All resources tagged with `project`, `environment`, `managed-by`
- Terragrunt handles backend config and dependency ordering

### Helm Chart Structure

Each microservice gets its own Helm chart with standard templates.

```
deploy/charts/
├── service-a/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── hpa.yaml
│       └── _helpers.tpl
└── service-b/
    └── ...
```

**Conventions:**
- Standard Kubernetes labels on all resources
- Health checks: `/health/live` (liveness), `/health/ready` (readiness)
- Resource limits always defined
- Environment variables from ConfigMaps and Secrets, never hardcoded
- HPA with sensible defaults (min 1, max 3 replicas)

## Development Workflow

The `dev-workflow` plugin encodes a complete SDLC from requirements to pull request.

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

The most sophisticated skill -- `complete-task` -- runs a multi-phase pipeline that dynamically adapts to what changed in your branch.

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

**Change detection flags:**

| Flag | Triggered by | Gates |
|------|-------------|-------|
| `HAS_BACKEND` | Files under `src/` | .NET build, lint, unit tests, migration check |
| `HAS_FRONTEND` | Files under `{frontend.path}/` | Type-check, ESLint, browser verification |
| `HAS_INFRA` | Files under `infra/`, `deploy/`, `.github/` | Helm lint, Terraform fmt, infra-reviewer agent |

**Agent composition:**

| Agent | When | Role |
|-------|------|------|
| `reviewer` | Always | OWASP security, architecture violations, code quality |
| `verifier` | Always | Acceptance criteria from linked GitHub issue |
| `doc-checker` | Endpoints, entities, or infra changed | Detect stale documentation |
| `infra-reviewer` | `HAS_INFRA` | Terraform/Helm-specific security and best practices |

All agents run in parallel with worktree isolation -- each gets its own copy of the repo so they don't interfere with each other.

## Quality Gates

The plugins enforce quality at multiple levels:

| Level | Tool | What It Checks |
|-------|------|---------------|
| **On save** | `format-on-save` hook | Auto-formats C#, TypeScript, Terraform files |
| **On commit** | `pre-commit-lint` hook | Staged file formatting, blocks unfixable errors |
| **On commit** | `scan-secrets` hook | AWS keys, Azure secrets, private keys, API tokens |
| **On demand** | `check-architecture` | Layer violations, Result pattern, pending migrations |
| **On demand** | `run-tests` | Smart change detection, runs only affected test projects |
| **Pre-PR** | `complete-task` | Full pipeline: build, lint, test, review, QA |
| **Pre-merge** | `reviewer` agent | Deep security + architecture + quality review |

## Technology Choices

| Concern | Choice | Why |
|---------|--------|-----|
| Backend framework | .NET 10 / C# 14 | Strong typing, performance, mature ecosystem |
| Architecture | Hexagonal | Testability, framework independence |
| CQRS framework | WolverineFx | Wolverine handlers are plain classes, minimal ceremony |
| ORM (writes) | EF Core | Change tracking, migrations, LINQ |
| ORM (reads) | Dapper | Raw SQL performance for read-optimized queries |
| Validation | FluentValidation | Expressive, testable validation rules |
| Mapping | Riok.Mapperly | Source-generated, zero runtime overhead |
| Error handling | Result\<T\> pattern | Explicit, no exception-driven control flow |
| Frontend | React + TypeScript | Type safety, component model, ecosystem |
| Server state | TanStack Query | Automatic caching, refetching, invalidation |
| Client state | Zustand | Minimal boilerplate, no reducers |
| UI components | shadcn/ui | Copy-paste ownership, Tailwind-native |
| IaC | Terraform + Terragrunt | Declarative, multi-cloud, DRY with Terragrunt |
| Orchestration | Helm | Kubernetes-native, templated deployments |
| CI/CD | GitHub Actions | Integrated with repo, marketplace of actions |
| Observability | OpenTelemetry | Vendor-neutral, auto-instrumented |
