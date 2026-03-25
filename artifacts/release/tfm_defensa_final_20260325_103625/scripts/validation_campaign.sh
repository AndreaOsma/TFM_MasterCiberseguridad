#!/usr/bin/env bash
set -euo pipefail

# Ejecuta ejecuciones repetidas de la batería de hipótesis y consolida métricas.
#
# Uso local:
#   VAULT_TOKEN=... bash artifacts/scripts/validation_campaign.sh
#
# Uso remoto (ejemplo):
#   VAULT_TOKEN=... RUN_COMMAND='ssh tfm-test@proxmox "cd ~/TFM_MasterCiberseguridad && bash artifacts/scripts/proxmox_validation_suite.sh"' \
#   bash artifacts/scripts/validation_campaign.sh
#
# Variables opcionales:
#   RUNS=10
#   RUN_COMMAND="bash artifacts/scripts/proxmox_validation_suite.sh"
#   OUT_DIR=artifacts/validation/campaign
#   SLEEP_BETWEEN_RUNS=1

RUNS="${RUNS:-10}"
RUN_COMMAND="${RUN_COMMAND:-bash artifacts/scripts/proxmox_validation_suite.sh}"
OUT_DIR="${OUT_DIR:-artifacts/validation/campaign}"
SLEEP_BETWEEN_RUNS="${SLEEP_BETWEEN_RUNS:-1}"

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "[ERROR] RUNS debe ser un entero >= 1." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ERROR] python3 no está disponible." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
METRICS_TSV="$OUT_DIR/metrics.tsv"
SUMMARY_TXT="$OUT_DIR/summary.txt"
RAW_DIR="$OUT_DIR/runs"
mkdir -p "$RAW_DIR"

echo -e "run\tissue_ms\trevoke_ms\tlease_ttl_seconds\tttl_within_expected_window\trevocation_effective\tunauthorized_access_blocked\thypothesis_overall" > "$METRICS_TSV"

extract_kv() {
  local key="$1"
  local file="$2"
  local value
  value="$(awk -F= -v k="$key" '$1==k{print $2; exit}' "$file")"
  printf "%s" "${value:-na}"
}

echo "[INFO] Iniciando campaña con $RUNS ejecuciones..."
for i in $(seq 1 "$RUNS"); do
  run_out="$RAW_DIR/run_${i}.txt"
  echo "[INFO] Ejecución $i/$RUNS"

  set +e
  bash -lc "$RUN_COMMAND" >"$run_out" 2>&1
  rc=$?
  set -e

  issue_ms="$(extract_kv issue_ms "$run_out")"
  revoke_ms="$(extract_kv revoke_ms "$run_out")"
  lease_ttl_seconds="$(extract_kv lease_ttl_seconds "$run_out")"
  ttl_ok="$(extract_kv ttl_within_expected_window "$run_out")"
  rev_ok="$(extract_kv revocation_effective "$run_out")"
  unauth_ok="$(extract_kv unauthorized_access_blocked "$run_out")"
  hypothesis_overall="$(extract_kv hypothesis_overall "$run_out")"

  if [[ "$rc" -ne 0 && "$hypothesis_overall" == "na" ]]; then
    hypothesis_overall="not_supported"
  fi

  echo -e "${i}\t${issue_ms}\t${revoke_ms}\t${lease_ttl_seconds}\t${ttl_ok}\t${rev_ok}\t${unauth_ok}\t${hypothesis_overall}" >> "$METRICS_TSV"
  sleep "$SLEEP_BETWEEN_RUNS"
done

python3 - "$METRICS_TSV" "$SUMMARY_TXT" <<'PY'
import csv
import math
import statistics
import sys

metrics_tsv = sys.argv[1]
summary_txt = sys.argv[2]

rows = []
with open(metrics_tsv, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in reader:
        rows.append(row)

def numeric_series(key):
    values = []
    for r in rows:
        v = r.get(key, "na")
        if v is None or v == "na":
            continue
        try:
            values.append(float(v))
        except ValueError:
            pass
    return values

def p95(values):
    if not values:
        return math.nan
    if len(values) == 1:
        return values[0]
    ordered = sorted(values)
    idx = math.ceil(0.95 * len(ordered)) - 1
    idx = max(0, min(idx, len(ordered) - 1))
    return ordered[idx]

def fmt(v):
    if isinstance(v, float):
        if math.isnan(v):
            return "na"
        if v.is_integer():
            return str(int(v))
        return f"{v:.2f}"
    return str(v)

def yes_rate(key):
    total = len(rows)
    if total == 0:
        return (0, 0.0)
    yes = sum(1 for r in rows if r.get(key) == "yes")
    return (yes, yes * 100.0 / total)

total_runs = len(rows)
hyp_supported = sum(1 for r in rows if r.get("hypothesis_overall") == "supported")

issue = numeric_series("issue_ms")
revoke = numeric_series("revoke_ms")

ttl_yes, ttl_rate = yes_rate("ttl_within_expected_window")
rev_yes, rev_rate = yes_rate("revocation_effective")
unauth_yes, unauth_rate = yes_rate("unauthorized_access_blocked")

lines = [
    f"runs={total_runs}",
    f"hypothesis_supported_runs={hyp_supported}",
    f"hypothesis_supported_rate_pct={hyp_supported * 100.0 / total_runs:.2f}" if total_runs else "hypothesis_supported_rate_pct=0.00",
    "",
    "issue_ms:",
    f"  min={fmt(min(issue) if issue else math.nan)}",
    f"  median={fmt(statistics.median(issue) if issue else math.nan)}",
    f"  p95={fmt(p95(issue))}",
    f"  max={fmt(max(issue) if issue else math.nan)}",
    "",
    "revoke_ms:",
    f"  min={fmt(min(revoke) if revoke else math.nan)}",
    f"  median={fmt(statistics.median(revoke) if revoke else math.nan)}",
    f"  p95={fmt(p95(revoke))}",
    f"  max={fmt(max(revoke) if revoke else math.nan)}",
    "",
    f"ttl_within_expected_window_yes={ttl_yes}/{total_runs} ({ttl_rate:.2f}%)",
    f"revocation_effective_yes={rev_yes}/{total_runs} ({rev_rate:.2f}%)",
    f"unauthorized_access_blocked_yes={unauth_yes}/{total_runs} ({unauth_rate:.2f}%)",
]

with open(summary_txt, "w", encoding="utf-8") as out:
    out.write("\n".join(lines) + "\n")
PY

echo "[OK] Campaña finalizada."
echo "     Detalle por corrida: $METRICS_TSV"
echo "     Resumen agregado:    $SUMMARY_TXT"
