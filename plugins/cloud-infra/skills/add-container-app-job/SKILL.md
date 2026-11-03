---
name: add-container-app-job
description: Add an Azure Container Apps Job unit (database migrations, one-off setup tasks, scheduled batch work) on the shared container-app-job module, using the same image and Key Vault secrets as its service, and register migration jobs in cloudstack.json. Use when a service needs EF Core migrations run before rollout, a manual task container, or a cron job on Container Apps.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
user-invocable: true
argument-hint: "{name} --service {service} [--args \"--migrate\"] [--schedule \"<cron>\"]"
---

# Add Container App Job

Create a Container Apps Job that runs a service's image with different arguments. The main case is the migration job that `/cloud-infra:deploy` runs, and waits on, before any new app revision takes traffic. The rules live in the container-apps-conventions skill.

## Arguments

- `{name}`: Terragrunt unit name, e.g. `orders-migrate`, `catalog-seed`.
- `--service {service}` (required): the `backend.services` entry whose image, secrets and env the job reuses.
- `--args "..."`: container args, e.g. `"--migrate"`. Empty keeps the image CMD.
- `--schedule "<cron>"`: run on a schedule (e.g. `"0 3 * * *"`, UTC). By default the job is manually triggered. Migration jobs are never scheduled, because they have to run in deploy order.

A job is a **migration job** when `--args` contains `--migrate` or `{name}` ends in `-migrate`.

## Configuration

Read `cloudstack.json`:
- `RUNTIME` = `infrastructure.runtime` (default `container-apps`). If it is `aks`, stop and suggest a Kubernetes Job in the service's Helm chart (`/cloud-infra:add-helm-chart`).
- `TG_PATH` = `infrastructure.terragruntPath`, `TF_PATH` = `infrastructure.terraformPath`
- `UNITS_PATH` = `infrastructure.containerApps.appUnitsPath` (default `infra/terragrunt/{env}`)
- `ENVS` = `infrastructure.containerApps.environments` (default `["dev","staging","prod"]`)
- `MIGRATION_JOBS` = `infrastructure.containerApps.migrationJobs` (default `{}`)

Read `project` and `location_short` from `{TG_PATH}/root.hcl`.

## Process

### 1. Check

- The service's app unit must exist (`{TG_PATH}/_envcommon/{service-unit}.hcl`). If it doesn't, suggest `/cloud-infra:add-container-app {service}` first, since the job takes its image repository and secrets from there.
- `{name}` must not exist yet, and for a migration job `MIGRATION_JOBS` must not already map this service to another unit.
- **Job name length.** The module names the job `{project}-job-{job_name}-{env}-{location_short}`, with a 32-character maximum, and `job_name` matches `^[a-z][a-z0-9-]{0,10}[a-z0-9]$`. Use a short `job_name` that differs from the unit name when needed. The starter's `orders-migrate` unit uses `job_name = "orders"` (`starter-job-orders-staging-weu`). Check the length against the longest env.
- Migration jobs: the service host has to exit after migrating when given `--migrate`. Look for the `MigrateArgument` handling in the service's `Program.cs`, using `src/Orders/Starter.Orders.Host/Program.cs` as the reference. Without it the job starts the web server and runs until `replica_timeout_in_seconds`, so stop and say so.

### 2. `_envcommon/{name}.hcl`

Copy `_envcommon/orders-migrate.hcl` (or another job unit) block for block:
- Header comment saying what the job does and its Azure name.
- `locals` (`env`, `modules_dir`, `otel_env`) and `terraform.source = "${local.modules_dir}/container-app-job"`.
- The same dependencies as the service's app unit (`resource_group`, `managed_identity`, `container_registry`, `container_app_environment`, and `postgresql` when the service has one), with `mock_outputs` copied verbatim.

