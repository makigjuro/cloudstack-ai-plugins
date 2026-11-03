---
name: lint
description: Run all linters and formatters -- dotnet format, ESLint, terraform/terragrunt validate, and helm lint (AKS only). Use to verify formatting before a PR. Note that hooks auto-fix on save/commit; this skill is for explicit verification across the full codebase. For infrastructure-only changes, use /infra-lint instead.
allowed-tools: Bash
user-invocable: true
argument-hint: "[--fix]"
---

# Lint

Run all project linters and report violations. Optionally fix auto-fixable issues.

## Configuration

Read `blueprint.json` from the project root at the start of execution. Extract relevant fields:
- `SOLUTION` = `backend.solutionPath` (default: find `*.sln`)
- `FRONTEND_PATH` = `frontend.path` (default: `web`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `RUNTIME` = `infrastructure.runtime` (default: `container-apps`)
- `ENVIRONMENTS` = `infrastructure.containerApps.environments` (default: `dev staging prod`)

If `blueprint.json` does not exist, auto-detect by scanning the project structure.

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

Only when `RUNTIME` is `aks` or `{CHARTS_PATH}/` exists — Container Apps projects have no charts, so report Helm as SKIPPED.

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

**Terragrunt format + validate (if `{TG_PATH}/` exists):**
```bash
(cd {TG_PATH} && terragrunt hcl format --check)   # drop --check with --fix
for env in {ENVIRONMENTS}; do
  [ -d "{TG_PATH}/$env" ] || continue
  (cd "{TG_PATH}/$env" && IMAGE_TAG="${IMAGE_TAG:-0000000}" terragrunt run --all validate --provider-cache)
done
```
The placeholder `IMAGE_TAG` only satisfies the required image-tag input; without Azure credentials units validate against `mock_outputs`.

## After Running

- Report the total violation count for each tool separately.
- For failures, show file path, line number (where available), and rule name.
- If running with `--fix`, report how many issues were auto-fixed and how many remain.
- If TypeScript type errors exist, list them separately from lint errors.
- Summarize with a pass/fail status per category:
  - .NET Format: PASS/FAIL
  - ESLint: PASS/FAIL
  - TypeScript: PASS/FAIL
  - Helm Lint: PASS/FAIL/SKIPPED
  - Terraform Validate: PASS/FAIL
  - Terraform Format: PASS/FAIL
  - Terragrunt Validate: PASS/FAIL/SKIPPED
