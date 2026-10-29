# Azure Container Registry; identity gets AcrPull, CI principals AcrPush.

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"
}

terraform {
  source = "${local.modules_dir}/container-registry"
}

dependency "resource_group" {
  config_path = "${get_terragrunt_dir()}/../resource-group"

  mock_outputs = {
    name     = "starter-rg-mock-weu"
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu"
    location = "westeurope"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "managed_identity" {
  config_path = "${get_terragrunt_dir()}/../managed-identity"

  mock_outputs = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.ManagedIdentity/userAssignedIdentities/starter-id-mock-weu"
    name         = "starter-id-mock-weu"
    principal_id = "00000000-0000-0000-0000-000000000001"
    client_id    = "00000000-0000-0000-0000-000000000002"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  sku                 = local.env.acr_sku
  pull_principal_id   = dependency.managed_identity.outputs.principal_id
  push_principal_ids  = local.env.acr_push_principal_ids
}
