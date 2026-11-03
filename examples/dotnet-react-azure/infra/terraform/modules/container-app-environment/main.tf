# Container Apps environment: workload-profiles environment with the
# Consumption profile (scale-to-zero, per-second billing), VNet-injected into
# the delegated ACA subnet and shipping logs to Log Analytics.

locals {
  name = "${var.project}-cae-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_container_app_environment" "this" {
  name                               = local.name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  log_analytics_workspace_id         = var.log_analytics_workspace_id
  infrastructure_subnet_id           = var.infrastructure_subnet_id
  internal_load_balancer_enabled     = var.internal_load_balancer_enabled
  zone_redundancy_enabled            = var.zone_redundancy_enabled
  infrastructure_resource_group_name = "${var.project}-rg-acainfra-${var.environment}-${var.location_short}"
  tags                               = local.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}
