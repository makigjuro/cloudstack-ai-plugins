---
name: add-terraform-module
description: Scaffold a new Terraform module with variables, main, and outputs. Use when provisioning a new cloud resource (database, cache, storage, etc.) that needs its own Terraform module and optional IaC wrapper wiring.
allowed-tools: Write, Read, Glob, Grep
user-invocable: true
argument-hint: "{module-name}"
---

# Add Terraform Module

Scaffold a new Terraform module following project conventions.

## Arguments

- `{module-name}` — Name of the module (required, e.g., `redis`, `service-bus`, `postgresql`)
- `{description}` — What this module provisions (optional)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `TG_PATH` = `infrastructure.terragruntPath` (default: `infra/terragrunt`)
- `IAC_WRAPPER` = `infrastructure.iacWrapper` (default: `none`)
- `CLOUD` = `infrastructure.cloud` (default: `azure`)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

1. Read existing modules in `{TF_PATH}/` to follow established patterns.

2. Create the module directory:

```
{TF_PATH}/{module-name}/
├── variables.tf
├── main.tf
├── outputs.tf
```

3. **variables.tf** — Always include these standard variables:
```hcl
variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Cloud region (e.g. westeurope, us-east-1)"
  type        = string
}

variable "project" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

Add module-specific variables after the standard ones.

4. **main.tf** — Follow the naming convention from existing modules. Derive a location short code from the region (e.g., `westeurope` -> `weu`, `us-east-1` -> `use1`):
```hcl
locals {
  location_short = # derive from var.location or use a lookup map
  name           = "${var.project}-{resource-abbrev}-${var.environment}-${local.location_short}"
}
```

Scan existing modules to discover the project's established naming convention and location short mapping. Use that pattern.

5. **outputs.tf** — Export `name`, `id`, and any connection strings or keys needed by downstream modules.

6. **IaC Wrapper Wiring (conditional on `IAC_WRAPPER`):**

   **If `IAC_WRAPPER` = `terragrunt`:** Create Terragrunt wiring for the dev environment:

   ```
   {TG_PATH}/dev/{module-name}/
   └── terragrunt.hcl
   ```

   With content:
   ```hcl
   include "root" {
     path = find_in_parent_folders()
   }

   terraform {
     source = "../../../terraform/modules/{module-name}"
   }

   dependency "resource_group" {
     config_path = "../resource-group"
   }

   inputs = {
     resource_group_name = dependency.resource_group.outputs.name
   }
   ```

   Adjust the `source` path to be the correct relative path from `{TG_PATH}/dev/{module-name}/` to `{TF_PATH}/{module-name}`. Add additional dependencies based on what the module needs.

   **If `IAC_WRAPPER` = `none`:** Skip wrapper wiring. Note that the user can run `terraform plan` directly from the module directory.

## Output

After scaffolding, report:
```
## Scaffolded: {module-name} Terraform module

Files created:
- `{TF_PATH}/{module-name}/variables.tf`
- `{TF_PATH}/{module-name}/main.tf`
- `{TF_PATH}/{module-name}/outputs.tf`
- `{TG_PATH}/dev/{module-name}/terragrunt.hcl` (if IAC_WRAPPER = terragrunt)

Next: Add resource definitions in `main.tf`, then run `/infra-lint` to validate.
```

## Error Handling

- **Module directory already exists:** Warn the user and ask whether to overwrite or extend.
- **Terraform not installed:** Suggest installing with `brew install terraform`.
- **IaC wrapper root config not found:** If using Terragrunt, check that `{TG_PATH}/terragrunt.hcl` exists as the root config.

## After Scaffolding

Remind to:
- Add module-specific resource definitions in `main.tf`
- Add any needed dependencies in the wrapper config (if applicable)
- Run `/infra-lint` to validate
