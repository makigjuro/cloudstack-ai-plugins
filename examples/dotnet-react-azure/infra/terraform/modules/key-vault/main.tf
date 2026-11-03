# Key Vault (RBAC authorization) for application secrets.
#
#   - The workload identity gets "Key Vault Secrets User" (read only) so
#     Container Apps can resolve Key Vault secret references at runtime.
#   - The principal running Terraform (CI via OIDC, or an operator) gets
#     "Key Vault Secrets Officer" so units such as postgresql can write the
#     secrets they generate. No secret is ever created out of band.
#   - Firewall defaults to Deny, allowing the ACA subnet (service endpoint),
#     trusted Azure services and any explicitly listed IPs.

data "azurerm_client_config" "current" {}

locals {
  name = "${var.project}-kv-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_key_vault" "this" {
  name                          = local.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = true

  network_acls {
    default_action             = var.network_default_action
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_addresses
  }

  # CI runner / operator IPs are ephemeral and added out of band
  # (`az keyvault network-rule add`) around an apply. Terraform must not strip
  # them mid-run, or later units lose data-plane access.
  lifecycle {
    ignore_changes = [network_acls[0].ip_rules]

    precondition {
      condition     = length(local.name) <= 24
      error_message = "Key Vault name '${local.name}' exceeds the 24 character limit; shorten project or location_short."
    }
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "workload_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.secrets_user_principal_id
  principal_type       = "ServicePrincipal"
}

# Azure RBAC is eventually consistent; without a pause the first secret write
# (or the first Container App secret resolution) can fail with 403.
resource "time_sleep" "rbac_propagation" {
  create_duration = var.rbac_propagation_wait

  triggers = {
    deployer = azurerm_role_assignment.deployer_secrets_officer.id
    workload = azurerm_role_assignment.workload_secrets_user.id
  }
}
