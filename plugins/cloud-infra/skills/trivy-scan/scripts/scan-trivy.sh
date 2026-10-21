#!/usr/bin/env bash
# Scan Terraform + Helm charts for security misconfigurations using trivy.
#
# Reads:
#   TF_PARENT       — Terraform tree root (default: infra/terraform)
#   CHARTS_PATH     — Helm charts root (default: deploy/charts)
#   TRIVY_SEVERITY  — comma-list of severities to fail on
#                     (default: CRITICAL,HIGH,MEDIUM)
#   TRIVY_STRICT    — "1" to include LOW in the fail set
#   TRIVY_WARN_ONLY — "1" to never exit non-zero
#   TRIVY_IGNOREFILE — path to .trivyignore (default: {TF_PARENT}/.trivyignore
#                      if present, else {CHARTS_PATH}/../.trivyignore)
#
# Usage:
#   TF_PARENT=infra/terraform CHARTS_PATH=deploy/charts bash scan-trivy.sh
#
# Exit codes:
#   0  clean (or --warn-only) — PR can proceed
#   1  findings at failing severity — PR blocked
#   2  trivy not installed / invocation error

set -uo pipefail

TF_PARENT="${TF_PARENT:-infra/terraform}"
CHARTS_PATH="${CHARTS_PATH:-deploy/charts}"
TRIVY_SEVERITY="${TRIVY_SEVERITY:-CRITICAL,HIGH,MEDIUM}"
TRIVY_STRICT="${TRIVY_STRICT:-0}"
TRIVY_WARN_ONLY="${TRIVY_WARN_ONLY:-0}"

if [ "$TRIVY_STRICT" = "1" ]; then
  TRIVY_SEVERITY="CRITICAL,HIGH,MEDIUM,LOW"
fi

# --- preflight ---
if ! command -v trivy >/dev/null 2>&1; then
  cat >&2 <<EOF
ERROR: trivy is not installed.

Install it and re-run:
  brew install trivy                                                    # macOS
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin  # Linux
EOF
  exit 2
fi

# --- resolve ignorefile ---
pick_ignorefile() {
  if [ -n "${TRIVY_IGNOREFILE:-}" ] && [ -f "$TRIVY_IGNOREFILE" ]; then
    echo "$TRIVY_IGNOREFILE"
    return
  fi
  for candidate in \
    "$TF_PARENT/.trivyignore" \
    "$(dirname "$CHARTS_PATH")/.trivyignore" \
    ".trivyignore"; do
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

IGNOREFILE="$(pick_ignorefile)"
IGNORE_ARGS=()
if [ -n "$IGNOREFILE" ]; then
  echo "Using .trivyignore: $IGNOREFILE"
  IGNORE_ARGS+=("--ignorefile" "$IGNOREFILE")
fi

# --- scan targets ---
TARGETS=()
if [ -d "$TF_PARENT" ]; then
  TARGETS+=("$TF_PARENT")
fi
if [ -d "$CHARTS_PATH" ]; then
  TARGETS+=("$CHARTS_PATH")
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No TF_PARENT ($TF_PARENT) or CHARTS_PATH ($CHARTS_PATH) found — nothing to scan."
  exit 0
fi

# --- run scan ---
FAILED=0
for target in "${TARGETS[@]}"; do
  echo "=== Scanning $target (severity: $TRIVY_SEVERITY) ==="
  if ! trivy config "$target" \
      --severity "$TRIVY_SEVERITY" \
      --exit-code 1 \
      --quiet \
      --cache-dir /tmp/trivy-cache \
      "${IGNORE_ARGS[@]}"; then
    FAILED=1
  fi
done

if [ "$FAILED" -eq 0 ]; then
  echo "Trivy scan: PASS (no findings at severity $TRIVY_SEVERITY)"
  exit 0
fi

if [ "$TRIVY_WARN_ONLY" = "1" ]; then
  echo "Trivy scan: WARN (findings present, --warn-only set)"
  exit 0
fi

echo "Trivy scan: FAIL (findings at severity $TRIVY_SEVERITY)"
exit 1