Inputs:
```hcl
inputs = {
  job_name                     = "{job_name}"
  resource_group_name          = dependency.resource_group.outputs.name
  container_app_environment_id = dependency.container_app_environment.outputs.id
  managed_identity_id          = dependency.managed_identity.outputs.id
  registry_server              = dependency.container_registry.outputs.login_server
  image_repository             = "<same image_repository as the service unit>"
  args                         = ["--migrate"]   # from --args

  # Same Key Vault references and secret env vars as the service unit.
  key_vault_secrets = { ... }
  secret_env_vars   = { ... }
  env_vars = merge({
    ASPNETCORE_ENVIRONMENT = local.env.aspnetcore_environment
    OTEL_SERVICE_NAME      = "{name}"
    AZURE_CLIENT_ID        = dependency.managed_identity.outputs.client_id
  }, local.otel_env)
}
```
`image_tag` comes from `root.hcl` (`IMAGE_TAG`), so the job always runs the same SHA as the app. Long data migrations can raise `replica_timeout_in_seconds` (default 600). Keep `replica_retry_limit` at 1 or lower for migrations.

### 3. Schedule (only with `--schedule`)

The starter's `container-app-job` module only supports `manual_trigger_config`. If `{TF_PATH}/container-app-job/variables.tf` has no `schedule_cron_expression`, extend the module in a backwards-compatible way. Ask the user first, since it touches a shared module:
```hcl
# variables.tf
variable "schedule_cron_expression" {
  description = "Cron expression (UTC) for a scheduled job; null keeps the job manually triggered"
  type        = string
  default     = null
}

# main.tf: replace the static manual_trigger_config block (exactly one trigger block is allowed)
dynamic "manual_trigger_config" {
  for_each = var.schedule_cron_expression == null ? [1] : []
  content {
    parallelism              = 1
    replica_completion_count = 1
  }
}
dynamic "schedule_trigger_config" {
  for_each = var.schedule_cron_expression == null ? [] : [1]
  content {
    cron_expression          = var.schedule_cron_expression
    parallelism              = 1
    replica_completion_count = 1
  }
}
```
Then set `schedule_cron_expression = "<cron>"` in the unit's inputs. Check the change with `terraform -chdir={TF_PATH}/container-app-job init -backend=false && terraform -chdir={TF_PATH}/container-app-job validate`. Existing manual jobs must plan with no changes.

### 4. Per-environment units

For each env in `ENVS`, create `{UNITS_PATH}/{env}/{name}/terragrunt.hcl` with the two includes (`root` → `find_in_parent_folders("root.hcl")`, `envcommon` → `_envcommon/{name}.hcl`), using the header comment style of the existing units.

### 5. Register migration jobs

For a migration job, add `"{Service}": "{name}"` to `infrastructure.containerApps.migrationJobs` in `cloudstack.json`, creating the `containerApps` object if needed. Keep the file's formatting and existing keys. `/cloud-infra:deploy` and the CI rollout read this map to know which job to run, and wait on, before the service's app unit is applied.

### 6. Format and validate offline

```bash
cd {TG_PATH} && terragrunt hcl format
cd {UNITS_PATH with env=dev} && TG_OFFLINE=true IMAGE_TAG=abc1234 terragrunt run --all validate --provider-cache
```

## Output

```
## Container Apps Job: {name}

| Env | Unit | Azure name | Trigger |
|-----|------|------------|---------|
| dev | {UNITS_PATH}/dev/{name} | {project}-job-{job_name}-dev-{loc} | manual / cron "<expr>" |
...
Image: same as {service} (<acr>/{image_repository}:${IMAGE_TAG}), args: [...]
Secrets: <secret env vars> (Key Vault refs)
cloudstack.json: containerApps.migrationJobs.{Service} = "{name}" | not a migration job
Validation: hcl format ok, dev validate ok

Run manually: az containerapp job start -g <rg> -n {project}-job-{job_name}-<env>-{loc}
```

## Safety

- Never put secret values in inputs. Reuse the service's Key Vault references.
- Don't run `plan`, `apply` or `az containerapp job start` here. `/cloud-infra:deploy` runs migration jobs in order.
- Only modify the shared module when `--schedule` needs it and the user agrees.

## Related Skills

- `/cloud-infra:add-container-app`: the app unit the job shares an image with
- `/dotnet-architect:add-migration`: create the EF Core migration the job applies
- `/cloud-infra:deploy`: applies the job unit, runs it, waits for `Succeeded`, then rolls the apps
