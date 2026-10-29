# orders service: internal ingress, DB connection string from Key Vault.
# image = <acr>/starter-orders:<IMAGE_TAG> (image_tag comes from root.hcl inputs).

locals {
  env         = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  modules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/../terraform/modules"

  # Only export OTEL_EXPORTER_OTLP_ENDPOINT when an endpoint is configured.
  otel_env = local.env.otel_exporter_otlp_endpoint == "" ? {} : {
    OTEL_EXPORTER_OTLP_ENDPOINT = local.env.otel_exporter_otlp_endpoint
  }
}

terraform {
  source = "${local.modules_dir}/container-app"
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

dependency "container_registry" {
  config_path = "${get_terragrunt_dir()}/../container-registry"

  mock_outputs = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.ContainerRegistry/registries/starteracrmockweu"
    name         = "starteracrmockweu"
    login_server = "starteracrmockweu.azurecr.io"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "postgresql" {
  config_path = "${get_terragrunt_dir()}/../postgresql"

  mock_outputs = {
    id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.DBforPostgreSQL/flexibleServers/starter-psql-mock-weu"
    name                          = "starter-psql-mock-weu"
    fqdn                          = "starter-psql-mock-weu.postgres.database.azure.com"
    database_name                 = "starter"
    connection_string_secret_name = "orders-db-connection"
    connection_string_secret_id   = "https://starter-kv-mock-weu.vault.azure.net/secrets/orders-db-connection"
    admin_password_secret_id      = "https://starter-kv-mock-weu.vault.azure.net/secrets/postgres-admin-password"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "container_app_environment" {
  config_path = "${get_terragrunt_dir()}/../container-app-environment"

  mock_outputs = {
    id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.App/managedEnvironments/starter-cae-mock-weu"
    name              = "starter-cae-mock-weu"
    default_domain    = "mock-12345678.westeurope.azurecontainerapps.io"
    static_ip_address = "10.0.0.4"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  app_name                     = "orders"
  resource_group_name          = dependency.resource_group.outputs.name
  container_app_environment_id = dependency.container_app_environment.outputs.id
  managed_identity_id          = dependency.managed_identity.outputs.id
  registry_server              = dependency.container_registry.outputs.login_server
  image_repository             = "starter-orders"

  ingress_external = false
  target_port      = 8080
  min_replicas     = local.env.min_replicas
  max_replicas     = local.env.max_replicas
  cpu              = local.env.app_cpu
  memory           = local.env.app_memory

  key_vault_secrets = {
    "orders-db-connection" = dependency.postgresql.outputs.connection_string_secret_id
  }
  secret_env_vars = {
    ConnectionStrings__Orders = "orders-db-connection"
  }
  env_vars = merge({
    ASPNETCORE_ENVIRONMENT = local.env.aspnetcore_environment
    OTEL_SERVICE_NAME      = "orders"
    AZURE_CLIENT_ID        = dependency.managed_identity.outputs.client_id
  }, local.otel_env)
}
