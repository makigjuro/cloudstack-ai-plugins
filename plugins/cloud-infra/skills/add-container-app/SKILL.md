---
name: add-container-app
description: Add a service to Azure Container Apps — creates its Terragrunt unit in every environment on the shared container-app module (internal ingress, managed identity, Key Vault secret refs, probes, SHA-tagged image), a Dockerfile if missing, a migration job when the service has a DbContext, and the gateway route. Use whenever the user wants to deploy, host, expose or wire up a new or existing microservice on Container Apps, or asks for "a container app for X".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
user-invocable: true
argument-hint: "{service} [--external] [--port 8080]"
---

# Add Container App

Give a backend service its own Container App in every environment, following the project's existing units exactly. The design rules live in the container-apps-conventions skill; this skill applies them to a new unit.

## Arguments

- `{service}` (required): a service from `backend.services` (match `name` or `aliases`, case-insensitive), e.g. `Inventory`. The unit and `app_name` are its lowercase alias, e.g. `inventory`.
- `--external`: public ingress. Only `containerApps.gatewayApp` should be external, so ask for confirmation and record why. Without it, ingress is internal (`https://<app>.internal.<env-domain>`).
- `--port {n}`: container port (default `8080`). It drives `target_port`, the probes and `ASPNETCORE_HTTP_PORTS` in the Dockerfile.

## Configuration

Read `cloudstack.json` from the project root:
- `RUNTIME` = `infrastructure.runtime` (default `container-apps`)
- `TG_PATH` = `infrastructure.terragruntPath` (default `infra/terragrunt`)
- `UNITS_PATH` = `infrastructure.containerApps.appUnitsPath` (default `infra/terragrunt/{env}`)
- `GATEWAY` = `infrastructure.containerApps.gatewayApp` (default `gateway`)
- `ENVS` = `infrastructure.containerApps.environments` (default `["dev","staging","prod"]`)
- The service entry from `backend.services`: `path`, `projectPrefix`, `dbContext`, `aliases`
- `localDev.orchestrator` / `localDev.composePath`

Read `project` and `location_short` from `{TG_PATH}/root.hcl` (`locals`), not from `project.name`: the root file is what names resources.

If `RUNTIME` is `aks`, stop: say this project deploys to Kubernetes and point to `/cloud-infra:add-helm-chart {service}`. If it is `none`, stop and ask whether the project should adopt Container Apps.

## Process

### 1. Check before writing

- `{TG_PATH}/_envcommon/{unit}.hcl` and `{UNITS_PATH}/{env}/{unit}/` must not exist. If they do, report and stop rather than overwrite.
- Name length: `{project}-ca-{unit}-{env}-{location_short}` must be at most 32 characters for the longest env (usually `staging`), and `app_name` must match `^[a-z][a-z0-9-]{0,14}[a-z0-9]$` (the module validates both, but only at plan time). Suggest a shorter alias if needed.
- Find the existing internal app unit to copy. In the starter that is `_envcommon/orders.hcl`; otherwise pick any non-gateway unit sourcing `container-app`.

### 2. `_envcommon/{unit}.hcl`

Copy the reference unit's structure block for block. Keep the header comment style, the `locals` (`env`, `modules_dir`, `otel_env`), `terraform.source = "${local.modules_dir}/container-app"`, and every `dependency` with its `mock_outputs` and `mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]` copied verbatim. The mocks must keep matching the modules' outputs, or offline validation breaks.

Dependencies: `resource_group`, `managed_identity`, `container_registry`, `container_app_environment`, plus `postgresql` only when the service has a `dbContext`.

Inputs:
```hcl
inputs = {
  app_name                     = "{unit}"
  resource_group_name          = dependency.resource_group.outputs.name
  container_app_environment_id = dependency.container_app_environment.outputs.id
  managed_identity_id          = dependency.managed_identity.outputs.id
  registry_server              = dependency.container_registry.outputs.login_server
  image_repository             = "{project}-{unit}"   # image = <acr>/{project}-{unit}:${IMAGE_TAG}

  ingress_external = false                            # true only with --external
  target_port      = {port}
  min_replicas     = local.env.min_replicas
  max_replicas     = local.env.max_replicas
  cpu              = local.env.app_cpu
  memory           = local.env.app_memory

  # Only with a dbContext. Key Vault reference via the managed identity: the value never enters state.
  key_vault_secrets = {
    "{unit}-db-connection" = dependency.postgresql.outputs.connection_string_secret_id
  }
  secret_env_vars = {
    ConnectionStrings__{Name} = "{unit}-db-connection"
  }
  env_vars = merge({
    ASPNETCORE_ENVIRONMENT = local.env.aspnetcore_environment
    OTEL_SERVICE_NAME      = "{unit}"
    AZURE_CLIENT_ID        = dependency.managed_identity.outputs.client_id
  }, local.otel_env)
}
```
- `{Name}` is the key the service passes to `GetConnectionString(...)`. Grep its Infrastructure project to find it.
- The starter's `postgresql` unit writes one connection-string secret for the shared database, and each service owns its own schema there. Reusing that secret ID under a service-named Container App secret is the intended pattern. A dedicated database or login per service means extending the postgresql module, so flag it to the user instead of inventing secrets.
- Image tags, probes (`/health/live`, `/health/ready` on `target_port`), `revision_mode = "Single"` and the registry identity are module defaults. Don't override them.

