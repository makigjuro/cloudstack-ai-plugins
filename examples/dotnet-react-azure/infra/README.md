# Starter infrastructure (Azure Container Apps)

Terraform modules + Terragrunt environments for the Orders service, the gateway and the web app. It follows the
"Cloud Infrastructure" design in [`docs/architecture.md`](../../../docs/architecture.md):
immutable SHA-tagged images, only the gateway is public, no stored credentials, migrations
before traffic, probes on every app, and environments promoted rather than rebuilt.

```
infra/
├── terraform/
│   ├── .trivyignore            # accepted trivy findings, each justified
│   └── modules/                # one module per resource (main/variables/outputs/versions)
├── terragrunt/
│   ├── root.hcl                # remote state, provider generation, common inputs
│   ├── _envcommon/<unit>.hcl   # DRY unit definitions (source, dependencies, mocks, inputs)
│   └── {dev,staging,prod}/
│       ├── env.hcl             # per-environment sizing
│       └── <unit>/terragrunt.hcl
└── scripts/bootstrap-state.sh  # creates the per-env state storage (az CLI)
```

## What gets created (per environment)

Names follow `{project}-{resource}-{env}-{location_short}` with `project = starter` and
`location = westeurope` (`weu`). Every resource is tagged `project`, `environment`, `managed-by`.

| Unit | Module | Azure resources (dev names) |
|------|--------|-----------------------------|
| `resource-group` | resource-group | `starter-rg-dev-weu` |
| `networking` | networking | VNet `starter-vnet-dev-weu`; `snet-aca` (delegated to `Microsoft.App/environments`, KeyVault service endpoint); `snet-postgresql` (delegated to Flexible Server, NSG allows 5432 from ACA only); private DNS zone `starter-dev.private.postgres.database.azure.com` + VNet link |
| `managed-identity` | managed-identity | `starter-id-dev-weu`, shared by apps and the job |
| `monitoring` | monitoring | Log Analytics `starter-log-dev-weu` |
| `key-vault` | key-vault | `starter-kv-dev-weu`: RBAC auth, firewall default Deny (ACA subnet + listed IPs + Azure services), identity → Key Vault Secrets User, deployer → Key Vault Secrets Officer |
| `container-registry` | container-registry | `starteracrdevweu`: admin user disabled, identity → AcrPull, optional CI principals → AcrPush |
| `postgresql` | postgresql | `starter-psql-dev-weu` Flexible Server (private access only, TLS 1.2+), database `starter`, generated admin password in KV secret `postgres-admin-password`, Npgsql connection string in KV secret `orders-db-connection` |
| `container-app-environment` | container-app-environment | `starter-cae-dev-weu`: Consumption workload profile, VNet-injected, logs to Log Analytics |
| `static-web-app` | static-web-app | `starter-swa-dev-weu` (React SPA) |
| `orders` | container-app | `starter-ca-orders-dev-weu`: image `<acr>/starter-orders:<IMAGE_TAG>`, internal ingress on 8080, `ConnectionStrings__Orders` from KV |
| `gateway` | container-app | `starter-ca-gateway-dev-weu`: image `<acr>/starter-gateway:<IMAGE_TAG>`, **external** ingress, routes to `https://starter-ca-orders-dev-weu.internal.<env default domain>`, CORS for `https://<swa default hostname>` |
| `orders-migrate` | container-app-job | `starter-job-orders-dev-weu`: manual-trigger job, orders image with `--migrate`, same KV DB secret |

All apps: `revision_mode = Single`, liveness `/health/live`, readiness `/health/ready`, registry
pulls and Key Vault references via the managed identity, `OTEL_EXPORTER_OTLP_ENDPOINT` set from
`env.hcl` (`otel_exporter_otlp_endpoint`) when non-empty.

| Setting (`env.hcl`) | dev | staging | prod |
|---------------------|-----|---------|------|
| `min_replicas` / `max_replicas` | 0 / 2 | 1 / 3 | 2 / 10 |
| PostgreSQL SKU, backups, HA | B1ms, 7 d | D2ds_v5, 14 d | D2ds_v5, 35 d geo-redundant, ZoneRedundant HA |
| Key Vault purge protection | off | on | on |
| ACR SKU / SWA SKU | Standard / Free | Standard / Standard | Premium / Standard |
| CAE zone redundancy | off | on | on |
| VNet | 10.10.0.0/16 | 10.20.0.0/16 | 10.30.0.0/16 |

## Prerequisites

- Terraform >= 1.5 (Terragrunt is pointed at `terraform`, not OpenTofu; override with `TG_TF_PATH`),
  Terragrunt 0.93+, az CLI.
