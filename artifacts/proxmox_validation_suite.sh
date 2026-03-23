#!/usr/bin/env bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export PGHOST="${PGHOST:-192.168.1.230}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-postgres}"
export VAULT_TOKEN="${VAULT_TOKEN:?VAULT_TOKEN is required}"

start_issue_ms="$(date +%s%3N)"
vault read -format=json database/creds/readonly-role > /tmp/val-creds.json
end_issue_ms="$(date +%s%3N)"

lease_id="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/val-creds.json'))['lease_id'])
PY
)"
db_user="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/val-creds.json'))['data']['username'])
PY
)"
db_pass="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/val-creds.json'))['data']['password'])
PY
)"
lease_ttl="$(python3 - <<'PY'
import json
print(json.load(open('/tmp/val-creds.json'))['lease_duration'])
PY
)"

issue_ms=$((end_issue_ms - start_issue_ms))

PGPASSWORD="$db_pass" psql -h "$PGHOST" -U "$db_user" -d "$PGDATABASE" -c "SELECT current_user;" >/tmp/val-pre.txt

start_revoke_ms="$(date +%s%3N)"
vault lease revoke -sync "$lease_id" >/tmp/val-revoke.txt
end_revoke_ms="$(date +%s%3N)"
revoke_ms=$((end_revoke_ms - start_revoke_ms))

set +e
PGPASSWORD="$db_pass" psql -h "$PGHOST" -U "$db_user" -d "$PGDATABASE" -c "SELECT 1;" >/tmp/val-post.txt 2>&1
post_rc=$?
set -e

role_exists="$(PGPASSWORD='tfm-vault-db-admin' psql -h "$PGHOST" -U postgres -d "$PGDATABASE" -tAc "SELECT 1 FROM pg_roles WHERE rolname='${db_user}';" | tr -d '[:space:]')"

# Negative test: token without DB policy should be denied
cat >/tmp/deny-policy.hcl <<'EOF'
path "sys/health" {
  capabilities = ["read"]
}
EOF
vault policy write deny-db /tmp/deny-policy.hcl >/dev/null
deny_token="$(vault token create -policy=deny-db -field=token)"

set +e
VAULT_TOKEN="$deny_token" vault read database/creds/readonly-role >/tmp/val-deny.txt 2>&1
deny_rc=$?
set -e

echo "issue_ms=$issue_ms"
echo "revoke_ms=$revoke_ms"
echo "lease_ttl_seconds=$lease_ttl"
echo "lease_id=$lease_id"
echo "db_user=$db_user"
echo "pre_revoke_query=ok"
if [[ $post_rc -ne 0 ]]; then
  echo "post_revoke_query=failed_expected"
else
  echo "post_revoke_query=unexpected_success"
fi
if [[ "$role_exists" == "1" ]]; then
  echo "post_revoke_role_exists=yes"
else
  echo "post_revoke_role_exists=no"
fi
if [[ $deny_rc -ne 0 ]]; then
  echo "unauthorized_token_access=denied_expected"
else
  echo "unauthorized_token_access=unexpected_allowed"
fi
