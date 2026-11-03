# VNet for one environment:
#   - snet-aca:        delegated to Microsoft.App/environments (Container Apps
#                      environment is VNet-injected here). Carries the
#                      Microsoft.KeyVault service endpoint so the Key Vault
#                      firewall can allow it.
#   - snet-postgresql: delegated to PostgreSQL Flexible Server (private access),
#                      NSG allows 5432 only from the ACA subnet.
#   - Private DNS zone for the Flexible Server, linked to the VNet.

locals {
  vnet_name = "${var.project}-vnet-${var.environment}-${var.location_short}"
  tags = merge({
    project      = var.project
    environment  = var.environment
    "managed-by" = "terraform"
  }, var.tags)
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

# --- Container Apps infrastructure subnet ---

# No NSG is attached: the gateway's external ingress needs inbound 80/443 from
# the internet on this subnet and the ACA platform manages the remaining
# required flows. Internal apps are only reachable through the environment's
# internal ingress, never directly.
resource "azurerm_subnet" "aca" {
  name                 = "snet-aca"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aca_subnet_prefix]
  service_endpoints    = ["Microsoft.KeyVault"]

  delegation {
    name = "aca-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# --- PostgreSQL delegated subnet ---

resource "azurerm_subnet" "postgresql" {
  name                 = "snet-postgresql"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.postgresql_subnet_prefix]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "postgresql" {
  name                = "${var.project}-nsg-psql-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "postgresql_allow_aca" {
  name                        = "AllowAcaToPostgreSQL"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aca_subnet_prefix
  destination_address_prefix  = var.postgresql_subnet_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.postgresql.name
}

resource "azurerm_network_security_rule" "postgresql_deny_vnet" {
  name                        = "DenyOtherVnetInbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.postgresql.name
}

resource "azurerm_subnet_network_security_group_association" "postgresql" {
  subnet_id                 = azurerm_subnet.postgresql.id
  network_security_group_id = azurerm_network_security_group.postgresql.id
}

# --- Private DNS for PostgreSQL Flexible Server (private access) ---

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.project}-${var.environment}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${local.vnet_name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}
