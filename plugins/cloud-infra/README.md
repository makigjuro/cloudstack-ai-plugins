# cloud-infra

**The cloud layer of the [cloudstack reference architecture](../../README.md).** It provisions and deploys the app with Terraform/Terragrunt and Helm on Azure/AKS. You see the plan before anything is applied.

```
/plugin install cloud-infra@cloudstack-ai-plugins
```

## The architecture it targets

- **Terraform modules** for cloud resources (database, cache, storage, AKS), wired per environment with Terragrunt.
- **One Helm chart per service**, using the release namespace, standard labels and resource limits.
- **GitHub Actions** for build, image push and deploy.
- **Security and review:** every change is linted, scanned with trivy and reviewed. Apply runs only on the plan you reviewed.

The cloud topology diagram is in [docs/architecture.md](../../docs/architecture.md#cloud-infrastructure).

## Skills

| Skill | What it does |
|---|---|
| `/cloud-infra:infra-plan` | Plans infrastructure changes with dependency and risk analysis |
| `/cloud-infra:add-terraform-module redis` | Scaffolds a module (variables, main, outputs) and optional Terragrunt wiring |
| `/cloud-infra:add-helm-chart order-service` | Scaffolds a chart with standard templates and values |
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
| `infrastructure.chartsPath` | `deploy/charts` | Helm charts |
| `infrastructure.namespace` | project name | Kubernetes namespace |
| `infrastructure.containerRegistry` | from chart values | e.g. `ghcr.io/my-org` |
| `infrastructure.iacWrapper` | `none` | `terragrunt` or `none` |
| `infrastructure.cloud` | `azure` | `azure`, `aws`, `gcp` |

The defaults follow Azure conventions. The templates are provider-agnostic, and the skills read your existing modules to match your naming and tagging on any cloud.

**Prerequisites:** `terraform`, `helm`, `trivy`, and `terragrunt` if you use it.
