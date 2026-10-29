output "id" {
  description = "Container App Job resource ID"
  value       = azurerm_container_app_job.this.id
}

output "name" {
  description = "Container App Job name (used by `az containerapp job start`)"
  value       = azurerm_container_app_job.this.name
}

output "image" {
  description = "Fully qualified image the job runs"
  value       = local.image
}
