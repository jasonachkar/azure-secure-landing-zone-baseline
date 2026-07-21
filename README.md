# Azure Secure Landing Zone Baseline

[![Terraform Security Scan](https://github.com/jasonachkar/azure-secure-landing-zone-baseline/actions/workflows/terraform-security.yml/badge.svg)](https://github.com/jasonachkar/azure-secure-landing-zone-baseline/actions/workflows/terraform-security.yml)
[![tfsec](https://img.shields.io/badge/tfsec-enabled-2A6DB2?logo=aqua&logoColor=white)](https://github.com/aquasecurity/tfsec)
[![Checkov](https://img.shields.io/badge/Checkov-enabled-6B57FF)](https://www.checkov.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](azure-landing-zone/LICENSE)
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

The baseline creates a hub-and-spoke landing zone at subscription scope. It separates core security services from networking, applies eight custom Azure Policy definitions, centralizes diagnostic data, enables configurable Microsoft Defender for Cloud plans, and provides activity-log alerting and least-privilege RBAC inputs.

| Component | Azure Resource | Purpose |
|---|---|---|
| Core resource group | `azurerm_resource_group` | Contains logging, Key Vault, action group, and security alert resources. |
| Network resource group | `azurerm_resource_group` | Contains hub-and-spoke networking and optional Azure Firewall. |
| Hub and spoke | Virtual Networks, subnets, peerings | Separates shared connectivity from workload address space. |
| Network enforcement | NSGs and Azure Firewall | Denies Internet ingress by default and provides centralized inspection when enabled. |
| Central logging | Log Analytics Workspace | Collects resource diagnostic logs and metrics with configurable retention. |
| Diagnostic archive | Storage Account | Stores Log Analytics diagnostics with TLS 1.2, HTTPS-only traffic, and default-deny network rules. |
| Secrets boundary | Azure Key Vault | Provides soft delete, purge protection, denied public network access, and a deployer access policy. |
| Cloud workload protection | Microsoft Defender for Cloud | Enables selected Standard-tier protection plans and connects Log Analytics. |
| Governance | Azure Policy definitions and subscription assignments | Enforces location, tags, network exposure, storage security, encryption auditing, and diagnostics auditing. |
| Access control | Azure role assignments | Applies an explicit list of principal-to-role mappings at subscription scope. |
| Detection and notification | Azure Monitor action group and activity-log alerts | Detects NSG, RBAC, policy-assignment, and Key Vault access-policy write operations. |
| Remote state | Azure Blob Storage backend | Keeps Terraform state out of local workstations and provides encryption at rest and blob-lease locking. |

## Architecture Diagram

```text
Azure subscription (policy and RBAC assignment scope)
│
├── Custom Azure Policy definitions + subscription assignments
│   └── Apply across both resource groups and all child resources
│
├── <project>-<env>-rg-core
│   ├── Log Analytics Workspace (90-day secure default)
│   ├── Diagnostics Storage Account (HTTPS/TLS 1.2, network default deny)
│   ├── Key Vault (purge protection, public network access disabled)
│   ├── Defender for Cloud workspace/contact configuration
│   └── Azure Monitor action group + activity-log alerts
│
└── <project>-<env>-rg-network
    ├── Hub VNet
    │   ├── app, data, and management subnets + NSGs
    │   └── AzureFirewallSubnet + Azure Firewall (enabled by default)
    │
    ├──────────── bidirectional VNet peering ────────────┐
    │                                                    │
    └── Spoke VNet                                      │
        └── app, data, and management subnets + NSGs ◄──┘
```

Diagnostic settings send VNet, NSG, storage, and Key Vault telemetry to Log Analytics. Log Analytics sends its own platform diagnostics to the storage account to avoid a circular destination.

## Security Controls

The references below use [CIS Controls v8.1](https://www.cisecurity.org/controls/v8-1) safeguards. The project also aligns its Azure-specific implementation domains with the current [CIS Microsoft Azure Benchmarks](https://www.cisecurity.org/benchmark/azure). A deployment still requires organization-specific review, evidence collection, and compensating controls; this repository does not by itself confer certification.

### Network

- Internet-origin inbound traffic is denied on every managed subnet; management SSH/RDP is allowed only from an explicit CIDR allowlist (CIS 12.2, 12.3).
- Azure Firewall is enabled by default and may be disabled explicitly for cost-controlled development environments (CIS 12.2, 13.3).
- Hub and spoke address spaces are isolated and connected through explicit peerings (CIS 12.2).
- Public IP creation and unrestricted SSH/RDP are governed by subscription policy (CIS 4.1, 12.2).

### Identity & Access

- RBAC is input as explicit principal/role pairs; the module creates no implicit broad role grants (CIS 5.4, 6.8).
- Role assignments are scoped to the target subscription and support assignment descriptions for auditability (CIS 6.7, 6.8).
- The Key Vault deployer policy is bound to the authenticated Terraform principal and no secrets are stored in Terraform configuration (CIS 3.3, 6.8).

### Data Protection

- Terraform state is stored in Azure Blob Storage, encrypted at rest by Azure Storage and locked by blob lease (CIS 3.11).
- Storage requires HTTPS and TLS 1.2, disables anonymous nested-item publication, and applies default-deny network rules (CIS 3.10, 3.11, 12.2).
- Key Vault enables 90-day soft-delete retention, purge protection, public-network denial, and network ACLs (CIS 3.3, 3.11).
- The VM disk-encryption policy audits workloads that lack a disk encryption set (CIS 3.11).

Key Vault public access is intentionally disabled. A workload that needs Key Vault data-plane access must add a private endpoint and private DNS integration appropriate to its network topology.

### Compliance & Audit

- Diagnostic settings collect supported logs and metrics centrally (CIS 8.2, 8.5, 8.9).
- Log Analytics retention defaults to 90 days and accepts 30–730 days for environment-specific requirements (CIS 8.10).
- Activity-log alerts monitor writes to NSG rules, role assignments, policy assignments, and Key Vault access policies (CIS 8.11, 13.1).
- Mandatory ownership, environment, cost-center, and data-classification tags are validated in Terraform and enforced by policy (CIS 1.1, 4.1).
- Checkov, tfsec, and Trivy reject high-risk IaC changes before merge; scan findings are uploaded as SARIF (CIS 16.7, 16.12).

## Module Structure

```text
.
├── .github/workflows/terraform-security.yml       # Active repository-level GitHub security workflow.
├── README.md                                       # Repository overview and operating guide.
└── azure-landing-zone/
    ├── .github/workflows/terraform-security.yml   # Project-local workflow source required by the baseline layout.
    ├── docs/                                       # Architecture decisions, PlantUML, and threat model.
    ├── policies/                                   # Eight custom Azure Policy JSON definitions.
    ├── scripts/
    │   ├── preflight.sh                            # Verifies Azure CLI/Terraform and active subscription context.
    │   └── validate-repo.sh                        # Checks required files, formatting, init, and validation.
    └── terraform/
        ├── backend.hcl.example                     # Safe remote-backend template; backend.hcl is ignored.
        ├── versions.tf                             # Terraform >=1.6, AzureRM ~>4.0, and azurerm backend.
        ├── providers.tf                            # AzureRM feature and deletion-safety configuration.
        ├── variables.tf                            # Public module interface and input validation.
        ├── locals.tf                               # Deterministic names, tags, regions, and storage naming.
        ├── main.tf                                 # Root composition and diagnostic settings.
        ├── outputs.tf                              # Network, logging, policy, Key Vault, and alert outputs.
        ├── modules/
        │   ├── alerts/                             # Action group and security activity-log alerts.
        │   ├── defender/                           # Defender plans, workspace connection, and contact.
        │   ├── keyvault/                           # Hardened Key Vault and deployer access policy.
        │   ├── logging/                            # Log Analytics and diagnostic storage.
        │   ├── networking/                         # Hub/spoke VNets, NSGs, peering, and Firewall.
        │   ├── policy/                             # Policy definition loading and subscription assignments.
        │   └── rbac/                               # Multiple principal/role assignments via for_each.
        └── envs/
            ├── dev/                                # Development wrapper, backend, and complete tfvars.
            └── prod/                               # Production wrapper, backend, and complete tfvars.
```

## Azure Policies

Effects shown are production assignment behavior. `policy_enforcement_mode = "Audit"` changes configurable deny policies to audit in development, and `allow_public_ip = true` independently audits public IP creation.

| Policy File | Effect | CIS Control |
|---|---|---|
| `allowed-locations.json` | Deny resources outside approved Azure regions | 4.1, 4.6 |
| `audit-diagnostics.json` | AuditIfNotExists when supported resources lack diagnostics | 8.2, 8.5, 8.9 |
| `audit-vm-disk-encryption.json` | Audit VMs without disk encryption sets | 3.11 |
| `deny-internet-ssh-rdp.json` | Deny Internet-sourced TCP/22 and TCP/3389 except allowlisted CIDRs | 12.2, 12.3 |
| `deny-public-ip.json` | Deny public IP creation | 12.2 |
| `require-tags.json` | Deny resources missing required governance tags | 1.1, 4.1 |
| `storage-disable-public-access.json` | Deny storage accounts that permit blob public access | 3.3, 12.2 |
| `storage-secure-transfer.json` | Deny storage accounts without secure transfer | 3.10 |

## CI/CD Pipeline

The workflow runs only when Terraform or policy files change. Terraform validation gates all three IaC scanners; policy JSON linting runs independently.

```text
push to main / pull request
           │
           ├── policy-lint: python json.tool ───────────────┐
           │                                                │
           └── terraform fmt ──► init -backend=false ──► validate
                                                         │
                                  ┌──────────────────────┼──────────────────────┐
                                  ▼                      ▼                      ▼
                              Checkov                  tfsec                  Trivy
                                  │                      │                      │
                                  └──────────── SARIF uploaded to GitHub Security ─┘
```

All scanners are enforcing: Checkov uses `soft_fail: false`; Trivy fails on HIGH or CRITICAL findings; tfsec propagates its action result.

## Prerequisites

| Tool | Minimum Version | Install Link |
|---|---:|---|
| Terraform | 1.6.0 | [HashiCorp installation guide](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | 2.60 | [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Git | 2.40 | [Git downloads](https://git-scm.com/downloads) |
| Bash | 4.0 | [Git for Windows](https://gitforwindows.org/) or a Unix-compatible shell |
| Python | 3.10 | [Python downloads](https://www.python.org/downloads/) for local policy JSON linting |

The deploying identity needs subscription permissions to create resource groups and resources, define and assign policies, configure Defender for Cloud, and create role assignments. In practice this usually requires `Contributor`, `Resource Policy Contributor`, and `User Access Administrator`, or an approved custom-role equivalent.

## Quick Start

### 1. Clone and enter the project

```bash
git clone https://github.com/jasonachkar/azure-secure-landing-zone-baseline.git
cd azure-secure-landing-zone-baseline/azure-landing-zone
```

### 2. Authenticate and select the subscription

```bash
az login
az account list --output table
az account set --subscription "$(az account show --query id -o tsv)"
az account show --query '{name:name,id:id,tenantId:tenantId}' --output table
```

If the current subscription is not the intended target, pass its subscription ID explicitly to `az account set`.

### 3. Bootstrap the remote state backend

The following commands create an encrypted StorageV2 account and private blob container. The storage-account suffix is derived from the subscription ID to produce a deterministic, globally unique candidate.

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

Azure role assignment propagation can take several minutes. If container creation returns authorization failure immediately after the assignment, wait briefly and retry it.

### 4. Configure and initialize Terraform

```bash
cp terraform/backend.hcl.example terraform/backend.hcl
```

Edit `terraform/backend.hcl` and set `storage_account_name` to the value printed by `echo "$TFSTATE_SA"`. The file is gitignored. Then initialize:

```bash
terraform -chdir=terraform init -backend-config=backend.hcl
```

### 5. Review and apply a development plan

Review `terraform/envs/dev/dev.tfvars`, especially the documentation-only admin IP and notification values, then run:

```bash
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan \
  -var-file=envs/dev/dev.tfvars \
  -out=dev.tfplan
terraform -chdir=terraform apply dev.tfplan
```

Never apply a saved plan from an untrusted source. Review the plan output and obtain the approvals required by your change process.

## Configuration Reference

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `project_name` | `string` | Required | Short workload name used in Azure resource names. |
| `environment` | `string` | Required | Environment identifier such as `dev` or `prod`. |
| `location` | `string` | Required | Primary Azure region. |
| `allowed_locations` | `list(string)` | `[]` | Policy-approved regions; empty means only `location`. |
| `tags` | `map(string)` | Required | Must contain `owner`, `environment`, `costCenter`, and `dataClassification`. |
| `admin_ip_allowlist` | `list(string)` | `[]` | CIDRs permitted by management NSG rules and supplied to Key Vault ACLs. |
| `enable_firewall` | `bool` | `true` | Deploy Azure Firewall and its required subnet/public IP. |
| `rbac_assignments` | `list(object)` | `[]` | Principal IDs, role names, and descriptions assigned at subscription scope. |
| `policy_enforcement_mode` | `string` | `"Deny"` | `Deny` or `Audit` for configurable enforcement policies. |
| `allow_public_ip` | `bool` | `false` | Switch only the public-IP policy to Audit. |
| `hub_vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | Hub VNet CIDR ranges. |
| `spoke_vnet_address_space` | `list(string)` | `["10.1.0.0/16"]` | Spoke VNet CIDR ranges. |
| `hub_subnet_prefixes` | `map(string)` | app/data/mgmt/firewall ranges | Hub subnet CIDRs; `firewall` is required when Firewall is enabled. |
| `spoke_subnet_prefixes` | `map(string)` | app/data/mgmt ranges | Spoke subnet CIDRs. |
| `log_retention_days` | `number` | `90` | Log Analytics retention; valid range is 30–730 days. |
| `storage_account_name` | `string` | `null` | Optional globally unique diagnostics storage name override. |
| `enable_defender_plans` | `list(string)` | VM, Storage, Key Vault, ARM, DNS | Defender resource types enabled at Standard tier. |
| `security_contact_email` | `string` | `null` | Optional Defender for Cloud notification contact. |
| `alert_email_addresses` | `list(string)` | `[]` | Email receivers created in the Azure Monitor action group. |

## Per-Environment Deployment

The complete examples are:

- Development: `azure-landing-zone/terraform/envs/dev/dev.tfvars`
- Production: `azure-landing-zone/terraform/envs/prod/prod.tfvars`

From the `azure-landing-zone` directory, select a variable file explicitly:

```bash
terraform -chdir=terraform plan -var-file=envs/dev/dev.tfvars
terraform -chdir=terraform plan -var-file=envs/prod/prod.tfvars
```

Development disables Azure Firewall and paid Defender plans, uses 30-day retention, and changes deny policies to Audit. Production enables Firewall and Defender plans, retains logs for 365 days, denies public IPs, and supplies security notification and RBAC examples.

For strict state isolation, use the environment wrappers and distinct backend keys:

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

Never point dev and prod at the same backend key.

## Compliance Mapping

| Control Domain | Framework | Implementation |
|---|---|---|
| Secure configuration | CIS Controls v8.1: 4.1, 4.6 | Terraform-defined defaults, input validation, mandatory tags, allowed regions, and policy enforcement. |
| Network infrastructure | CIS Controls v8.1: 12.2, 12.3; CIS Azure Foundations network domain | Hub/spoke isolation, NSGs, optional admin allowlist, public-IP policy, and Azure Firewall enabled by default. |
| Account and access control | CIS Controls v8.1: 5.4, 6.7, 6.8; SOC 2 CC6.1/CC6.2 | Explicit subscription RBAC mappings and deployer-scoped Key Vault permissions. |
| Data protection | CIS Controls v8.1: 3.3, 3.10, 3.11; PCI DSS 4.0.1: 3.5, 4.2.1 | TLS 1.2, HTTPS-only storage, remote encrypted state, Key Vault purge protection, and disk-encryption audit policy. |
| Logging and retention | CIS Controls v8.1: 8.2, 8.5, 8.9, 8.10; PCI DSS 4.0.1: 10.2, 10.5 | Central diagnostic settings, storage archive, and 90-day default Log Analytics retention. |
| Detection and response | CIS Controls v8.1: 8.11, 13.1; SOC 2 CC7.2/CC7.3 | Defender for Cloud plans, action group, and alerts for security-sensitive control-plane operations. |
| Secure development | CIS Controls v8.1: 16.7, 16.12; SOC 2 CC8.1 | Terraform format/validation plus enforcing Checkov, tfsec, Trivy, and policy JSON checks. |

This mapping identifies supporting technical controls, not complete framework coverage or an audit attestation.

## Contributing

1. Fork the repository and create a focused branch such as `feat/private-endpoints` or `fix/policy-parameters`.
2. Use Conventional Commits (`feat:`, `fix:`, `security:`, `docs:`, `ci:`, `chore:`) and keep unrelated changes in separate commits.
3. Run `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, and the policy JSON lint before opening a pull request.
4. Update documentation and environment examples when the module interface changes.
5. Open a pull request that explains risk, expected plan changes, validation evidence, and any migration steps. Obtain review before merge; do not commit state, credentials, plans, or `backend.hcl`.

Security-sensitive findings should be reported privately to the repository owner rather than disclosed in a public issue.

## License

Licensed under the [MIT License](azure-landing-zone/LICENSE).
