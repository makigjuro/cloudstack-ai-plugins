---
name: lint
description: Run all linters and formatters -- dotnet format, ESLint, helm lint, and terraform validate. Use to verify formatting before a PR. Note that hooks auto-fix on save/commit; this skill is for explicit verification across the full codebase. For infrastructure-only changes, use /infra-lint instead.
allowed-tools: Bash
user-invocable: true
argument-hint: "[--fix]"
---

# Lint

Run all project linters and report violations. Optionally fix auto-fixable issues.

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract relevant fields:
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln`)
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Arguments

- `--fix` or `fix` -- Apply auto-fixes (default: report only)
- `backend` -- Only lint C# code
- `frontend` -- Only lint frontend code
- `helm` -- Only lint Helm charts
- `terraform` -- Only lint Terraform/Terragrunt code

If no argument is given, lint everything in report-only mode.

## Backend (.NET)

**Check formatting violations (report only):**
```bash
dotnet format {SOLUTION} --verify-no-changes --verbosity normal
```

**Fix formatting violations:**
```bash
dotnet format {SOLUTION} --verbosity normal
```

## Frontend (React/TypeScript)

**Check lint violations (report only):**
```bash
cd {FRONTEND_PATH} && npm run lint
```

**Fix auto-fixable violations:**
```bash
cd {FRONTEND_PATH} && npm run lint:fix
```

**Check TypeScript types:**
```bash
cd {FRONTEND_PATH} && npm run type-check
```

## Helm Charts

**Lint all charts in {CHARTS_PATH}/:**
```bash
# Discover and lint all charts
for chart in $(ls {CHARTS_PATH}/); do
  helm lint {CHARTS_PATH}/$chart
done
```

**Template render check (catches template errors without deploying):**
```bash
for chart in $(ls {CHARTS_PATH}/); do
  helm template test {CHARTS_PATH}/$chart > /dev/null
done
```

## Terraform / Terragrunt

Determine the Terraform root directory from `{TF_PATH}` (e.g., if `TF_PATH` is `infra/terraform/modules`, the root for format checks is `infra`).

**Validate Terraform modules:**
```bash
# Find all Terraform module directories and validate each
for dir in $(find {TF_ROOT} -name "*.tf" -exec dirname {} \; | sort -u); do
  echo "=== Validating $dir ==="
  terraform -chdir="$dir" init -backend=false -input=false 2>/dev/null
  terraform -chdir="$dir" validate
done
```

**Format check (report only):**
```bash
terraform fmt -check -recursive {TF_ROOT}
```

**Format fix:**
```bash
terraform fmt -recursive {TF_ROOT}
```

**Terragrunt validate (if terragrunt.hcl files exist):**
```bash
find {TF_ROOT} -name "terragrunt.hcl" -execdir terragrunt validate \;
```

## After Running

- Report the total violation count for each tool separately.
- For failures, show file path, line number (where available), and rule name.
- If running with `--fix`, report how many issues were auto-fixed and how many remain.
- If TypeScript type errors exist, list them separately from lint errors.
- Summarize with a pass/fail status per category:
  - .NET Format: PASS/FAIL
  - ESLint: PASS/FAIL
  - TypeScript: PASS/FAIL
  - Helm Lint: PASS/FAIL
  - Terraform Validate: PASS/FAIL
  - Terraform Format: PASS/FAIL
