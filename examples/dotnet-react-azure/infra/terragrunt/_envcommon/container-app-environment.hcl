# Container Apps environment (Consumption workload profile, VNet-injected).

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"
}

terraform {
  source = "${local.modules_dir}/container-app-environment"
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

dependency "networking" {
  config_path = "${get_terragrunt_dir()}/../networking"

  mock_outputs = {
    vnet_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.Network/virtualNetworks/starter-vnet-mock-weu"
    vnet_name                        = "starter-vnet-mock-weu"
    aca_subnet_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.Network/virtualNetworks/starter-vnet-mock-weu/subnets/snet-aca"
    postgresql_subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.Network/virtualNetworks/starter-vnet-mock-weu/subnets/snet-postgresql"
    postgresql_private_dns_zone_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.Network/privateDnsZones/starter-mock.private.postgres.database.azure.com"
    postgresql_private_dns_zone_name = "starter-mock.private.postgres.database.azure.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "monitoring" {
  config_path = "${get_terragrunt_dir()}/../monitoring"

  mock_outputs = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.OperationalInsights/workspaces/starter-log-mock-weu"
    name         = "starter-log-mock-weu"
    workspace_id = "00000000-0000-0000-0000-000000000003"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  resource_group_name        = dependency.resource_group.outputs.name
  log_analytics_workspace_id = dependency.monitoring.outputs.id
  infrastructure_subnet_id   = dependency.networking.outputs.aca_subnet_id
  zone_redundancy_enabled    = local.env.cae_zone_redundancy_enabled
}
