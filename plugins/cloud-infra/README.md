# cloud-infra

A Claude Code plugin for cloud infrastructure management — Terraform modules, Helm charts, and CI/CD pipelines.

## What It Provides

### Skills

| Skill | Description |
|-------|-------------|
| `/add-terraform-module` | Scaffold a new Terraform module with variables, main, outputs, and optional IaC wrapper wiring |
| `/add-helm-chart` | Scaffold a new Helm chart with standard Kubernetes templates and values |
| `/infra-lint` | Lint Terraform and Helm charts only — fast, skips application/frontend checks. Runs `/trivy-scan` as its final step |
| `/trivy-scan` | Scan Terraform and Helm charts with [trivy](https://trivy.dev) for security misconfigurations (public access defaults, weak TLS, over-broad IAM). Honours `.trivyignore` with justifying comments |
| `/infra-apply` | Run `terraform plan` for review and optionally apply infrastructure changes |
| `/infra-plan` | Plan infrastructure changes with dependency analysis and risk assessment |
| `/complete-infra` | Full infrastructure completion workflow — parallel lint + security scan, review agent, and PR creation |

### Rules

| Rule | Scope |
|------|-------|
| `helm-charts` | Conventions for Helm chart structure, labels, namespaces, and resource definitions |

### Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `infra-reviewer` | Sonnet | Dedicated Terraform/Helm/CI review with security, naming, and best-practice checklists |

## Installation

Add to your project's `.claude/settings.json`:

```json
{
  "plugins": [
    "cloud-infra"
  ]
}
```

Or if using a local path:

```json
{
  "plugins": [
    { "path": "path/to/cloud-infra" }
  ]
}
```

## Configuration

Create a `cloudstack.json` in your project root to customize paths and settings:

```json
{
  "infrastructure": {
    "chartsPath": "deploy/charts",
    "terraformPath": "infra/terraform/modules",
    "terragruntPath": "infra/terragrunt",
    "namespace": "my-project",
    "containerRegistry": "ghcr.io/my-org",
    "iacWrapper": "terragrunt",
    "cloud": "azure"
  }
}
```

All fields are optional. The plugin auto-detects values by scanning your project structure when `cloudstack.json` is absent.

### Configuration Reference

| Key | Default | Description |
|-----|---------|-------------|
| `infrastructure.chartsPath` | `deploy/charts` | Path to Helm charts directory |
| `infrastructure.terraformPath` | `infra/terraform/modules` | Path to Terraform modules |
| `infrastructure.terragruntPath` | `infra/terragrunt` | Path to Terragrunt environment configs |
| `infrastructure.namespace` | Auto-detect or project name | Kubernetes namespace for deployments |
| `infrastructure.containerRegistry` | Auto-detect from chart values | Container image registry (e.g., `ghcr.io/my-org`) |
| `infrastructure.iacWrapper` | `none` | IaC wrapper tool: `terragrunt` or `none` |
| `infrastructure.cloud` | `azure` | Cloud provider: `azure`, `aws`, `gcp` |

## Supported IaC Wrappers

- **`none`** — Plain Terraform. Modules are planned/applied directly.
- **`terragrunt`** — Terragrunt manages backend config, environment separation, and dependency ordering. The plugin creates `terragrunt.hcl` wiring files alongside modules.

## Cloud Provider Notes

The plugin defaults to Azure conventions but the Terraform templates are provider-agnostic. When using AWS or GCP:
- Resource naming patterns may differ (no location short code, different abbreviations)
- Tagging conventions vary (`tags` for Azure/AWS, `labels` for GCP)
- The plugin scans existing modules to learn your project's conventions regardless of provider
