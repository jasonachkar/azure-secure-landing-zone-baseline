# Azure Secure Landing Zone Baseline

[![Terraform Security Scan](https://github.com/jasonachkar/azure-secure-landing-zone-baseline/actions/workflows/terraform-security.yml/badge.svg)](https://github.com/jasonachkar/azure-secure-landing-zone-baseline/actions/workflows/terraform-security.yml)
[![tfsec](https://img.shields.io/badge/tfsec-enabled-2A6DB2?logo=aqua&logoColor=white)](https://github.com/aquasecurity/tfsec)
[![Checkov](https://img.shields.io/badge/Checkov-enabled-6B57FF)](https://www.checkov.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform >= 1.6](https://img.shields.io/badge/Terraform-%3E%3D%201.6-844FBA?logo=terraform)](https://developer.hashicorp.com/terraform/install)
[![Microsoft Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)

A production-oriented Terraform foundation for Azure that makes secure networking, governance, telemetry, secrets management, and threat detection the default.

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Security Controls](#security-controls)
- [Module Structure](#module-structure)
- [Azure Policies](#azure-policies)
- [CI/CD Pipeline](#cicd-pipeline)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Per-Environment Deployment](#per-environment-deployment)
- [Compliance Mapping](#compliance-mapping)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project deploys a subscription-scoped hub-and-spoke landing zone. Core security services and networking use separate resource groups, while policy, RBAC, Defender for Cloud, diagnostic settings, and Azure Monitor alerts provide subscription-wide governance and visibility.

| Component | Azure Resource | Purpose |
|---|---|---|
| Resource organization | Two Resource Groups | Separates core security services from networking resources. |
| Hub and spoke | VNets, subnets, and peerings | Isolates shared connectivity and workload address spaces. |
| Network protection | NSGs and Azure Firewall | Denies Internet ingress by default and centralizes inspection. |
| Security telemetry | Log Analytics Workspace | Collects diagnostic logs and metrics with controlled retention. |
| Diagnostic archive | Storage Account | Stores platform diagnostics with TLS 1.2, HTTPS-only traffic, and network default deny. |
| Secrets boundary | Azure Key Vault | Enables soft delete, purge protection, ACLs, and denied public network access. |
| Threat protection | Microsoft Defender for Cloud | Enables configurable Standard-tier resource protection plans. |
| Governance | Azure Policy | Assigns eight custom controls across the subscription. |
| Access control | Azure role assignments | Maps any number of Microsoft Entra principals to explicit role names. |
| Detection | Azure Monitor alerts and action group | Detects security-sensitive NSG, RBAC, policy, and Key Vault write operations. |
| State protection | Azure Blob backend | Encrypts state at rest and provides state locking through blob leases. |

## Architecture Diagram

```text
Azure subscription (Policy + RBAC scope)
│
├── Custom policy definitions and subscription assignments
│   └── Govern every resource group and child resource
│
├── <project>-<env>-rg-core
│   ├── Log Analytics Workspace
│   ├── Diagnostics Storage Account
│   ├── Key Vault
│   ├── Defender for Cloud configuration
│   └── Action group + security activity-log alerts
│
└── <project>-<env>-rg-network
    ├── Hub VNet
    │   ├── app / data / management subnets + NSGs
    │   └── AzureFirewallSubnet + Azure Firewall
    │
    ├────────────── bidirectional VNet peering ──────────────┐
    │                                                        │
    └── Spoke VNet                                          │
        └── app / data / management subnets + NSGs ◄────────┘
```

VNet, NSG, storage, and Key Vault diagnostics flow to Log Analytics. Log Analytics platform diagnostics flow to storage so the workspace does not target itself.

## Security Controls

References use [CIS Controls v8.1](https://www.cisecurity.org/controls/v8-1) safeguards and align implementation domains with the current [CIS Microsoft Azure Benchmarks](https://www.cisecurity.org/benchmark/azure). They are engineering mappings, not a certification claim.

### Network

- Every managed subnet has an NSG that denies inbound Internet traffic (CIS 12.2, 12.3).
- Management SSH/RDP is opened only when `admin_ip_allowlist` contains explicit CIDRs (CIS 12.3).
- Azure Firewall Premium defaults to enabled, uses a dedicated Firewall Policy, and enforces threat intelligence and IDPS in deny mode; development must opt out explicitly (CIS 12.2, 13.3).
- Policy denies public IPs and unrestricted SSH/RDP in production (CIS 4.1, 12.2).

### Identity & Access

- RBAC accepts explicit principal/role pairs and creates no implicit broad grants (CIS 5.4, 6.8).
- Assignment descriptions and stable `for_each` keys improve traceability (CIS 6.7, 6.8).
- Key Vault deployer permissions bind to the authenticated Terraform principal (CIS 3.3, 6.8).

### Data Protection

- Remote Azure Blob state is encrypted at rest and lockable (CIS 3.11).
- Diagnostics storage uses GRS, infrastructure encryption, a rotating Key Vault customer-managed key, Azure AD authorization by default, disabled Shared Key/local users, versioning, soft delete, SAS expiry policy, and queue request logging (CIS 3.10, 3.11, 8.5).
- Storage and Key Vault deny public-network access and use private endpoints in the spoke data subnet with private DNS linked to both VNets (CIS 3.3, 3.11, 12.2).
- Key Vault Premium uses 90-day soft delete, purge protection, a rotating HSM-backed key, and a least-privilege user-assigned storage-encryption identity (CIS 3.3, 3.11, 6.8).
- Azure Policy audits VM disk-encryption configuration (CIS 3.11).

Key Vault data-plane operations must run from a VPN-connected host or self-hosted runner that can resolve the private DNS zone and reach the hub/spoke network.

### Compliance & Audit

- Resource diagnostics are centralized in Log Analytics and storage (CIS 8.2, 8.5, 8.9).
- Retention defaults to 90 days with a validated 30–730 day range (CIS 8.10).
- Activity-log alerts cover writes to NSG rules, role assignments, policy assignments, and Key Vault access policies (CIS 8.11, 13.1).
- Terraform input validation and policy both require governance tags (CIS 1.1, 4.1).
- Checkov, tfsec, and Trivy enforce IaC checks and publish SARIF findings (CIS 16.7, 16.12).

## Module Structure

```text
.
├── .github/workflows/terraform-security.yml  # Project-local copy of the security workflow.
├── README.md                                  # Project documentation and operations guide.
├── LICENSE                                    # MIT license.
├── docs/                                      # Architecture, decisions, and threat model.
├── policies/                                  # Eight Azure Policy JSON definitions.
├── scripts/
│   ├── preflight.sh                           # Checks tools and Azure subscription context.
│   └── validate-repo.sh                       # Runs repository and Terraform checks.
└── terraform/
    ├── backend.hcl.example                    # Git-safe remote-state configuration template.
    ├── versions.tf                            # Terraform/AzureRM requirements and backend.
    ├── providers.tf                           # AzureRM provider feature configuration.
    ├── variables.tf                           # Root input interface and validations.
    ├── locals.tf                              # Normalized names, regions, tags, and storage name.
    ├── main.tf                                # Root composition and diagnostic settings.
    ├── outputs.tf                             # IDs and URIs needed by downstream automation.
    ├── modules/
    │   ├── alerts/                            # Action group and activity-log alerts.
    │   ├── defender/                          # Defender plans, workspace, and contact.
    │   ├── keyvault/                          # Hardened Key Vault and deployer policy.
    │   ├── logging/                           # Log Analytics and diagnostic storage.
    │   ├── networking/                        # Hub/spoke, NSGs, peering, and Firewall.
    │   ├── policy/                            # Policy definitions and assignments.
    │   └── rbac/                              # Multi-principal subscription RBAC.
    └── envs/
        ├── dev/                               # Cost-optimized wrapper and complete tfvars.
        └── prod/                              # Hardened wrapper and complete tfvars.
```

The executable GitHub workflow is also stored at the Git repository root in `../.github/workflows/terraform-security.yml`, which is the only location GitHub Actions loads.

## Azure Policies

Production uses the effects below. Development sets configurable deny controls to Audit, and `allow_public_ip` can audit the public-IP rule independently.

| Policy File | Effect | CIS Control |
|---|---|---|
| `allowed-locations.json` | Deny unapproved Azure regions | 4.1, 4.6 |
| `audit-diagnostics.json` | AuditIfNotExists for missing diagnostics | 8.2, 8.5, 8.9 |
| `audit-vm-disk-encryption.json` | Audit VMs without disk encryption sets | 3.11 |
| `deny-internet-ssh-rdp.json` | Deny Internet SSH/RDP except allowlisted CIDRs | 12.2, 12.3 |
| `deny-public-ip.json` | Deny public IP creation | 12.2 |
| `require-tags.json` | Deny resources missing required tags | 1.1, 4.1 |
| `storage-disable-public-access.json` | Deny blob public access | 3.3, 12.2 |
| `storage-secure-transfer.json` | Deny storage without secure transfer | 3.10 |

## CI/CD Pipeline

```text
Terraform or policy change
          │
          ├── policy JSON lint ─────────────────────────────┐
          │                                                 │
          └── terraform fmt ─► init -backend=false ─► validate
                                                        │
                               ┌────────────────────────┼────────────────────────┐
                               ▼                        ▼                        ▼
                            Checkov                   tfsec                    Trivy
                               │                        │                        │
                               └──────────── SARIF to GitHub Security ───────────┘
```

The workflow runs on relevant pull requests and pushes to `main`. Formatting and validation gate the scanners; Checkov uses hard failure, Trivy fails on HIGH/CRITICAL findings, and tfsec propagates its action result.

## Prerequisites

| Tool | Minimum Version | Install Link |
|---|---:|---|
| Terraform | 1.6.0 | [HashiCorp installation guide](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | 2.60 | [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Git | 2.40 | [Git downloads](https://git-scm.com/downloads) |
| Bash | 4.0 | [Git for Windows](https://gitforwindows.org/) or a Unix-compatible shell |
| Python | 3.10 | [Python downloads](https://www.python.org/downloads/) |

The deployment identity needs resource creation, policy definition/assignment, Defender configuration, and role-assignment permissions. Use approved custom roles or the combined capabilities of `Contributor`, `Resource Policy Contributor`, and `User Access Administrator`.

## Quick Start

### 1. Clone, authenticate, and select a subscription

```bash
git clone https://github.com/jasonachkar/azure-secure-landing-zone-baseline.git
cd azure-secure-landing-zone-baseline/azure-landing-zone
az login
az account list --output table
az account set --subscription "$(az account show --query id -o tsv)"
az account show --query '{name:name,id:id,tenantId:tenantId}' --output table
```

Pass the intended subscription ID to `az account set` if the current subscription is not the deployment target.

### 2. Bootstrap remote state

```bash
TFSTATE_LOCATION="canadacentral"
TFSTATE_RG="rg-tfstate"
TFSTATE_CONTAINER="tfstate"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TFSTATE_SUFFIX="$(printf '%s' "$SUBSCRIPTION_ID" | tr -d '-' | cut -c1-12)"
TFSTATE_SA="sttfstate${TFSTATE_SUFFIX}"

az group create \
  --name "$TFSTATE_RG" \
  --location "$TFSTATE_LOCATION"

az storage account create \
  --name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --location "$TFSTATE_LOCATION" \
  --kind StorageV2 \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --public-network-access Enabled

SIGNED_IN_USER_ID="$(az ad signed-in-user show --query id -o tsv)"
TFSTATE_SCOPE="$(az storage account show \
  --name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --query id -o tsv)"

az role assignment create \
  --assignee-object-id "$SIGNED_IN_USER_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$TFSTATE_SCOPE"

az storage container create \
  --name "$TFSTATE_CONTAINER" \
  --account-name "$TFSTATE_SA" \
  --auth-mode login
```

Role assignments can take several minutes to propagate. Retry container creation if it initially returns an authorization error.

### 3. Initialize, plan, and apply

```bash
cp terraform/backend.hcl.example terraform/backend.hcl
```

Set `storage_account_name` in `terraform/backend.hcl` to the value from `echo "$TFSTATE_SA"`; the file is ignored by Git. Then review `terraform/envs/dev/dev.tfvars` and run:

```bash
terraform -chdir=terraform init -backend-config=backend.hcl
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan \
  -var-file=envs/dev/dev.tfvars \
  -out=dev.tfplan
terraform -chdir=terraform apply dev.tfplan
```

Review the saved plan and obtain required approval before applying it.

## Configuration Reference

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | `string` | Required | Short project name used in resource names. |
| `environment` | `string` | Required | Environment identifier. |
| `location` | `string` | Required | Primary Azure region. |
| `allowed_locations` | `list(string)` | `[]` | Policy-approved regions; empty uses `location`. |
| `tags` | `map(string)` | Required | Required ownership, environment, cost-center, and classification tags. |
| `admin_ip_allowlist` | `list(string)` | `[]` | CIDRs used for management access and Key Vault ACL input. |
| `enable_firewall` | `bool` | `true` | Deploy Azure Firewall in the hub. |
| `rbac_assignments` | `list(object)` | `[]` | Subscription principal/role/description mappings. |
| `policy_enforcement_mode` | `string` | `"Deny"` | `Deny` or `Audit` for configurable policies. |
| `allow_public_ip` | `bool` | `false` | Audit rather than deny public IP creation. |
| `hub_vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | Hub VNet address ranges. |
| `spoke_vnet_address_space` | `list(string)` | `["10.1.0.0/16"]` | Spoke VNet address ranges. |
| `hub_subnet_prefixes` | `map(string)` | app/data/mgmt/firewall | Hub subnet ranges. |
| `spoke_subnet_prefixes` | `map(string)` | app/data/mgmt | Spoke subnet ranges. |
| `log_retention_days` | `number` | `90` | Log Analytics retention from 30 to 730 days. |
| `storage_account_name` | `string` | `null` | Optional diagnostics storage name override. |
| `enable_defender_plans` | `list(string)` | VM, Storage, Key Vault, ARM, DNS | Standard-tier Defender resource types. |
| `security_contact_email` | `string` | `null` | Optional Defender security contact. |
| `security_contact_phone` | `string` | Required | Defender security-contact phone in E.164 format. |
| `alert_email_addresses` | `list(string)` | `[]` | Azure Monitor action-group recipients. |

## Per-Environment Deployment

Development and production examples are complete and intentionally different:

- `terraform/envs/dev/dev.tfvars`: Firewall and Defender disabled, Audit policies, public IP audit, 30-day retention.
- `terraform/envs/prod/prod.tfvars`: Firewall and Defender enabled, Deny policies, public IP denial, 365-day retention, alerting and RBAC examples.

Use a tfvars file directly with the root module:

```bash
terraform -chdir=terraform plan -var-file=envs/dev/dev.tfvars
terraform -chdir=terraform plan -var-file=envs/prod/prod.tfvars
```

For separate state, use each environment wrapper and a distinct backend key:

```bash
terraform -chdir=terraform/envs/dev init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=$TFSTATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.azure-landing-zone.tfstate"
terraform -chdir=terraform/envs/dev plan -var-file=dev.tfvars

terraform -chdir=terraform/envs/prod init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=$TFSTATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.azure-landing-zone.tfstate"
terraform -chdir=terraform/envs/prod plan -var-file=prod.tfvars
```

Never share a backend key between environments.

## Compliance Mapping

| Control Domain | Framework | Implementation |
|---|---|---|
| Secure configuration | CIS Controls v8.1: 4.1, 4.6 | Terraform defaults, validation, tags, allowed regions, and policy. |
| Network infrastructure | CIS Controls v8.1: 12.2, 12.3; CIS Azure network domain | Hub/spoke, NSGs, management allowlist, public-IP policy, and Firewall. |
| Identity and access | CIS Controls v8.1: 5.4, 6.7, 6.8; SOC 2 CC6.1/CC6.2 | Explicit subscription RBAC and deployer-scoped Key Vault access. |
| Data protection | CIS Controls v8.1: 3.3, 3.10, 3.11; PCI DSS 4.0.1: 3.5, 4.2.1 | TLS, HTTPS-only storage, encrypted state, purge protection, and disk audit. |
| Logging and retention | CIS Controls v8.1: 8.2, 8.5, 8.9, 8.10; PCI DSS 4.0.1: 10.2, 10.5 | Central diagnostics, archive storage, and 90-day retention default. |
| Detection and response | CIS Controls v8.1: 8.11, 13.1; SOC 2 CC7.2/CC7.3 | Defender, action group, and security-sensitive activity alerts. |
| Secure development | CIS Controls v8.1: 16.7, 16.12; SOC 2 CC8.1 | Format, validate, Checkov, tfsec, Trivy, and JSON lint gates. |

These technical mappings support a compliance program but do not provide complete coverage or an audit attestation.

## Contributing

1. Fork the repository and create a focused branch such as `feat/private-endpoints`.
2. Use Conventional Commits and keep logical changes in separate commits.
3. Run Terraform formatting, backend-disabled initialization, validation, and policy JSON linting.
4. Update inputs, examples, and documentation together when interfaces change.
5. Open a pull request describing risk, plan impact, evidence, and migration requirements; obtain review before merge.

Do not commit credentials, local state, plan files, `.terraform/`, or `backend.hcl`. Report sensitive vulnerabilities privately to the repository owner.

## License

Licensed under the [MIT License](LICENSE).
