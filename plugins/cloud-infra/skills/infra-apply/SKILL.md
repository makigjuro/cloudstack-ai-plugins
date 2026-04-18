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
terragrunt run --all plan
```

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

**If `IAC_WRAPPER` = `terragrunt`:**

Single module:
```bash
cd {TG_PATH}/{environment}/{module}
terragrunt apply tfplan
```

All modules:
```bash
cd {TG_PATH}/{environment}
terragrunt run --all apply
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
- Clean up plan files after apply: `rm -f tfplan`
- For `--all` operations with Terragrunt, respect the dependency order defined in configs
