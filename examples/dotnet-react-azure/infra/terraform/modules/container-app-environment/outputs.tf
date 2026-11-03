output "id" {
  description = "Container Apps environment ID"
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Container Apps environment name"
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain of the environment; internal apps resolve at https://<app>.internal.<default_domain>"
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "Static IP of the environment's load balancer"
  value       = azurerm_container_app_environment.this.static_ip_address
}
