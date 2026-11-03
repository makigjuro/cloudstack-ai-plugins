---
name: add-ci-pipeline
description: Scaffold GitHub Actions CI/CD for a Container Apps project. It covers PR/main CI (.NET build and tests, web lint/test/build, Terraform/Terragrunt format, validate and trivy), an OIDC deploy that builds SHA-tagged images once and promotes them dev → staging → prod with migration-job-first rollouts and smoke tests, and a Static Web Apps deploy for the SPA. It also documents the one-time Azure/GitHub setup. Use when the user wants CI, a pipeline, GitHub Actions, automated deploys or environment promotion.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch
user-invocable: true
argument-hint: "[ci|deploy|web|all]"
---

# Add CI Pipeline (GitHub Actions, Container Apps)

Generate workflows that enforce the architecture's deploy rules: immutable SHA tags, build once and promote, migrations before traffic, OIDC only, and Terraform-native rollouts so state never drifts.

## Arguments

- `ci`: `ci.yml` only. `deploy`: `deploy.yml` + `reusable-rollout.yml`. `web`: `deploy-web.yml` + `reusable-deploy-web.yml`. `all` (default): all of them.

## Reference implementation

The canonical output is the starter's workflows: `examples/dotnet-react-azure/.github/workflows/` in the cloud-app-blueprint repo (https://github.com/makigjuro/cloud-app-blueprint/tree/main/examples/dotnet-react-azure/.github/workflows). Read the local copy if this is that repo; otherwise fetch the raw files. Reproduce them, changing only the project-specific values listed below. Their structure, step order and shell helpers are deliberate. If neither copy is reachable, write the workflows from the requirements in this file.

## Configuration

Read `blueprint.json`. Stop if `infrastructure.cicd` is set to something other than `github-actions`. If `infrastructure.runtime` is `aks`, say that this scaffold targets Container Apps (an AKS pipeline would use Helm, see `/cloud-infra:add-helm-chart`) and stop.

Adapt the following, and read each value from the repo rather than assuming it:

| Value | Source |
|-------|--------|
| `PROJECT`, `LOCATION_SHORT` | `locals` in `{terragruntPath}/root.hcl` |
| Build matrix (`image`, `dockerfile`) | `image_repository` in each `_envcommon/<app>.hcl`; the Dockerfile at `backend.services[].path/Dockerfile` plus the gateway project's Dockerfile |
| `MIGRATION_UNITS` | values of `containerApps.migrationJobs` |
| `APP_UNITS` | app units (sourcing `container-app`), with `containerApps.gatewayApp` **last** |
| `IMAGES` | all `image_repository` values |
| `SMOKE_UNAUTHENTICATED_ROUTES` | gateway `ReverseProxy.Routes[*].Match.Path` prefixes (e.g. `/api/orders`); each must return 401 without a token |
| Environments | `containerApps.environments`, in promotion order |
| Solution and tests | `backend.solutionPath`; unit and integration filters as in the project README (`Category!=Integration` / `Category=Integration`) |
| .NET version | `backend.dotnetVersion` → `dotnet-version: "<major>.0.x"` |
| Web | `frontend.path`, Node major from `package.json` `engines.node`, the scripts that exist (`type-check`, `lint`, `test`, `build`) |
| Terraform | `hashicorp/setup-terraform@v3` with `terraform_version` matching the modules' `required_version` line (starter: `1.5.x`), `terraform_wrapper: false` |
| Terragrunt | pinned release (starter: `0.93.13`), downloaded and checked against the release `SHA256SUMS` |
| Web deploy | only if `infrastructure.frontendHosting` is `static-web-app`; SWA name `{project}-swa-{env}-{loc}`, gateway app `{project}-ca-{gateway}-{env}-{loc}` |

If workflows already exist in `.github/workflows/`, show a diff and ask before overwriting.

## Requirements each workflow must meet

