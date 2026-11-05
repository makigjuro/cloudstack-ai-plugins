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

Read `blueprint.json` from the project root at the start of execution. Extract:
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)

If `blueprint.json` does not exist, auto-detect by scanning the project structure.

## Process

### Step 1: Validate First

Run `/infra-lint terraform` to ensure all modules are valid before planning.

### Step 2: Generate Plan

**If `IAC_WRAPPER` = `terragrunt`:**

Single module:
```bash
cd {TG_PATH}/{environment}/{module}
terragrunt plan -input=false -out=tfplan
```

All modules:
```bash
cd {TG_PATH}/{environment}
terragrunt run --all --non-interactive plan -- -input=false -out=tfplan 2>&1 | tee /tmp/tg-plan-{environment}.log
```

With `run --all`, Terraform flags go after `--` (Terragrunt 0.93+ rejects `run --all plan -out=tfplan`), and each module gets its own `tfplan` inside its `.terragrunt-cache` working dir.

**Mock outputs (new or partly applied environments).** A module whose dependency has no state yet is planned with that dependency's `mock_outputs`. Terragrunt logs `has no outputs, but mock outputs provided` for it. Such a plan points at placeholder resources, so it must never be applied: in a new environment it fails with 404s against names like `*-mock-*`. Check every module's plan:
```bash
grep -c "mock outputs provided" /tmp/tg-plan-{environment}.log
# per module: count mock values in the saved plan (mock values in this architecture contain "mock")
(cd {TG_PATH}/{environment}/{module} && terragrunt show -json tfplan | grep -ci mock)
```
If any module's plan uses mock values, switch to **waves**:
1. A wave is the set of modules whose plans have no mock values. Their dependencies all exist already.
2. Show that wave's plans for review, then apply them one module at a time (Step 4, single module), in the order Terragrunt printed (`Unit queue will be processed for plan in this order`).
3. Plan the remaining modules again. They now see real outputs from the wave just applied. Show the new plans, and repeat until none remain.

**Key Vault firewall.** When Terraform writes Key Vault secrets (the reference architecture's `postgresql` module does), the machine running it must be allowed through the vault firewall. The reference starter reads extra IPs from `KEY_VAULT_ALLOWED_IPS`. Export it with the runner's IPv4 (`curl -4 -s ifconfig.me`; Key Vault rules don't accept IPv6) before planning the key-vault module, rather than committing the IP to `env.hcl`.

Every wave's plans are new plans, so review and confirm each wave. If `terragrunt show -json tfplan` prints nothing for a module, treat that plan as unchecked, not clean. Tell the user why waves were needed. For Container Apps, the app and job modules (`containerApps` in `blueprint.json`) are rolled out by `/cloud-infra:deploy`, not here, because they need images in the registry first.

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
terragrunt apply -input=false tfplan
```

All modules (only when no plan uses mock values, see Step 2):
```bash
cd {TG_PATH}/{environment}
terragrunt run --all --non-interactive apply -- tfplan
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
