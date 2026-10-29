output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.this.name
}

output "aca_subnet_id" {
  description = "ID of the subnet delegated to Microsoft.App/environments"
  value       = azurerm_subnet.aca.id
}

output "postgresql_subnet_id" {
  description = "ID of the subnet delegated to PostgreSQL Flexible Server"
  # Depend on the NSG association so the server is never created into a
  # subnet whose NSG is still being attached.
  value      = azurerm_subnet_network_security_group_association.postgresql.subnet_id
  depends_on = [azurerm_subnet_network_security_group_association.postgresql]
}

output "postgresql_private_dns_zone_id" {
  description = "ID of the PostgreSQL private DNS zone (VNet link created before this output resolves)"
  value       = azurerm_private_dns_zone.postgresql.id
  depends_on  = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

output "postgresql_private_dns_zone_name" {
  description = "Name of the PostgreSQL private DNS zone"
  value       = azurerm_private_dns_zone.postgresql.name
}
