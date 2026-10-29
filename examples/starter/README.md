# cloudstack starter

A small, complete app built on the [cloudstack reference architecture](../../docs/architecture.md). It's what the plugins scaffold into, and it shows the shape of a real project:
- one hexagonal .NET service (Orders)
- an API gateway
- a React frontend
- Terraform/Terragrunt for Azure Container Apps

Copy it to start a new project, or read it to see what each skill produces.

## What's inside

```
src/
  Shared/Starter.Domain                Entities, value objects, domain events, repository interfaces (no dependencies)
  Shared/Starter.Shared.Infrastructure Result → HTTP, authentication, messaging helpers
  Starter.ServiceDefaults              /health/live, /health/ready, OpenTelemetry (on when OTEL_EXPORTER_OTLP_ENDPOINT is set)
  Starter.ApiGateway                   YARP gateway, the only public entry point
  Orders/                              Application (CQRS + WolverineFx + FluentValidation), Infrastructure (EF Core + PostgreSQL), Host (Minimal API)
tests/
  Starter.Domain.Tests                 Unit tests (xUnit, NSubstitute, FluentAssertions)
  Starter.Orders.Tests.Integration     WebApplicationFactory + Testcontainers PostgreSQL
web/                                   React 19 + TypeScript, TanStack Query, Zustand, shadcn/ui (Azure Static Web Apps)
infra/
  terraform/modules/                   11 modules: networking, identity, Key Vault, ACR, PostgreSQL, Container Apps env/app/job, Static Web App, …
  terragrunt/{dev,staging,prod}/       One unit per module and per app
cloudstack.json                        Tells the plugins where everything is
```

The Orders API runs behind the gateway, and every endpoint requires a JWT:
- `POST /api/orders` creates an order and returns 201 with the new ID.
- `GET /api/orders/{id}` returns one order.
- `GET /api/orders?pageNumber=1&pageSize=20` returns a page of orders.

Orders are scoped to the caller's tenant, taken from the token's `tid` claim.

## Run it locally

Needs Docker, the .NET 10 SDK and Node.

```bash
cp .env.example .env
docker compose up --build        # postgres → orders-migrate (runs once) → orders → gateway on http://localhost:5080
cd web && npm install && npm run dev   # http://localhost:5173, proxies /api to the gateway
```

Locally, the services use a development auth bypass, so every request is a fixed dev user. It only works when `ASPNETCORE_ENVIRONMENT=Development` and `Auth:DevBypass=true`, and the service refuses to start if the bypass is set in any other environment.

## Test it

```bash
dotnet test src/Starter.sln --filter "Category!=Integration"   # unit
dotnet test src/Starter.sln --filter "Category=Integration"    # integration (Docker)
cd web && npm run type-check && npm run lint && npm test -- --run && npm run build
```

## Deploy it to Azure Container Apps

See [infra/README.md](infra/README.md) for bootstrap, OIDC and the full plan/apply order. In short:

```bash
infra/scripts/bootstrap-state.sh dev                     # once per environment: Terraform state storage
cd infra/terragrunt/dev
IMAGE_TAG=$(git rev-parse --short HEAD) terragrunt run --all plan
```

Each deploy follows the same rules:
- Images are tagged with the commit SHA. `latest` is rejected.
- The `orders-migrate` job runs the Orders image with `--migrate` before the new revision takes traffic.
- Apps pull from ACR and read Key Vault secrets with a managed identity, so no credentials are stored.
- Only the gateway is public.

A one-command `/cloud-infra:deploy` and a CI scaffold are on the [roadmap](https://github.com/makigjuro/cloudstack-ai-plugins/issues/4).

## Use it with the plugins

From this directory, with the plugins installed:

```
/dotnet-architect:check-architecture
/dotnet-architect:add-entity Customer Orders
/react-developer:add-feature customers
/dev-workflow:complete-task
```

## Notes

- **Port 5080:** the gateway uses 5080 because macOS AirPlay Receiver takes port 5000.
- **FluentAssertions 7.2.2:** pinned to the last Apache-licensed release. 8.x needs a commercial license.
- **OpenTelemetry:** no collector endpoint is set in `infra/terragrunt/*/env.hcl` yet. Set `otel_exporter_otlp_endpoint` to send telemetry.
- **Database login:** the Orders connection string uses the PostgreSQL admin login. A dedicated app role or Entra ID auth is the next hardening step.