- The deploying principal needs **Contributor + Role Based Access Control Administrator** (or
  Owner) on the subscription or env resource group, because modules create role assignments
  (AcrPull, Key Vault Secrets User/Officer).
- Authenticate through environment variables only, nothing is committed:
  `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, and either `az login` locally or
  `ARM_CLIENT_ID` + `ARM_USE_OIDC=true` in CI.

## 1. Bootstrap remote state (once per environment)

```bash
DRY_RUN=1 scripts/bootstrap-state.sh dev                 # show what will be created
scripts/bootstrap-state.sh dev [<ci-principal-object-id>]
```

It creates `starter-rg-tfstate-<env>-weu` and storage account `startertfstate<env>weu`
(container `tfstate`, shared keys disabled, versioning + soft delete, delete lock), and grants
Storage Blob Data Contributor to the signed-in user or the given principal. Terragrunt uses
Entra ID auth for state (`use_azuread_auth = true`). State keys are `<env>/<unit>/terraform.tfstate`.

## 2. Validate offline (no Azure needed)

```bash
cd terragrunt/dev
IMAGE_TAG=abc1234 terragrunt run --all validate --provider-cache
```

When `ARM_SUBSCRIPTION_ID` is unset (or `TG_OFFLINE=true`), `root.hcl` swaps the azurerm
backend for a throwaway local one, so dependency outputs fall back to `mock_outputs`. A
`before_hook` refuses `plan`/`apply`/`destroy`/`import`/`refresh`/`state` in that mode, so it can
never write real infrastructure into local state.

Every unit downloads the azurerm provider on its own. If parallel runs fail with lock-file checksum mismatches or `Unrecognized remote plugin message`, it's concurrent downloads on your machine, not the configuration. Share one download with Terragrunt's provider cache, or run sequentially:

```bash
IMAGE_TAG=abc1234 terragrunt run --all validate --provider-cache   # one shared provider download
IMAGE_TAG=abc1234 terragrunt run --all validate --parallelism 1    # or one unit at a time
```

## 3. Plan and apply

```bash
export ARM_SUBSCRIPTION_ID=<sub> ARM_TENANT_ID=<tenant>
export IMAGE_TAG=$(git rev-parse --short=7 HEAD)    # must already be pushed to the env's ACR
export KEY_VAULT_ALLOWED_IPS=$(curl -4 -s ifconfig.me)  # first apply from a laptop (see below)
cd terragrunt/<env>
terragrunt run --all plan -- -input=false -out=tfplan   # Terraform flags go after `--`
terragrunt run --all apply -- tfplan
```

Terragrunt orders units from the dependency graph:
`resource-group` → `networking`, `managed-identity`, `monitoring`, `static-web-app` →
`key-vault`, `container-registry`, `container-app-environment` → `postgresql` →
`orders`, `orders-migrate` → `gateway`.

### First apply of a new environment: apply in waves

A unit whose dependency doesn't exist yet is planned with that dependency's `mock_outputs`
(Terragrunt logs `has no outputs, but mock outputs provided`). On a new environment that is
every unit except `resource-group`, and their saved plans point at resources like
`starter-rg-mock-weu`, so applying them fails with 404. Every mock value in this repo contains
`mock`, which makes them easy to spot. Apply wave by wave and make each wave's plans after the
previous wave exists:

```bash
# For each wave, in each unit: plan, check, then apply exactly that plan
#   1: resource-group
#   2: networking managed-identity monitoring static-web-app
#   3: key-vault container-registry container-app-environment
#   4: postgresql
#   (5: orders-migrate, orders, then gateway: these are rolled out by /cloud-infra:deploy)
cd terragrunt/<env>/<unit>
terragrunt plan -input=false -out=tfplan
terragrunt show -json tfplan | grep -ci mock     # must print 0; otherwise a dependency isn't applied yet
terragrunt apply -input=false tfplan
```

Once every unit exists, a single `run --all plan` / `apply` works, because each dependency then
has real outputs.

Notes:
- `IMAGE_TAG` (or `TF_VAR_image_tag`) is required; the app/job modules reject empty values and `latest`.
- On the very first apply the ACR is empty, so apply the platform units first, push the images,
  then roll out the app units with `/cloud-infra:deploy <env>` (or the deploy workflow), which plans
  the gateway only after `orders` exists.
- **Key Vault firewall:** Terraform writes the PostgreSQL secrets from wherever it runs, so the
  runner's IPv4 must be allowed. Put fixed operator/CI egress IPs in `key_vault_allowed_ip_addresses`.
  For a laptop or a hosted runner, export `KEY_VAULT_ALLOWED_IPS` (comma-separated IPv4, e.g.
  `$(curl -4 -s ifconfig.me)`) for the first apply instead of committing the IP. Key Vault rules
  are IPv4 only, so use `curl -4`. Terraform ignores later `ip_rules` changes, so it never strips
  rules added afterwards; to allow a new IP later, use
  `az keyvault network-rule add --name starter-kv-<env>-weu --ip-address <ip>`. Container Apps
  resolve secrets over the ACA subnet's KeyVault service endpoint. If your setup can't resolve
  references through the firewall, set `network_default_action = "Allow"` for that env's key-vault
  unit and document the exception.
- **Destroy:** in dev (no purge protection) destroying the key-vault unit also purges the vault,
  so the next apply starts clean. With purge protection (staging, prod) the vault stays
  soft-deleted and is recovered by the next apply.

### Authentication

The services validate JWTs and refuse to start without `Auth:Authority` and `Auth:Audience`.
Both come from `env.hcl`:
- `auth_authority`: leave it empty to use the tenant you deploy with
  (`https://login.microsoftonline.com/<ARM_TENANT_ID>/v2.0`), or set another issuer.
