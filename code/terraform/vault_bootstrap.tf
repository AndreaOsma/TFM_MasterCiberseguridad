locals {
  postgres_host = split("/", var.lab_ipv4.postgres)[0]
}

resource "vault_mount" "database" {
  count = var.enable_vault_bootstrap ? 1 : 0

  path        = "database"
  type        = "database"
  description = "Database secrets engine para emision dinamica de credenciales PostgreSQL"
}

resource "vault_database_secret_backend_connection" "postgres" {
  count = var.enable_vault_bootstrap ? 1 : 0

  backend       = vault_mount.database[0].path
  name          = "postgres"
  allowed_roles = ["readonly-role"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${local.postgres_host}:5432/postgres?sslmode=disable"
    username       = var.vault_db_admin_username
    password       = var.vault_db_admin_password
  }
}

resource "vault_database_secret_backend_role" "readonly" {
  count = var.enable_vault_bootstrap ? 1 : 0

  backend = vault_mount.database[0].path
  name    = "readonly-role"
  db_name = vault_database_secret_backend_connection.postgres[0].name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";",
    "GRANT USAGE ON SCHEMA public TO \"{{name}}\";",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]

  revocation_statements = [
    "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";",
    "REVOKE USAGE ON SCHEMA public FROM \"{{name}}\";",
    "REVOKE CONNECT ON DATABASE postgres FROM \"{{name}}\";",
    "DROP ROLE IF EXISTS \"{{name}}\";"
  ]

  default_ttl = 300
  max_ttl     = 900
}

resource "vault_policy" "ci_dynamic_db_read" {
  count = var.enable_vault_bootstrap ? 1 : 0

  name = "ci-dynamic-db-read"

  policy = <<EOT
path "database/creds/readonly-role" {
  capabilities = ["read"]
}
EOT
}
