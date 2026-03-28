#!/usr/bin/env bash
# Validate changed Terraform modules against origin/main.
# Runs init (backend=false) + validate on each changed module directory.
#
# Expects TF_PATH environment variable (default: infra/terraform/modules)
#
# Usage: TF_PATH=infra/terraform/modules bash validate-terraform.sh

set -euo pipefail

TF_PATH="${TF_PATH:-infra/terraform/modules}"

CHANGED=$(git diff --name-only origin/main...HEAD -- "$TF_PATH")

if [ -z "$CHANGED" ]; then
  echo "No Terraform changes to validate"
  exit 0
fi

DIRS=$(echo "$CHANGED" | xargs -I{} dirname {} | sort -u)
FAILED=0

for dir in $DIRS; do
  if [ ! -d "$dir" ]; then
    echo "SKIP: $dir (deleted or missing)"
    continue
  fi
  echo "=== Validating $dir ==="
  terraform -chdir="$dir" init -backend=false -input=false 2>/dev/null
  if ! terraform -chdir="$dir" validate; then
    FAILED=1
  fi
done

exit $FAILED
