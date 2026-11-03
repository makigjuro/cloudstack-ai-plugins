output "id" {
  description = "Container App resource ID"
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Container App name"
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "Ingress FQDN (internal apps: <name>.internal.<environment default domain>)"
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "latest_revision_name" {
  description = "Name of the latest revision (changes on every new image tag)"
  value       = azurerm_container_app.this.latest_revision_name
}

output "image" {
  description = "Fully qualified image deployed in the latest revision"
  value       = local.image
}