**`ci.yml`** runs on `pull_request` and on `push` to `main`, with `permissions: contents: read`.
- A `changes` job (`dorny/paths-filter@v3`) and `backend`/`web`/`infra` jobs gated on its outputs. One workflow keeps a single required status check, and skipped jobs count as passing.
- backend: `actions/setup-dotnet@v4` → restore → build Release → unit tests → integration tests (Testcontainers uses the runner's Docker).
- web: `actions/setup-node@v4` with the npm cache keyed on the lockfile → `npm ci`, type-check, lint, `npm test -- --run`, build.
- infra: `terraform fmt -check -recursive`, `terragrunt hcl format --check`, then in `{env=dev}` run `terragrunt run --all validate --provider-cache` with `TG_OFFLINE=true IMAGE_TAG=ci` and no Azure credentials, so the mocks are used. Finish with trivy config using the repo's `.trivyignore`. Run trivy from a pinned `aquasec/trivy:<version>` image.

**`deploy.yml`** runs on `push` to `main` (backend and infra paths) and `workflow_dispatch`, with `permissions: id-token: write, contents: read`.
- `meta` sets the tag to `${GITHUB_SHA::7}`. `build` is a matrix job with `environment: dev` (it gets the dev OIDC subject): `azure/login@v2` → skip if the tag already exists → `az acr login` → `docker build` (repo root context) → `docker push`. It never pushes `latest`.
- `deploy-dev` → `promote-staging` → `promote-prod`, each a call to `reusable-rollout.yml` with `environment`, `image_tag`, and `promote_from` (the previous env) for staging and prod. Comment that staging and prod need **required reviewers** on their GitHub environments.

**`reusable-rollout.yml`** (`workflow_call`) has one job with `environment: ${{ inputs.environment }}` and `concurrency: deploy-<env>` with `cancel-in-progress: false`. Never cancel a half-finished rollout.
- `ARM_USE_OIDC=true` plus `ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` from `vars.*`, and `TG_NON_INTERACTIVE=true`.
- Steps: resolve RG and ACR from `terragrunt output -raw name` → promote (`az acr import`, skip if present; `--registry <id>` form when `SOURCE_ACR_RESOURCE_ID` is set) → verify every image exists → record the current tags → plan each unit to `tfplan`, failing if any change is a delete → apply migration units and run `az containerapp job start`, polling `az containerapp job execution show` until `Succeeded` → apply app units, gateway last, and wait for each revision (latest == latestReady, tag matches, not Unhealthy/Failed/Degraded) → smoke test (`/health/ready` 200, protected routes 401) → `if: failure()` rollback that re-applies the recorded previous tags in reverse → `if: always()` summary table.
- This is the same sequence as `/cloud-infra:deploy`. Keep the two consistent.

**`deploy-web.yml` + `reusable-deploy-web.yml`** run dev → staging → prod.
- After OIDC login, read the gateway FQDN with `az containerapp show --query properties.configuration.ingress.fqdn`. Fetch the deployment token with `az staticwebapp secrets list --query properties.apiKey` and mask it with `::add-mask::`. It is never stored as a repo secret.
- `npm ci && npm run build` with `VITE_API_BASE_URL=https://<gateway-fqdn>`, then copy `staticwebapp.config.json` into `dist/`.
- `Azure/static-web-apps-deploy@v1` with `action: upload`, `skip_app_build: true`, then a curl check.
- The SPA is rebuilt per env because the API URL is baked in at build time. Say so in a comment.

**All workflows:**
- Use major-version action tags (`actions/checkout@v4`, `actions/setup-dotnet@v4`, `actions/setup-node@v4`, `azure/login@v2`, `hashicorp/setup-terraform@v3`) and `defaults.run.shell: bash`.
- No client secrets and no `secrets.*` for Azure.
- If the project lives in a subdirectory of the git repo, add a top-of-file comment and adjust the paths. GitHub only reads `.github/workflows` at the repo root.

## One-time setup to document (print it, and offer to run the `gh` parts)

1. **Identity per environment.** Create an Entra app registration or a user-assigned managed identity, with no client secret. Add a federated credential:
   ```bash
   az ad app federated-credential create --id <app-id> --parameters '{
     "name": "github-<env>", "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:<owner>/<repo>:environment:<env>", "audiences": ["api://AzureADTokenExchange"]}'
   # user-assigned identity instead:
   az identity federated-credential create -g <rg> --identity-name <id> --name github-<env> \
     --issuer https://token.actions.githubusercontent.com --subject repo:<owner>/<repo>:environment:<env> \
     --audiences api://AzureADTokenExchange
   ```
2. **Role assignments**, scoped per environment:
   - **AcrPush** on that env's ACR. Add the principal's object ID to `acr_push_principal_ids` in `{env}/env.hcl` so Terraform owns it.
   - **Contributor** on `{project}-rg-{env}-{loc}`. This covers app/job updates, `az acr import` into the env ACR, and `az staticwebapp secrets list`.
   - **Storage Blob Data Contributor** on the state account `{project}tfstate{env}{loc}` (`scripts/bootstrap-state.sh {env} <object-id>` grants it).
   - **AcrPull** on the *previous* env's ACR (staging reads dev, prod reads staging) for promotion.
   - **Key Vault Secrets Officer** only if CI also applies units that write secrets (e.g. `postgresql`). The rollout doesn't. For full infra applies, also add Role Based Access Control Administrator, as `infra/README.md` describes.
3. **GitHub environments** `dev`, `staging`, `prod`, with required reviewers on staging and prod:
   ```bash
   gh api -X PUT repos/<owner>/<repo>/environments/prod --input - <<'EOF'
   {"reviewers":[{"type":"User","id":<user-id>}],"deployment_branch_policy":{"protected_branches":true,"custom_branch_policies":false}}
   EOF
   gh variable set AZURE_CLIENT_ID       --env prod --body <client-id>
   gh variable set AZURE_TENANT_ID       --env prod --body <tenant-id>
   gh variable set AZURE_SUBSCRIPTION_ID --env prod --body <subscription-id>
   ```
   These are **variables**, not secrets, since they are identifiers. Set `SOURCE_ACR_RESOURCE_ID` on staging and prod only when the source ACR is in another subscription.
4. **First deploy.** Apply the platform units per env with `/cloud-infra:infra-apply` before the pipeline runs. The rollout refuses to start when the resource group or ACR outputs are missing.

## Verify

```bash
python3 -c "import sys,yaml; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/*.yml
actionlint   # if installed (also runs shellcheck on run: blocks when shellcheck is on PATH)
```
Check that every unit, output (`name`, `fqdn`), Dockerfile and image repository the workflows reference exists in the repo, and list any that you had to assume.

## Output

```
## CI pipeline scaffolded

| File | Purpose |
|------|---------|
| .github/workflows/ci.yml | PR + main: backend / web / infra (path-filtered) |
| .github/workflows/deploy.yml | build once → dev → staging → prod |
| .github/workflows/reusable-rollout.yml | migrate → apps → smoke → rollback |
| .github/workflows/deploy-web.yml (+ reusable-deploy-web.yml) | SPA to Static Web Apps |

Services: <image → Dockerfile>   Migration units: <...>   Smoke routes: <...>
Validation: yaml ok, actionlint ok | not installed
Setup still needed: <identities, roles, environments, variables>
```

## Related Skills

- `/cloud-infra:deploy`: the same rollout, run locally
- `/cloud-infra:add-container-app`: add a service, then add it to the build matrix and `APP_UNITS`
- `/cloud-infra:infra-lint`: what the CI infra job runs
