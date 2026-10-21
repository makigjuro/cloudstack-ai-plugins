---
name: infra-apply
description: Run terraform plan for review and optionally apply infrastructure changes. Use when the user wants to preview or deploy infrastructure — always shows the plan before any apply.
allowed-tools: Bash, Read, Glob
user-invocable: true
argument-hint: "[environment] [module] [--apply]"
---

# Infrastructure Apply

Generate a Terraform plan for review. Optionally apply after user confirmation.

## Arguments

- `{environment}` — Target environment (e.g., `dev`, `staging`, `prod`). Default: `dev`
- `{module}` — Specific module to plan (e.g., `aks-cluster`, `postgresql`). If omitted, plan all.
- `--apply` — Apply after showing the plan (requires explicit user confirmation)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Validate First

Run `/infra-lint terraform` to ensure all modules are valid before planning.

### Step 2: Generate Plan

**If `IAC_WRAPPER` = `terragrunt`:**

Single module:
```bash
cd {TG_PATH}/{environment}/{module}
terragrunt plan -out=tfplan
```

All modules:
```bash
cd {TG_PATH}/{environment}
terragrunt run --all plan -out=tfplan
```

With `run --all`, the `tfplan` file is written separately inside each module's directory (or its `.terragrunt-cache` working dir).

**If `IAC_WRAPPER` = `none` (plain Terraform):**

Single module:
```bash
cd {TF_PATH}/{module}
terraform plan -var="environment={environment}" -out=tfplan
```

All modules — iterate over each module directory:
```bash
for dir in {TF_PATH}/*/; do
  echo "=== Planning $(basename $dir) ==="
  terraform -chdir="$dir" plan -var="environment={environment}" -out=tfplan
done
```

Note: With plain Terraform, you may need to pass additional `-var-file` or `-backend-config` flags depending on the project setup. Check for `{environment}.tfvars` files.

### Step 3: Review Plan Output

Display the plan summary:
- Resources to add
- Resources to change
- Resources to destroy

**CRITICAL:** If any resources will be **destroyed**, highlight this prominently and require explicit user confirmation before proceeding.

### Step 4: Apply (only if `--apply` and user confirms)

Apply exactly the plan reviewed in Step 3 by applying the saved `tfplan` file — never run a fresh `apply` without a plan file. If the code, variables, or remote state changed since planning (or Terraform reports the saved plan is stale), STOP and re-run Step 2 so the user reviews the new plan before applying.

**If `IAC_WRAPPER` = `terragrunt`:**

Single module:
```bash
cd {TG_PATH}/{environment}/{module}
terragrunt apply tfplan
```

All modules:
```bash
cd {TG_PATH}/{environment}
terragrunt run --all apply tfplan
```

**If `IAC_WRAPPER` = `none`:**

Single module:
```bash
cd {TF_PATH}/{module}
terraform apply tfplan
```

All modules:
```bash
for dir in {TF_PATH}/*/; do
  terraform -chdir="$dir" apply tfplan
done
```

## Safety Rules

- NEVER apply to `prod` without showing the plan first and getting explicit user confirmation
- ALWAYS run plan before apply
- If the plan shows unexpected destroys, STOP and ask the user
- Apply only the saved `tfplan` from the reviewed plan; if it is stale, re-plan and re-confirm
- Clean up plan files after apply: `rm -f tfplan` (for `--all` runs, remove the per-module `tfplan` files)
- For `--all` operations with Terragrunt, respect the dependency order defined in configs
