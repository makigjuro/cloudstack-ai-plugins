---
name: deploy
description: Deploy services to Azure Container Apps the Terraform-native way. It builds and pushes SHA-tagged images, or promotes the dev image to staging/prod with az acr import, then plans, runs the migration job and waits for it, rolls the apps (gateway last), checks revision health, smoke tests through the gateway, and rolls back to the previous tag on failure. Use when the user wants to deploy, release, ship, roll out, promote or redeploy services to an environment. It defaults to a preview that changes nothing.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: true
argument-hint: "{env} [--services a,b] [--tag <sha>] [--apply]"
---

# Deploy (Container Apps)

Roll new images out to one environment without letting Terraform state drift. Images only change through `IMAGE_TAG=<tag> terragrunt apply`, never through `az containerapp update --image`. CI runs the same sequence (`.github/workflows/reusable-rollout.yml`, from `/cloud-infra:add-ci-pipeline`).

## Arguments

- `{env}` (required): one of `containerApps.environments`.
- `--services a,b`: limit the rollout to these `backend.services` (names or aliases) and/or the gateway. Default: every service with an app unit, plus the gateway.
- `--tag <sha>`: deploy an existing tag. Default: `git rev-parse --short=7 HEAD`. `latest` is refused, and so is any tag the modules' `image_tag` validation rejects.
- `--apply`: carry out the rollout after the preview and an explicit "yes". Without it, nothing is built, pushed, imported or applied.

## Configuration

Read `blueprint.json`:
- `RUNTIME` = `infrastructure.runtime`. If it is `aks`, stop and say this skill targets Container Apps (use Helm/your cluster pipeline). If it is `none`, stop.
- `TG_PATH`, `UNITS_PATH` = `infrastructure.containerApps.appUnitsPath` (default `infra/terragrunt/{env}`)
- `GATEWAY` = `containerApps.gatewayApp` (default `gateway`), `ENVS` = `containerApps.environments`
- `MIGRATION_JOBS` = `containerApps.migrationJobs` (service → job unit, e.g. `{"Orders": "orders-migrate"}`)
- `backend.services[].path` (the Dockerfile is `{path}/Dockerfile`)

For each app unit, read `image_repository` from `{TG_PATH}/_envcommon/{unit}.hcl`. That value is authoritative, so don't guess image names. The gateway Dockerfile is wherever its project lives (e.g. `src/Starter.ApiGateway/Dockerfile`).

**Rollout set:** for each selected service, its migration unit from `MIGRATION_JOBS` (if any) and its app unit. Then the gateway, always last.

## Step 1: Preflight (stop on any failure)

- Tools: `az`, `terraform`, `terragrunt`, `docker` (building only), `jq`. If any is missing, suggest `/dev-workflow:doctor infra`.
- `git status --porcelain` must be empty when building, because the image has to match the commit it's tagged with. With `--tag` for a promotion, just warn.
- `az account show --query "{name:name, id:id, tenant:tenantId}" -o table`. Confirm the subscription belongs to `{env}` (ask if unsure), then `export ARM_SUBSCRIPTION_ID=<id> ARM_TENANT_ID=<tenant>`. Without `ARM_SUBSCRIPTION_ID`, `root.hcl` falls back to offline mode and refuses plan/apply.
- Resolve targets from state: `RG=$(cd {UNITS_PATH}/resource-group && terragrunt output -raw name)` and `ACR=$(cd .../container-registry && terragrunt output -raw name)`. If they're empty, the platform isn't applied yet, so send the user to `/cloud-infra:infra-apply {env}`.

## Step 2: Images

