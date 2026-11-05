# Environment settings for dev. Read by root.hcl and every _envcommon file.

locals {
  environment            = "dev"
  aspnetcore_environment = "Development"

  # JWT validation for the APIs (Auth:Authority, Auth:Audience). An empty authority means the
  # Entra tenant you deploy with (ARM_TENANT_ID). The audience is the Application ID URI of the
  # API app registration (see infra/README.md, "Authentication").
  auth_authority = ""
  auth_audience  = "api://starter-api-dev"

  # Container Apps scaling (applies to orders and gateway)
  min_replicas = 0
  max_replicas = 2
  app_cpu      = 0.5
  app_memory   = "1Gi"

  # OTLP endpoint exported to every app as OTEL_EXPORTER_OTLP_ENDPOINT. Point it
  # at your collector (e.g. an internal otel-collector app or an
  # OTLP-capable backend). Empty = variable not set, apps skip OTLP export.
  otel_exporter_otlp_endpoint = ""

  # Networking
  vnet_address_space       = ["10.10.0.0/16"]
  aca_subnet_prefix        = "10.10.0.0/23"
  postgresql_subnet_prefix = "10.10.2.0/24"

  # PostgreSQL Flexible Server
  postgresql_sku_name                     = "B_Standard_B1ms"
  postgresql_storage_mb                   = 32768
  postgresql_backup_retention_days        = 7
  postgresql_geo_redundant_backup_enabled = false
  postgresql_high_availability_mode       = null

  # Key Vault
  key_vault_purge_protection_enabled = false
  # Public IPs/CIDRs (fixed operator/CI egress) allowed through the KV firewall. For a laptop or a
  # hosted runner, pass KEY_VAULT_ALLOWED_IPS at run time instead of committing the IP.
  key_vault_allowed_ip_addresses = []

  # Monitoring, frontend, registry, environment
  log_retention_in_days       = 30
  static_web_app_sku          = "Free"
  acr_sku                     = "Standard"
  cae_zone_redundancy_enabled = false

  # Principal IDs granted AcrPush (the CI OIDC service principal for dev).
  acr_push_principal_ids = []
}
