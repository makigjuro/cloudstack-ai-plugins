---
name: container-apps-conventions
description: Azure Container Apps conventions — image tags, one unit per app, ingress, managed identity, Key Vault secrets, probes, scaling, migration jobs, and naming. Apply whenever creating or editing container-app / container-app-job Terraform modules or the Terragrunt units that deploy apps (infrastructure.runtime "container-apps").
user-invocable: false
paths:
  - "**/container-app*/**/*.tf"
  - "**/terragrunt/**/terragrunt.hcl"
  - "**/terragrunt/**/*.hcl"
---

# Container Apps Rules

Applies when `infrastructure.runtime` is `container-apps` (the default). For AKS, see the helm-chart-conventions skill.

## Images
- The image tag is a required variable/input (the git SHA), never `latest` — a new tag is what rolls a new revision, and `latest` makes deploys unreproducible and rollbacks impossible.
- Pull from the registry with the user-assigned identity (`registry { identity = ... }`) holding `AcrPull` — no registry username/password, so no credential to rotate or leak.

## Layout
- One app per Terragrunt unit under `{containerApps.appUnitsPath}` (e.g. `infra/terragrunt/{env}/orders/`), all sourcing the shared `container-app` module — per-app modules drift; per-app units keep plans and blast radius small.
- Shared config goes in `_envcommon/{app}.hcl`; the env unit only overrides inputs.

## Ingress and Identity
- Internal ingress (`ingress_external = false`) for every app except `{containerApps.gatewayApp}` — services are reached through the gateway, not the internet.
- `identity { type = "UserAssigned" }` with the shared managed identity — one identity carries AcrPull and Key Vault access and survives app re-creation.

## Secrets
- Secrets are Key Vault references (`secret { key_vault_secret_id, identity }`) surfaced via `secret_name` env vars — secret values never enter Terraform state, tfvars, or plain `env` blocks.
- Plain `env_vars` carry only non-secret config (`ASPNETCORE_ENVIRONMENT`, `OTEL_SERVICE_NAME`, `AZURE_CLIENT_ID`).

## Health and Scaling
- Liveness probe on `/health/live` and readiness on `/health/ready`, both on `target_port` — readiness gates traffic to a new revision; liveness restarts a hung replica.
- `min_replicas >= 1` in staging/prod; scale-to-zero (`min_replicas = 0`) only in dev — cold starts on prod requests are user-visible.
- Set `max_replicas >= min_replicas` and an HTTP concurrency scale rule.
- `revision_mode = "Single"` unless you are deliberately traffic-splitting — Multiple leaves old revisions taking traffic.

## Migrations
- Database migrations run as a Container Apps Job unit (`{containerApps.migrationJobs}`, e.g. `orders-migrate`) on the `container-app-job` module, executed and awaited before the app rolls out — the new revision must never start against an old schema, and app replicas should not race to migrate.

## Observability
- When the env defines `otel_exporter_otlp_endpoint`, set `OTEL_EXPORTER_OTLP_ENDPOINT` (and `OTEL_SERVICE_NAME`) on the app; omit the variable when the endpoint is empty — an empty endpoint makes the exporter log errors.

## Naming
- `{project}-{resource}-{env}-{location_short}` (e.g. `starter-ca-orders-prod-weu`), with a module `precondition` enforcing ACA's 32-character limit — names longer than 32 fail at apply time, not plan time.

## Related Skills
- `/cloud-infra:add-container-app`, `/cloud-infra:add-container-app-job` — scaffold units that follow these rules
- `/cloud-infra:infra-lint` — validates the Terragrunt tree
- `/cloud-infra:add-terraform-module` — scaffold the shared modules these units source