- `dev` (the first env in `ENVS`): **build**. For each image, check `az acr repository show --name "$ACR" --image "<repo>:<tag>"`. If it already exists, skip it (tags are immutable). Otherwise, with `--apply`:
  ```bash
  az acr login --name "$ACR"
  docker build --platform linux/amd64 -f <Dockerfile> -t "$ACR.azurecr.io/<repo>:<tag>" .   # context = repo root
  docker push "$ACR.azurecr.io/<repo>:<tag>"
  ```
  `--platform linux/amd64` matters on Apple Silicon, because Container Apps runs amd64 and an arm64 image fails to start. The Dockerfile's SDK stage must use `FROM --platform=$BUILDPLATFORM` and `-a $TARGETARCH` (as the reference Dockerfiles do): under amd64 emulation `dotnet restore` crashes with `AccessViolationException` (exit 134). If a build fails that way, fix the Dockerfile rather than retrying.
- `staging`/`prod`: **promote, never rebuild**, so the tested digest is what ships. The source is the previous env in `ENVS`, and the tag must already exist there (if it doesn't, stop and deploy to that env first). With `--apply`:
  ```bash
  az acr import --name "$ACR" --source "<source-acr>.azurecr.io/<repo>:<tag>" --image "<repo>:<tag>"
  # source ACR in another subscription:
  az acr import --name "$ACR" --registry <source-acr-resource-id> --source "<repo>:<tag>" --image "<repo>:<tag>"
  ```

## Step 3: Record what is deployed now

Get each unit's Azure name from state (`terragrunt output -raw name` in the unit), then record the current tag (the part after the last `:`):
```bash
az containerapp show     -g "$RG" -n <app> --query "properties.template.containers[0].image" -o tsv
az containerapp job show -g "$RG" -n <job> --query "properties.template.containers[0].image" -o tsv
```
An empty result means this is the first rollout, so there's nothing to roll back to. Note that in the report.

## Step 4: Plan (the preview)

For every unit in the rollout set:
```bash
cd {UNITS_PATH}/<unit> && IMAGE_TAG=<tag> terragrunt plan -input=false -out=tfplan
terragrunt show -json tfplan | jq '[.resource_changes[]? | select(.change.actions | index("delete"))] | length'
```
A deploy should only change images, env and revisions. If any plan deletes or replaces a resource, stop and send the change through `/cloud-infra:infra-apply`. Show a compact per-unit summary (add/change/destroy, old → new image).

**Mock values.** Count them in each plan: `terragrunt show -json tfplan | grep -ci mock` (mock outputs in this architecture contain `mock`; Terragrunt also logs `has no outputs, but mock outputs provided`). An empty `show` output means the plan is unchecked, not clean.
- On a first rollout, the gateway's plan uses mock values, because the services it routes to don't exist yet. Mark the unit **deferred** in the preview, and plan it again in Step 5 right before applying it. If that new plan still has mock values, stop.
- A migration or service unit with mock values means the platform isn't applied. Stop and send the user to `/cloud-infra:infra-apply {env}`.

**Without `--apply`, stop here** with the preview report. That report covers which images would be built or imported, the plans, the current tags, and the migration jobs that would run.

With `--apply`, ask: "Deploy `<tag>` to `{env}` (units: ...)? Type yes to continue." Anything other than yes stops the run. For `prod`, repeat the env name in the question.

## Step 5: Roll out (with `--apply` and confirmation)

Push or import the images from Step 2 first. Then:

1. **Migrations.** For each migration unit, run `terragrunt apply -input=false tfplan`, then start the job and poll it:
   ```bash
   exec=$(az containerapp job start -g "$RG" -n <job> --query name -o tsv)
   az containerapp job execution show -g "$RG" -n <job> --job-execution-name "$exec" --query properties.status -o tsv
   ```
   Poll every ~10 s until the status is `Succeeded`. `Failed`, `Stopped`, `Degraded`, or a timeout (about 20 min) means **stop**: the apps are untouched, so go to rollback for the job unit only. Point the user at Log Analytics (`ContainerAppConsoleLogs_CL`) for the job output.
2. **Apps, gateway last.** For each app unit, plan it again first if it was deferred in Step 4, and check that the new plan has no mock values and no deletes. Then run `terragrunt apply -input=false tfplan` and wait for the new revision. Poll every ~10 s for up to ~10 min:
   ```bash
   az containerapp show -g "$RG" -n <app> --query "[properties.latestRevisionName, properties.latestReadyRevisionName]" -o tsv
   az containerapp revision show -g "$RG" -n <app> --revision <latest> \
     --query "[properties.template.containers[0].image, properties.runningState, properties.healthState]" -o tsv
   ```
   Healthy means: the latest revision runs `<tag>`, it equals `latestReadyRevisionName`, and `healthState` isn't `Unhealthy`. In dev, scale-to-zero can leave it at `None`, and the smoke test wakes it. A `runningState` of `Failed`, `Degraded` or `ActivationFailed`, or a timeout, triggers rollback. Stop before the next app. `ActivationFailed` usually means the container exited on start: read `ContainerAppConsoleLogs_CL` in Log Analytics for the reason (a missing setting such as `Auth__Authority` shows up there).
3. **Smoke test.** Get the gateway host with `fqdn=$(cd {UNITS_PATH}/{GATEWAY} && terragrunt output -raw fqdn)`.
   - `https://$fqdn/health/ready` must return 200. Retry for about 2 min, since dev cold starts are slow.
   - For each deployed service with a gateway route (`ReverseProxy.Routes` in the gateway's `appsettings.json`, e.g. `/api/orders`), an unauthenticated GET should return `401`. That shows the gateway reached the service. A 404, 502 or 503 means routing or the service is broken.
   - Any failure triggers rollback.

## Step 6: Roll back (on any failure after an apply)

Work in reverse order over the units that were applied, re-applying each one's recorded previous tag:
```bash
cd {UNITS_PATH}/<unit> && IMAGE_TAG=<previous-tag> terragrunt apply -input=false -auto-approve
```
Then wait for the app revision as in step 2. The new image is in the recorded state already, so this restores it. It's announced and doesn't need new confirmation. Schema migrations are **not** reverted: they must be backwards compatible (expand/contract) so the previous app version still runs. Say so if a migration ran. If there is no previous tag (first rollout), leave the unit and report it. `az containerapp revision activate` is only an emergency stop-gap, because it drifts from state. Follow it with the re-apply.

Delete the plan files at the end. Terragrunt writes them in each unit's `.terragrunt-cache` working dir, so run `find {UNITS_PATH} -name tfplan -delete` for this env.

## Output

```
## Deploy {env}: <tag>  (preview | applied | rolled back)

| Service | Unit | Old tag → New tag | Revision | Health |
|---------|------|-------------------|----------|--------|
| Orders  | orders  | 3f2a9c1 → 8b41d07 | starter-ca-orders-dev-weu--xyz | Healthy |
| gateway | gateway | 3f2a9c1 → 8b41d07 | ...   | Healthy |

Images: built+pushed | imported from <source-env> | already present
Migrations: orders-migrate → starter-job-orders-dev-weu execution <name>: Succeeded | Failed | skipped
Smoke: /health/ready 200, /api/orders 401 | <failure>
Rollback: not needed | complete (units...) | partial/failed (details)
```
In preview mode, list the plans and the exact `--apply` command to run next.

## Safety

- The preview is the default. Never build, push, import, apply or start a job without `--apply` **and** an explicit yes after the preview.
- Never deploy `latest` or an untagged image. Never rebuild for staging/prod.
- Never use `az containerapp update --image`: Terraform state would drift and the next apply would revert it.
- Stop on a failed migration before touching any app.
- Don't change platform units (network, Key Vault, database, registry) here. That belongs to `/cloud-infra:infra-apply`.
- Don't print secrets. Nothing in this flow needs secret values.

## Related Skills

- `/cloud-infra:add-container-app`, `/cloud-infra:add-container-app-job`: create the units this skill rolls out
- `/cloud-infra:add-ci-pipeline`: the same sequence in GitHub Actions
- `/cloud-infra:infra-apply`: platform changes and first-time applies
- `/dev-workflow:doctor`: install missing tools