### 3. Per-environment units

For each env in `ENVS`, create `{UNITS_PATH}/{env}/{unit}/terragrunt.hcl` with the same two-include shape as the existing units:
```hcl
# {env} / {unit} — configuration lives in _envcommon/{unit}.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/{unit}.hcl"
}
```

### 4. Dockerfile (only if `{path}/Dockerfile` is missing)

Mirror an existing service Dockerfile, e.g. `src/Orders/Dockerfile`:
- Multi-stage: `mcr.microsoft.com/dotnet/sdk:{dotnetVersion}` restores from the copied `*.csproj` files first (layer cache), then publishes `{path}/{projectPrefix}.Host` with `--no-restore /p:UseAppHost=false`.
- Copy `global.json Directory.Build.props Directory.Packages.props .editorconfig`, the shared projects from `backend.sharedPaths`, and the service's own projects.
- Runtime stage `mcr.microsoft.com/dotnet/aspnet:{dotnetVersion}`, `ENV ASPNETCORE_HTTP_PORTS={port}`, `COPY --chown=$APP_UID`, `USER $APP_UID` (non-root), `EXPOSE {port}`, `ENTRYPOINT ["dotnet", "{projectPrefix}.Host.dll"]`.
- Header comment with the build command: the context is the repository root, `docker build -f {path}/Dockerfile -t {project}-{unit} .`.

Check that `.dockerignore` excludes `**/bin/`, `**/obj/`, `web/`, `infra/`, `tests/`.

### 5. Migration job (only with a `dbContext`)

Run `/cloud-infra:add-container-app-job {unit}-migrate --service {service} --args "--migrate"`. The host has to support `--migrate`: look for the `MigrateArgument` pattern in `src/Orders/Starter.Orders.Host/Program.cs`. If it's missing, tell the user, because without it the job would start the web server and never exit.

### 6. Gateway wiring (when `_envcommon/{GATEWAY}.hcl` exists and the app is internal)

- In `_envcommon/{GATEWAY}.hcl`, add a `dependency "{unit_snake}"` block shaped like the existing service dependency (outputs `id`, `name`, `fqdn`, `latest_revision_name`, `image`, with mocks). Then add:
  ```hcl
  ReverseProxy__Clusters__{unit}__Destinations__d1__Address = "https://${dependency.{unit_snake}.outputs.name}.internal.${dependency.container_app_environment.outputs.default_domain}"
  ```
  This dependency also makes Terragrunt apply the service before the gateway.
- In the gateway's `appsettings.json` `ReverseProxy`, add route `{unit}` (`ClusterId: {unit}`, `Match.Path: /api/{resource}/{**catch-all}`) and cluster `{unit}` with a local `d1` address (`http://localhost:<launchSettings port>`).
- If `localDev.orchestrator` is `docker-compose`, add the service (plus `{unit}-migrate` with `command: ["--migrate"]` when there is a DbContext) to the compose file, and set `ReverseProxy__Clusters__{unit}__Destinations__d1__Address: http://{unit}:{port}` on the gateway.

### 7. Format and validate (offline, no Azure needed)

```bash
cd {TG_PATH} && terragrunt hcl format
cd {UNITS_PATH with env=dev} && TG_OFFLINE=true IMAGE_TAG=abc1234 terragrunt run --all validate --provider-cache
```
`TG_OFFLINE=true` makes `root.hcl` use a throwaway local backend and the mock outputs, and refuses plan/apply. If parallel provider downloads fail with checksum or plugin errors, rerun with `--parallelism 1`. Fix every error before reporting.

## Output

```
## Container App: {unit}

| Env | Unit | Azure name | Ingress |
|-----|------|------------|---------|
| dev | {UNITS_PATH}/dev/{unit} | {project}-ca-{unit}-dev-{loc} | internal :{port} |
...
Image: <acr>/{project}-{unit}:${IMAGE_TAG}
Secrets: {unit}-db-connection -> ConnectionStrings__{Name} (Key Vault ref) | none
Dockerfile: created | existing ({path}/Dockerfile)
Migration job: {unit}-migrate (registered in containerApps.migrationJobs) | none
Gateway: route /api/{resource} -> {unit} | not wired (reason)
Validation: hcl format ok, dev validate ok (N units)

Next: add the image to the CI build matrix (/cloud-infra:add-ci-pipeline), then /cloud-infra:deploy dev.
```

## Safety

- Never write real IDs, connection strings or secret values into HCL. Use Key Vault references and dependency outputs only.
- Don't run `plan` or `apply` here. Applying is `/cloud-infra:infra-apply` for the first rollout (the image has to be in ACR first) and `/cloud-infra:deploy` after that.
- Leave existing units unchanged, apart from the gateway wiring described above.

## Related Skills

- container-apps-conventions: the rules these units follow
- `/cloud-infra:add-container-app-job`: migration and one-off jobs
- `/cloud-infra:deploy`: build, migrate and roll out
- `/cloud-infra:infra-lint`: full Terraform/Terragrunt lint
