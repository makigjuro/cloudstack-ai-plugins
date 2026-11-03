# Root Terragrunt configuration for the starter reference app.
# Every unit includes this file (include "root") plus its _envcommon/<unit>.hcl.
#
# Credentials are never stored here: the azurerm provider and backend read
# ARM_SUBSCRIPTION_ID / ARM_TENANT_ID / ARM_CLIENT_ID (+ ARM_USE_OIDC=true in CI)
# from the environment.

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  project        = "starter"
  location       = "westeurope"
  location_short = "weu"
  environment    = local.env_vars.locals.environment

  # Immutable image tag (git SHA) for the app and job units. Read once here and
  # passed to every unit as `image_tag`; modules that do not declare it ignore
  # it, and the container-app / container-app-job modules reject empty or
  # "latest" with a clear error at plan/apply time.
  image_tag = get_env("IMAGE_TAG", get_env("TF_VAR_image_tag", ""))

  # Offline mode swaps the azurerm backend for a throwaway local backend so
  # `terragrunt run --all validate` works without Azure credentials (dependency
  # outputs then fall back to mock_outputs). It is on when TG_OFFLINE=true or
  # when ARM_SUBSCRIPTION_ID is unset (Azure is unreachable without it anyway).
  # The decision must not depend on the command: Terragrunt fetches dependency
  # outputs with `output`, which has to see the same backend as `validate`.
  # plan/apply/destroy are refused in offline mode by the hook below.
  offline = get_env("TG_OFFLINE", "false") == "true" || get_env("ARM_SUBSCRIPTION_ID", "") == ""

  # Per-environment state storage, created by scripts/bootstrap-state.sh.
  state_resource_group_name  = "${local.project}-rg-tfstate-${local.environment}-${local.location_short}"
  state_storage_account_name = "${local.project}tfstate${local.environment}${local.location_short}"

  azurerm_backend = {
    resource_group_name  = local.state_resource_group_name
    storage_account_name = local.state_storage_account_name
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_azuread_auth     = true
  }

  local_backend = {
    path = "${get_terragrunt_dir()}/.terragrunt-offline/terraform.tfstate"
  }

  common_tags = {
    project      = local.project
    environment  = local.environment
    "managed-by" = "terragrunt"
  }
}

# Use the Terraform CLI (Terragrunt >= 0.8x defaults to OpenTofu).
terraform_binary = get_env("TG_TF_PATH", "terraform")

terraform {
  before_hook "refuse_offline_state_changes" {
    commands = ["plan", "apply", "destroy", "import", "refresh", "state"]
    execute = local.offline ? [
      "sh", "-c",
      "echo 'ERROR: offline mode (ARM_SUBSCRIPTION_ID unset or TG_OFFLINE=true) uses a throwaway local backend; export ARM_SUBSCRIPTION_ID and authenticate to Azure before plan/apply.' >&2; exit 1"
    ] : ["true"]
  }
}

remote_state {
  # jsonencode/jsondecode keeps both branches the same type for HCL.
  backend = local.offline ? "local" : "azurerm"
  config  = jsondecode(local.offline ? jsonencode(local.local_backend) : jsonencode(local.azurerm_backend))

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Modules pin terraform/azurerm versions in their own versions.tf; only the
# provider configuration is generated here.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      storage_use_azuread = true

      features {
        key_vault {
          purge_soft_delete_on_destroy    = false
          recover_soft_deleted_key_vaults = true
        }
        resource_group {
          prevent_deletion_if_contains_resources = true
        }
      }
    }
  EOF
}

inputs = {
  project        = local.project
  environment    = local.environment
  location       = local.location
  location_short = local.location_short
  tags           = local.common_tags
  image_tag      = local.image_tag
}
