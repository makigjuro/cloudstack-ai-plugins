#!/usr/bin/env bash
# Lint Helm charts that changed relative to origin/main.
# Runs helm lint + helm template on each changed chart.
#
# Expects CHARTS_PATH environment variable (default: deploy/charts)
#
# Usage: CHARTS_PATH=deploy/charts bash lint-helm.sh

set -euo pipefail

CHARTS_PATH="${CHARTS_PATH:-deploy/charts}"

HELM_CHANGED=$(git diff --name-only origin/main...HEAD -- "$CHARTS_PATH/")

if [ -z "$HELM_CHANGED" ]; then
  echo "No Helm changes to lint"
  exit 0
fi

# Extract unique chart directories (first 3 path segments for default layout, or detect depth)
CHARTS=$(echo "$HELM_CHANGED" | while IFS= read -r f; do
  # Walk up from changed file to find Chart.yaml
  dir=$(dirname "$f")
  while [ "$dir" != "." ] && [ ! -f "$dir/Chart.yaml" ]; do
    dir=$(dirname "$dir")
  done
  if [ -f "$dir/Chart.yaml" ]; then
    echo "$dir"
  fi
done | sort -u)

FAILED=0

for chart in $CHARTS; do
  if [ ! -d "$chart" ]; then
    echo "SKIP: $chart (deleted or missing)"
    continue
  fi
  echo "=== Linting $chart ==="
  if ! helm lint "$chart"; then
    FAILED=1
  fi
  if ! helm template test "$chart" > /dev/null; then
    FAILED=1
  fi
done

exit $FAILED
