#!/usr/bin/env bash
# Basic repo validation: required files plus Terraform formatting/validation.
set -euo pipefail

# Keep this list in sync with baseline repo requirements.
required_files=(
  "README.md"
  "LICENSE"
  ".github/workflows/terraform-security.yml"
  "../.github/workflows/terraform-security.yml"
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
  "terraform/backend.hcl.example"
  "terraform/providers.tf"
  "terraform/versions.tf"
  "terraform/variables.tf"
  "terraform/outputs.tf"
  "terraform/modules/alerts/main.tf"
  "terraform/modules/defender/main.tf"
  "terraform/modules/keyvault/main.tf"
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

if find . -name "._*" -not -path "./.git/*" -print -quit | grep -q .; then
  echo "AppleDouble metadata files found." >&2
  exit 1
fi

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "Required files present."

if command -v terraform >/dev/null 2>&1; then
  # Use backend=false to validate without a remote state dependency.
  terraform fmt -check -recursive terraform
  terraform -chdir=terraform init -backend=false
  terraform -chdir=terraform validate
else
  echo "terraform not found; skipping fmt/validate checks." >&2
fi
