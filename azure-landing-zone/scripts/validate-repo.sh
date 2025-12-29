#!/usr/bin/env bash
# Basic repo validation: required files plus Terraform formatting/validation.
set -euo pipefail

# Keep this list in sync with baseline repo requirements.
required_files=(
  "README.md"
  "LICENSE"
  "docs/architecture.puml"
  "docs/decisions.md"
  "docs/threat-model.md"
  "policies/require-tags.json"
  "policies/allowed-locations.json"
  "policies/deny-public-ip.json"
  "policies/deny-internet-ssh-rdp.json"
  "policies/storage-secure-transfer.json"
  "policies/storage-disable-public-access.json"
  "policies/audit-vm-disk-encryption.json"
  "policies/audit-diagnostics.json"
  "terraform/main.tf"
  "terraform/variables.tf"
  "terraform/outputs.tf"
  "terraform/modules/networking/main.tf"
  "terraform/modules/logging/main.tf"
  "terraform/modules/policy/main.tf"
  "terraform/modules/rbac/main.tf"
  "terraform/envs/dev/main.tf"
  "terraform/envs/prod/main.tf"
)

missing=0
for f in "${required_files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "Missing required file: ${f}" >&2
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "Required files present."

if command -v terraform >/dev/null 2>&1; then
  # Use backend=false to validate without a remote state dependency.
  terraform fmt -check -recursive terraform
  terraform -chdir=terraform/envs/dev init -backend=false
  terraform -chdir=terraform/envs/dev validate
else
  echo "terraform not found; skipping fmt/validate checks." >&2
fi
