# Key Vault (RBAC); identity gets Secrets User, deployer gets Secrets Officer.

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"
}

terraform {
  source = "${local.modules_dir}/key-vault"
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
  resource_group_name       = dependency.resource_group.outputs.name
  secrets_user_principal_id = dependency.managed_identity.outputs.principal_id
  allowed_subnet_ids        = [dependency.networking.outputs.aca_subnet_id]
  allowed_ip_addresses      = local.env.key_vault_allowed_ip_addresses
  purge_protection_enabled  = local.env.key_vault_purge_protection_enabled
}
