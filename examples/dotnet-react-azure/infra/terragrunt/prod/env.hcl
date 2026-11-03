# Environment settings for prod. Read by root.hcl and every _envcommon file.

locals {
  environment            = "prod"
  aspnetcore_environment = "Production"

  # Container Apps scaling (applies to orders and gateway)
  min_replicas = 2
  max_replicas = 10
  app_cpu      = 1
  app_memory   = "2Gi"

  # OTLP endpoint exported to every app as OTEL_EXPORTER_OTLP_ENDPOINT. Point it
  # at your collector (e.g. an internal otel-collector app or an
  # OTLP-capable backend). Empty = variable not set, apps skip OTLP export.
  otel_exporter_otlp_endpoint = ""

  # Networking
  vnet_address_space       = ["10.30.0.0/16"]
  aca_subnet_prefix        = "10.30.0.0/23"
  postgresql_subnet_prefix = "10.30.2.0/24"

  # PostgreSQL Flexible Server
  postgresql_sku_name                     = "GP_Standard_D2ds_v5"
  postgresql_storage_mb                   = 131072
  postgresql_backup_retention_days        = 35
  postgresql_geo_redundant_backup_enabled = true
  postgresql_high_availability_mode       = "ZoneRedundant"

  # Key Vault
  key_vault_purge_protection_enabled = true
  # Public IPs/CIDRs (operators, CI egress) allowed through the KV firewall.
  key_vault_allowed_ip_addresses = []

  # Monitoring, frontend, registry, environment
  log_retention_in_days       = 90
  static_web_app_sku          = "Standard"
  acr_sku                     = "Premium"
  cae_zone_redundancy_enabled = true

  # Principal IDs granted AcrPush (the CI OIDC service principal for prod).
  acr_push_principal_ids = []
}
