---
name: infra-lint
description: Lint Terraform, Terragrunt, and Helm charts only — skips application and frontend checks. Use for infrastructure-only changes when /lint would be overkill.
allowed-tools: Bash
user-invocable: true
---

# Infrastructure Lint

Fast lint for infrastructure files only. Skips application and frontend checks.

## Arguments

- `--fix` or `fix` — Apply auto-fixes (formatting only)
- `terraform` — Only lint Terraform/Terragrunt
- `helm` — Only lint Helm charts

If no argument, lint both Terraform and Helm.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure. Derive `TF_PARENT` as the parent directory of `TF_PATH` (e.g., if `TF_PATH` is `infra/terraform/modules`, `TF_PARENT` is `infra`).

## Terraform / Terragrunt

**Format check:**
```bash
terraform fmt -check -recursive {TF_PARENT}
```

**Format fix (if `--fix`):**
```bash
terraform fmt -recursive {TF_PARENT}
```

**Validate modules:**
```bash
for dir in $(find {TF_PATH} -name "*.tf" -exec dirname {} \; | sort -u); do
  echo "=== Validating $dir ==="
  terraform -chdir="$dir" init -backend=false -input=false 2>/dev/null
  terraform -chdir="$dir" validate
done
```

**Terragrunt validate (only if `IAC_WRAPPER` = `terragrunt`):**
```bash
find {TG_PATH} -name "terragrunt.hcl" -execdir terragrunt validate \;
```

## Helm Charts

**Lint all charts:**
```bash
for chart in {CHARTS_PATH}/*/; do
  echo "=== Linting $chart ==="
  helm lint "$chart"
  helm template test "$chart" > /dev/null
done
```

If `{CHARTS_PATH}/` doesn't exist, skip Helm linting and note it.

## Security Scan

After lint passes, invoke the `trivy-scan` skill as the final verification step. This catches security misconfigurations that `terraform validate` and `helm lint` don't see (public access defaults, weak TLS, over-broad IAM, missing encryption).

```
Skill(skill="cloud-infra:trivy-scan")
```

Findings suppressed by a committed `.trivyignore` (with justifying comments) don't block — only unsuppressed CRITICAL/HIGH/MEDIUM fail the gate.

If trivy isn't installed, the skill prints the install command and exits non-zero. Treat that as a FAIL for this skill's output but print the install hint so the user can remediate.

## Output

Report pass/fail per category:
```
- Terraform Format: PASS/FAIL
- Terraform Validate: PASS/FAIL
- Terragrunt Validate: PASS/FAIL (or SKIPPED if IAC_WRAPPER != terragrunt)
- Helm Lint: PASS/FAIL (or SKIPPED)
- Helm Template: PASS/FAIL (or SKIPPED)
- Security Scan (trivy): PASS/FAIL (or SKIPPED if trivy missing)
```
