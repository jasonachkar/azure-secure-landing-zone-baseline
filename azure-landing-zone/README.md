# Azure Secure Landing Zone Baseline

Azure landing zone baseline built with Terraform. This repository delivers a secure-by-default foundation (networking, logging, governance, and RBAC) with consistent naming, tags, and policy enforcement across dev and prod environments.

## Table of Contents
- Overview
- Architecture
- What Gets Deployed
- Security Defaults
- Repository Layout
- Prerequisites
- Required Azure Permissions
- Quickstart (Dev)
- Backend Configuration
- Configuration Guide
- Policy Customization and Exceptions
- Optional Azure Firewall
- Diagnostics and Logging
- CI and Quality Checks
- Destroy and Cleanup
- Troubleshooting
- License

## Overview
This landing zone establishes:
- A hub-and-spoke network topology with secure NSGs.
- Centralized logging with Log Analytics and diagnostics storage.
- Subscription-level governance using custom Azure Policy definitions.
- Example RBAC model with a custom read-only role and optional assignments.

It is designed to be:
- Secure by default (deny public ingress, enforce tags, restrict regions).
- Fully Terraform-managed and GitHub-ready.
- Environment-friendly with separate dev/prod wrappers.

## Architecture
High-level design:
- Hub VNet + Spoke VNet.
- Subnets in each VNet: app, data, mgmt.
- NSGs per subnet with deny-by-default inbound.
- Optional Azure Firewall in the hub.
- Centralized logging and diagnostics.

PlantUML diagram source: `docs/architecture.puml`  
Render it to PNG if desired using your preferred PlantUML renderer.

## What Gets Deployed
Core baseline components:
- Resource groups: `core` and `network`.
- Hub VNet and Spoke VNet with subnets.
- NSGs per subnet with baseline deny/allow rules.
- VNet peering (hub <-> spoke).
- Log Analytics Workspace.
- Storage Account for diagnostics (secure transfer enforced, public access disabled).
- Diagnostic settings for VNets, NSGs, Storage, and Log Analytics.
- 8 custom Azure Policy definitions and assignments.
- Custom RBAC role definition and optional role assignments.

## Security Defaults
- No public IPs created by default (policy denies public IPs).
- NSGs deny inbound from Internet; SSH/RDP allowed only if allowlist is provided.
- Storage accounts require HTTPS, disable blob public access, and default to deny network access.
- Mandatory tags enforced at both variable validation and policy level.
- Allowed locations restricted by policy (parameterized).

## Repository Layout
```
azure-landing-zone/
  README.md
  LICENSE
  .gitignore
  .editorconfig
  /docs
    architecture.puml
    decisions.md
    threat-model.md
  /policies
    README.md
    require-tags.json
    allowed-locations.json
    deny-public-ip.json
    deny-internet-ssh-rdp.json
    storage-secure-transfer.json
    storage-disable-public-access.json
    audit-vm-disk-encryption.json
    audit-diagnostics.json
  /scripts
    preflight.sh
    validate-repo.sh
  /terraform
    versions.tf
    providers.tf
    locals.tf
    variables.tf
    outputs.tf
    main.tf
    /modules
      /networking
      /logging
      /policy
      /rbac
    /envs
      /dev
      /prod
  /.github
    /workflows
      iac-ci.yml
```

## Prerequisites
- Terraform >= 1.6
- Azure CLI (`az`)
- An Azure subscription (required for plan/apply)

## Required Azure Permissions
At subscription scope:
- Resource group creation: `Contributor` (or higher)
- Policy definitions/assignments: `Resource Policy Contributor` (or higher)
- Role assignments: `User Access Administrator` or `Owner`

If you lack any of these, plan/apply will fail at the relevant step.

## Quickstart (Dev)
1. `bash scripts/preflight.sh`
2. `cd terraform/envs/dev`
3. Edit `dev.tfvars`
4. `terraform init`
5. `terraform plan -var-file=dev.tfvars`
6. `terraform apply -var-file=dev.tfvars`

## Backend Configuration
Backends are placeholders in:
- `terraform/envs/dev/backend.tf`
- `terraform/envs/prod/backend.tf`

Example for Azure Storage:
```
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=sttfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"
```

## Configuration Guide
Key variables (from `terraform/variables.tf`):
- `project_name` (string): short name used in resource names.
- `environment` (string): `dev` or `prod`.
- `location` (string): primary Azure region.
- `allowed_locations` (list): allowed regions for policy enforcement.
- `tags` (map): must include `owner`, `environment`, `costCenter`, `dataClassification`.
- `admin_ip_allowlist` (list): CIDRs allowed for SSH/RDP on mgmt subnet.
- `enable_firewall` (bool): deploy Azure Firewall in hub.
- `principal_object_id` (string): optional AAD object ID for RBAC assignments.
- `policy_enforcement_mode` (string): `Deny` or `Audit`.
- `allow_public_ip` (bool): audits public IP creation instead of deny.
- `storage_account_name` (string): optional override if default name collides.

Example `dev.tfvars`:
```
project_name = "azure-lz"
environment  = "dev"
location     = "eastus"

allowed_locations = ["eastus"]

tags = {
  owner              = "owner@example.com"
  environment        = "dev"
  costCenter         = "0000"
  dataClassification = "internal"
}

admin_ip_allowlist     = []
enable_firewall        = false
principal_object_id    = null
policy_enforcement_mode = "Deny"
allow_public_ip          = false
```

## Policy Customization and Exceptions
Policies are stored in `policies/` and registered via the policy module.
To customize:
1. Edit the JSON file in `policies/`.
2. Run `terraform plan` and `apply` from the env directory.

Exceptions:
- Prefer policy exemptions at the resource scope.
- For dev environments, set `allow_public_ip = true` or `policy_enforcement_mode = "Audit"`.

## Optional Azure Firewall
Enable with:
```
enable_firewall = true
```
Notes:
- Firewall requires a public IP and the `AzureFirewallSubnet`.
- If public IPs are denied by policy, set `allow_public_ip = true` or use `Audit` mode.

## Diagnostics and Logging
- Diagnostic settings are enabled for VNets, NSGs, storage, and Log Analytics.
- Logs flow to Log Analytics; Log Analytics diagnostics flow to storage.
- Storage account is configured with HTTPS-only, TLS 1.2, and public access disabled.

## CI and Quality Checks
GitHub Actions workflow (`.github/workflows/iac-ci.yml`) runs:
- `terraform fmt -check`
- `terraform validate`
- `tflint`
- `checkov`
- Best-effort plan for dev

Local checks:
```
bash scripts/validate-repo.sh
```

## Destroy and Cleanup
From the env directory:
```
terraform destroy -var-file=dev.tfvars
```
Notes:
- If you need to keep policies or RBAC, remove assignments manually.
- Ensure no other resources depend on hub/spoke networks before destroy.

## Troubleshooting
- **No subscriptions found**: your Azure account lacks a subscription. You need access granted or a subscription created.
- **Policy denies resource**: check `policy_enforcement_mode` or add a scoped exemption.
- **Storage account name collision**: set `storage_account_name`.
- **Insufficient permissions**: policy and role assignments require elevated permissions.

## License
MIT License. See `LICENSE`.
