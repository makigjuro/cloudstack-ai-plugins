# cloud-infra

**The cloud layer of the [cloudstack reference architecture](../../README.md).** It provisions the app on Azure Container Apps with Terraform/Terragrunt, with AKS + Helm as an alternative. You see the plan before anything is applied.

```
/plugin install cloud-infra@cloudstack-ai-plugins
```

## The architecture it targets

- **Azure Container Apps (default):**
  - One container app per service, in a VNet-injected environment.
  - Only the gateway is public; every other service uses internal ingress.
  - Images are tagged with the commit SHA and pulled from ACR with a managed identity.
  - Secrets are Key Vault references; probes are `/health/live` and `/health/ready`.
  - EF Core migrations run as ACA Jobs.
  - The frontend is on Static Web Apps.
- **Terraform modules** for each resource, wired per environment with Terragrunt.
- **GitHub Actions** authenticates to Azure with OIDC. The same image is promoted dev → staging → prod.
- **AKS + Helm (alternative):** one chart per service, with the release namespace, standard labels and resource limits.
- **Security and review:** every change is linted, scanned with trivy and reviewed. Apply runs only on the plan you reviewed.

> Container Apps–specific skills (`add-container-app`, migration jobs, app deploy, CI scaffold) are in progress in [#4](https://github.com/makigjuro/cloudstack-ai-plugins/issues/4). Today, Terraform modules for Container Apps are scaffolded with `add-terraform-module`.

The cloud topology diagram is in [docs/architecture.md](../../docs/architecture.md#cloud-infrastructure).

## Skills

| Skill | What it does |
|---|---|
| `/cloud-infra:infra-plan` | Plans infrastructure changes with dependency and risk analysis |
| `/cloud-infra:add-terraform-module redis` | Scaffolds a module (variables, main, outputs) and optional Terragrunt wiring |
| `/cloud-infra:add-helm-chart order-service` | AKS runtime: scaffolds a chart with standard templates and values |
| `/cloud-infra:infra-lint` | Runs `terraform validate`/`fmt`, `helm lint` and a trivy scan |
| `/cloud-infra:trivy-scan` | Scans Terraform and Helm for misconfigurations such as public access, weak TLS and broad IAM |
| `/cloud-infra:infra-apply dev --apply` | Shows the plan, then applies exactly that saved plan after you confirm |
| `/cloud-infra:complete-infra` | Lint + scan + review + PR for infrastructure-only branches |

**Agent:** `cloud-infra:infra-reviewer` reviews Terraform, Helm and CI for security, naming and best practice. `/dev-workflow:complete-task` runs it when infra files change.

**Convention skill:** `helm-chart-conventions`. Claude applies it automatically to chart files.

## Configuration

```json
{
  "infrastructure": {
    "terraformPath": "infra/terraform/modules",
    "terragruntPath": "infra/terragrunt",
    "chartsPath": "deploy/charts",
    "namespace": "my-project",
    "containerRegistry": "ghcr.io/my-org",
    "iacWrapper": "terragrunt",
    "cloud": "azure"
  }
}
```

| Key | Default | Notes |
|---|---|---|
| `infrastructure.terraformPath` | `infra/terraform/modules` | Terraform modules |
| `infrastructure.terragruntPath` | `infra/terragrunt` | per-environment configs |
| `infrastructure.chartsPath` | `deploy/charts` | Helm charts (AKS runtime) |
| `infrastructure.namespace` | project name | Kubernetes namespace (AKS runtime) |
| `infrastructure.containerRegistry` | from chart values | e.g. `ghcr.io/my-org` |
| `infrastructure.iacWrapper` | `none` | `terragrunt` or `none` |
| `infrastructure.cloud` | `azure` | `azure`, `aws`, `gcp` |

The defaults follow Azure conventions; `containerRegistry` defaults to ACR in the reference architecture. The templates are provider-agnostic, and the skills read your existing modules to match your naming and tagging on any cloud.

**Prerequisites:** `terraform`, `trivy`, `az` CLI, and `terragrunt` if you use it. `helm` is needed only for the AKS runtime.
