#!/usr/bin/env bash
set -euo pipefail

missing=0
for bin in az terraform; do
  if ! command -v "${bin}" >/dev/null 2>&1; then
    echo "Missing dependency: ${bin}" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  echo "Install the missing tools and retry." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Azure CLI is not logged in. Run: az login" >&2
  exit 1
fi

sub_id=$(az account show --query id -o tsv)
sub_name=$(az account show --query name -o tsv)
echo "Using Azure subscription: ${sub_name} (${sub_id})"

if [[ -n "${AZURE_SUBSCRIPTION_ID:-}" && "${AZURE_SUBSCRIPTION_ID}" != "${sub_id}" ]]; then
  echo "AZURE_SUBSCRIPTION_ID does not match the active subscription." >&2
  exit 1
fi

if [[ -n "${ARM_SUBSCRIPTION_ID:-}" && "${ARM_SUBSCRIPTION_ID}" != "${sub_id}" ]]; then
  echo "ARM_SUBSCRIPTION_ID does not match the active subscription." >&2
  exit 1
fi

terraform version | head -n 1
