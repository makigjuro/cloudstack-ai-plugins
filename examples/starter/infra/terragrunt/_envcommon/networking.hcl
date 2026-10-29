# VNet, ACA + PostgreSQL delegated subnets, PostgreSQL private DNS.

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"
}

terraform {
  source = "${local.modules_dir}/networking"
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

inputs = {
  resource_group_name      = dependency.resource_group.outputs.name
  vnet_address_space       = local.env.vnet_address_space
  aca_subnet_prefix        = local.env.aca_subnet_prefix
  postgresql_subnet_prefix = local.env.postgresql_subnet_prefix
}
