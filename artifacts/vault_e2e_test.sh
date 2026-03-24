#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "[ERROR] VAULT_TOKEN es obligatorio." >&2
  exit 1
fi
export VAULT_TOKEN
export PGHOST="${PGHOST:-192.168.1.230}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-postgres}"

vault secrets enable -path=database database >/dev/null 2>&1 || true

vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles=readonly-role \
  connection_url="postgresql://{{username}}:{{password}}@${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=disable" \
  username=postgres \
  password='tfm-vault-db-admin' >/dev/null

vault write database/roles/readonly-role \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";GRANT USAGE ON SCHEMA public TO \"{{name}}\";GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  revocation_statements="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";REVOKE USAGE ON SCHEMA public FROM \"{{name}}\";REVOKE CONNECT ON DATABASE postgres FROM \"{{name}}\";DROP ROLE IF EXISTS \"{{name}}\";" \
  default_ttl=1m \
  max_ttl=5m >/dev/null

vault read -format=json database/creds/readonly-role > /tmp/vault-creds.json

lease_id="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/vault-creds.json'))['lease_id'])
PY
)"

db_user="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/vault-creds.json'))['data']['username'])
PY
)"

db_pass="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/vault-creds.json'))['data']['password'])
PY
)"

PGPASSWORD="$db_pass" psql -h "$PGHOST" -U "$db_user" -d "$PGDATABASE" -c "SELECT current_user;" >/tmp/vault-e2e-before.txt

set +e
vault lease revoke -sync "$lease_id" >/tmp/vault-lease-revoke.txt 2>&1
revoke_rc=$?
set -e

sleep 3

set +e
PGPASSWORD="$db_pass" psql -h "$PGHOST" -U "$db_user" -d "$PGDATABASE" -c "SELECT 1;" >/tmp/vault-e2e-after.txt 2>&1
rc=$?
set -e

role_exists="$(PGPASSWORD='tfm-vault-db-admin' psql -h "$PGHOST" -U postgres -d "$PGDATABASE" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${db_user}';" | tr -d '[:space:]')"

echo "lease_id=$lease_id"
echo "db_user=$db_user"
echo "pre_revoke_query=ok"
echo "revoke_rc=$revoke_rc"
echo "revoke_output=$(tr '\n' ' ' </tmp/vault-lease-revoke.txt | sed 's/  */ /g')"
if [[ $rc -ne 0 ]]; then
  echo "post_revoke_query=failed_expected"
else
  echo "post_revoke_query=unexpected_success"
fi
if [[ "$role_exists" == "1" ]]; then
  echo "post_revoke_role_exists=yes"
else
  echo "post_revoke_role_exists=no"
fi
