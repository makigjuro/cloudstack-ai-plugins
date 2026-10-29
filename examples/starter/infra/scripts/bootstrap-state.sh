#!/usr/bin/env bash
# Creates the Terraform remote-state resource group + storage account for one
# environment, matching the names in terragrunt/root.hcl:
#   resource group:  starter-rg-tfstate-<env>-weu
#   storage account: startertfstate<env>weu   (container: tfstate)
#
# Idempotent: every resource is checked before it is created. Shared-key access
# is disabled; Terraform authenticates to state with Entra ID
# (use_azuread_auth = true), so the deploying principal needs
# "Storage Blob Data Contributor" on the account (granted below).
#
# Usage:
#   scripts/bootstrap-state.sh <dev|staging|prod> [principal-object-id]
#   DRY_RUN=1 scripts/bootstrap-state.sh dev     # print the plan only
#
# Requires: az CLI logged in (az login) with the target subscription selected
# or ARM_SUBSCRIPTION_ID exported.
set -euo pipefail

PROJECT="starter"
LOCATION="westeurope"
LOCATION_SHORT="weu"
CONTAINER="tfstate"

ENVIRONMENT="${1:-}"
PRINCIPAL_ID="${2:-}"

case "$ENVIRONMENT" in
  dev | staging | prod) ;;
  *)
    echo "usage: $0 <dev|staging|prod> [principal-object-id]" >&2
    exit 64
    ;;
esac

RG="${PROJECT}-rg-tfstate-${ENVIRONMENT}-${LOCATION_SHORT}"
SA="${PROJECT}tfstate${ENVIRONMENT}${LOCATION_SHORT}"
TAGS=("project=${PROJECT}" "environment=${ENVIRONMENT}" "managed-by=bootstrap-state.sh")

if ((${#SA} > 24)); then
  echo "storage account name '${SA}' exceeds 24 characters" >&2
  exit 65
fi

command -v az >/dev/null || { echo "az CLI not found (https://aka.ms/azure-cli)" >&2; exit 69; }

if [[ -n "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  az account set --subscription "$ARM_SUBSCRIPTION_ID"
fi
SUBSCRIPTION="$(az account show --query id -o tsv)"

if [[ -z "$PRINCIPAL_ID" ]]; then
  PRINCIPAL_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"
fi

cat <<PLAN
Terraform state bootstrap for '${ENVIRONMENT}'
  subscription:    ${SUBSCRIPTION}
  resource group:  ${RG} (${LOCATION}, CanNotDelete lock)
  storage account: ${SA} (Standard_LRS, TLS1_2, no public blobs, no shared keys,
                   blob versioning + 30-day soft delete)
  container:       ${CONTAINER}
  blob data role:  Storage Blob Data Contributor -> ${PRINCIPAL_ID:-<none: pass a principal id>}
PLAN

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "DRY_RUN=1: nothing changed."
  exit 0
fi

run() {
  echo "+ $*"
  "$@"
}

if [[ "$(az group exists --name "$RG")" == "true" ]]; then
  echo "= resource group ${RG} exists"
else
  run az group create --name "$RG" --location "$LOCATION" --tags "${TAGS[@]}" -o none
fi

if az storage account show --name "$SA" --resource-group "$RG" -o none 2>/dev/null; then
  echo "= storage account ${SA} exists"
else
  run az storage account create \
    --name "$SA" \
    --resource-group "$RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --https-only true \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --tags "${TAGS[@]}" \
    -o none
fi

run az storage account blob-service-properties update \
  --account-name "$SA" \
  --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  -o none

SA_ID="$(az storage account show --name "$SA" --resource-group "$RG" --query id -o tsv)"

if [[ -n "$PRINCIPAL_ID" ]]; then
  existing="$(az role assignment list --assignee "$PRINCIPAL_ID" --scope "$SA_ID" \
    --role "Storage Blob Data Contributor" --query 'length(@)' -o tsv)"
  if [[ "$existing" != "0" ]]; then
    echo "= Storage Blob Data Contributor already assigned to ${PRINCIPAL_ID}"
  else
    run az role assignment create --assignee "$PRINCIPAL_ID" \
      --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
    echo "  (RBAC can take a minute to propagate before the container can be created)"
  fi
fi

if [[ "$(az storage container exists --name "$CONTAINER" --account-name "$SA" --auth-mode login --query exists -o tsv)" == "true" ]]; then
  echo "= container ${CONTAINER} exists"
else
  run az storage container create --name "$CONTAINER" --account-name "$SA" --auth-mode login -o none
fi

if [[ -n "$(az lock list --resource-group "$RG" --query "[?name=='tfstate-protect'].id" -o tsv)" ]]; then
  echo "= delete lock exists"
else
  run az lock create --name tfstate-protect --lock-type CanNotDelete --resource-group "$RG" \
    --notes "Terraform state for ${PROJECT} ${ENVIRONMENT}" -o none
fi

echo "Done. State backend ready: ${SA}/${CONTAINER} in ${RG}."
