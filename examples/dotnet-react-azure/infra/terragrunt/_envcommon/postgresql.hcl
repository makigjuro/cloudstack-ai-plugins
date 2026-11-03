# PostgreSQL Flexible Server (private access); password + connection string go to Key Vault.

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"
}

terraform {
  source = "${local.modules_dir}/postgresql"
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

dependency "key_vault" {
  config_path = "${get_terragrunt_dir()}/../key-vault"

  mock_outputs = {
    id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.KeyVault/vaults/starter-kv-mock-weu"
    name      = "starter-kv-mock-weu"
    vault_uri = "https://starter-kv-mock-weu.vault.azure.net/"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  resource_group_name           = dependency.resource_group.outputs.name
  delegated_subnet_id           = dependency.networking.outputs.postgresql_subnet_id
  private_dns_zone_id           = dependency.networking.outputs.postgresql_private_dns_zone_id
  key_vault_id                  = dependency.key_vault.outputs.id
  sku_name                      = local.env.postgresql_sku_name
  storage_mb                    = local.env.postgresql_storage_mb
  backup_retention_days         = local.env.postgresql_backup_retention_days
  geo_redundant_backup_enabled  = local.env.postgresql_geo_redundant_backup_enabled
  high_availability_mode        = local.env.postgresql_high_availability_mode
  database_name                 = "starter"
  connection_string_secret_name = "orders-db-connection"
}
