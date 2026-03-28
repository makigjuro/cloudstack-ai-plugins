---
name: infra-plan
description: Plan infrastructure changes — Terraform modules, Helm charts, CI/CD pipelines. Use when the user wants to add or modify cloud infrastructure, Kubernetes resources, or deployment pipelines.
allowed-tools: Read, Glob, Grep, Task
user-invocable: true
---

# Infrastructure Plan

Break down an infrastructure change into implementation tasks. This is the infra equivalent of a feature planning skill.

## Arguments

- `{description}` — What infrastructure change is needed (required)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `K8S_NAMESPACE` = `infrastructure.namespace` (default: detect from existing charts or use project name)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)
- `CLOUD` = `infrastructure.cloud` (default: `azure`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

1. **Understand the request** — Parse what the user wants to change (new module, modify existing, add chart, change CI/CD)

2. **Analyze current state** — Read relevant files:
   - `{TF_PATH}/` — existing Terraform modules
   - `{TG_PATH}/` — environment configurations and dependencies (if using Terragrunt)
   - `{CHARTS_PATH}/` — existing Helm charts
   - `.github/workflows/` — CI/CD pipelines

3. **Identify scope** — Categorize the change:
   - **Terraform:** New module, modify module, add environment, change dependencies
   - **Helm:** New chart, modify templates, add values overlay
   - **CI/CD:** New workflow, modify pipeline, add environment gate
   - **Cross-cutting:** Changes spanning multiple categories

4. **Map dependencies** — If using Terragrunt, modules have ordering constraints via dependencies. For plain Terraform, check for module references. Identify:
   - Which modules depend on this change
   - Which modules this change depends on
   - Whether new IaC wrapper wiring is needed

5. **Create plan** — Output a structured plan:

```markdown
## Infrastructure Change Plan

### Summary
{one-line description}

### Category
Terraform | Helm | CI/CD | Cross-cutting

### Changes Required

#### {Category 1}
1. {task} — {file or directory affected}
2. {task} — {file or directory affected}

#### {Category 2} (if cross-cutting)
1. {task} — {file or directory affected}

### Dependency Order
{execution order considering module dependencies}

### Validation Steps
- [ ] `terraform validate` passes for affected modules
- [ ] `terraform fmt -check` passes
- [ ] IaC wrapper validates (if applicable)
- [ ] `helm lint` passes (if charts changed)
- [ ] `helm template` renders without errors (if charts changed)

### Risk Assessment
- Blast radius: {low/medium/high}
- Reversibility: {easy/hard}
- Requires `terraform plan` review: {yes/no}
```

## Guidelines

- Always check module dependency graph before suggesting changes
- Flag any changes that affect production environments
- Prefer modifying existing modules over creating new ones when the change is small
- For new cloud resources, check if an existing module can be extended first
