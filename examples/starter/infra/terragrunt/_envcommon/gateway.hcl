# gateway (YARP): the ONLY external ingress. Routes to orders over the
# environment's internal domain and allows the Static Web App origin for CORS.

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

dependency "orders" {
  config_path = "${get_terragrunt_dir()}/../orders"

  mock_outputs = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.App/containerApps/starter-ca-orders-mock-weu"
    name                 = "starter-ca-orders-mock-weu"
    fqdn                 = "starter-ca-orders-mock-weu.internal.mock-12345678.westeurope.azurecontainerapps.io"
    latest_revision_name = "starter-ca-orders-mock-weu--0000000"
    image                = "starteracrmockweu.azurecr.io/starter-orders:mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "static_web_app" {
  config_path = "${get_terragrunt_dir()}/../static-web-app"

  mock_outputs = {
    id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/starter-rg-mock-weu/providers/Microsoft.Web/staticSites/starter-swa-mock-weu"
    name              = "starter-swa-mock-weu"
    default_host_name = "mock-swa-123.azurestaticapps.net"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  app_name                     = "gateway"
  resource_group_name          = dependency.resource_group.outputs.name
  container_app_environment_id = dependency.container_app_environment.outputs.id
  managed_identity_id          = dependency.managed_identity.outputs.id
  registry_server              = dependency.container_registry.outputs.login_server
  image_repository             = "starter-gateway"

  ingress_external = true
  target_port      = 8080
  min_replicas     = local.env.min_replicas
  max_replicas     = local.env.max_replicas
  cpu              = local.env.app_cpu
  memory           = local.env.app_memory

  env_vars = merge({
    ASPNETCORE_ENVIRONMENT                                    = local.env.aspnetcore_environment
    OTEL_SERVICE_NAME                                         = "gateway"
    ReverseProxy__Clusters__orders__Destinations__d1__Address = "https://${dependency.orders.outputs.name}.internal.${dependency.container_app_environment.outputs.default_domain}"
    Cors__AllowedOrigins__0                                   = "https://${dependency.static_web_app.outputs.default_host_name}"
  }, local.otel_env)
}