- `auth_audience`: the Application ID URI of the API's app registration, `api://starter-api-<env>`
  by default.

With these set, the API starts and answers 401 to requests without a valid token, which is what
the deploy smoke test checks. To call it with real tokens, register the API once per environment:

```bash
az ad app create --display-name starter-api-<env> --identifier-uris api://starter-api-<env>
```

Then add an app role or scope for your clients (and the SPA's app registration).

## 4. How a deploy rolls a new revision

1. CI builds `starter-orders` and `starter-gateway` once, tagged with the git SHA, and pushes them
   to the dev ACR. For staging/prod the **same digest** is promoted with
   `az acr import --source <dev-acr>.azurecr.io/starter-orders:<sha> --name <env-acr>`, never rebuilt.
2. `IMAGE_TAG=<sha> terragrunt apply` in `<env>/orders-migrate` updates the job definition to the new image.
3. Run the migration and wait for it to succeed **before** traffic moves:
   `az containerapp job start -g starter-rg-<env>-weu -n starter-job-orders-<env>-weu`, then poll
   `az containerapp job execution show` until it reports `Succeeded`.
4. `IMAGE_TAG=<sha> terragrunt apply` in `<env>/orders`, then `<env>/gateway`. The image change creates
   a new revision (Single mode); ACA only shifts traffic once `/health/ready` passes.
5. Health check and smoke test through the gateway FQDN. Roll back by re-applying the previous SHA
   or re-activating the previous revision (`az containerapp revision activate`).

The SPA is deployed to the Static Web App by CI with a deployment token fetched at deploy time
(`az staticwebapp secrets list -n starter-swa-<env>-weu`), not stored as a GitHub secret.

## 5. GitHub Actions OIDC (setup for the workflows in `../.github/workflows/`)

Create one Entra app registration (or user-assigned identity) per environment, with no client
secret, and add federated credentials bound to GitHub **environments**:

| Environment | Issuer | Subject |
|-------------|--------|---------|
| dev | `https://token.actions.githubusercontent.com` | `repo:<owner>/<repo>:environment:dev` |
| staging | same | `repo:<owner>/<repo>:environment:staging` |
| prod | same | `repo:<owner>/<repo>:environment:prod` |

Audience: `api://AzureADTokenExchange`. Add `repo:<owner>/<repo>:pull_request` on the dev
identity only if PRs should run `plan` (read-only roles).

```bash
az ad app federated-credential create --id <app-id> --parameters '{
  "name": "github-staging",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<owner>/<repo>:environment:staging",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

Grant each identity the deploy roles on its environment only (Contributor + RBAC Administrator
on `starter-rg-<env>-weu`, Storage Blob Data Contributor on the state account), and list its
object ID in `acr_push_principal_ids` in that env's `env.hcl`. Workflows set `ARM_USE_OIDC=true`,
`ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` as GitHub environment **variables**
(they are identifiers, not secrets), and protect `staging`/`prod` with required reviewers.

## Verification

```bash
terraform fmt -check -recursive terraform/
(cd terragrunt && terragrunt hcl format --check)
for m in terraform/modules/*/; do terraform -chdir=$m init -backend=false && terraform -chdir=$m validate; done
(cd terragrunt/dev && IMAGE_TAG=abc1234 terragrunt run --all validate --provider-cache)
trivy config --ignorefile terraform/.trivyignore terraform/
```
