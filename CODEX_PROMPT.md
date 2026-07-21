# Azure Secure Landing Zone Baseline — Full Codex Refactor Prompt

## Context

You are working inside the GitHub repository `jasonachkar/azure-secure-landing-zone-baseline`.

The project structure is:

```
azure-landing-zone/
├── .github/                          # GitHub Actions workflows (currently empty)
├── docs/                             # Architecture docs
├── policies/                         # Azure Policy JSON definitions (8 policies)
│   ├── allowed-locations.json
│   ├── audit-diagnostics.json
│   ├── audit-vm-disk-encryption.json
│   ├── deny-internet-ssh-rdp.json
│   ├── deny-public-ip.json
│   ├── require-tags.json
│   ├── storage-disable-public-access.json
│   └── storage-secure-transfer.json
├── scripts/                          # Helper bash/PowerShell scripts
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    ├── outputs.tf
    ├── providers.tf
    ├── versions.tf
    ├── envs/
    │   ├── dev.tfvars
    │   └── prod.tfvars
    └── modules/
        ├── logging/
        ├── networking/
        ├── policy/
        └── rbac/
```

You must implement every task listed below. Do not skip any. Commit each logical group as a separate commit with a clear message.

---

## TASK 1 — Fix: Remove All macOS `._` Metadata Files (CRITICAL)

Throughout the entire repository, there are dozens of macOS AppleDouble metadata files
(e.g., `._main.tf`, `._README.md`, `._variables.tf`) appearing as visible, empty files
in every directory. These are NOT code and must be permanently removed.

### Steps:

1. Delete all `._*` files:
```bash
find . -name "._*" -not -path "./.git/*" -delete
```

2. Open (or create) the root `.gitignore` and add:
```gitignore
# macOS metadata
._*
.DS_Store
.AppleDouble
.LSOverride
__MACOSX/
```
Also add the same to `azure-landing-zone/.gitignore`.

3. Remove already-tracked `._*` files from the Git index:
```bash
git rm --cached -r --ignore-unmatch $(git ls-files | grep "^\\._")
```

4. Commit message: `chore: remove macOS AppleDouble metadata artifacts and update .gitignore`

---

## TASK 2 — Fix: Add Remote Terraform State Backend (CRITICAL SECURITY)

File: `azure-landing-zone/terraform/versions.tf`

Currently there is NO `backend` block — state is stored locally in plaintext.
Add an `azurerm` backend:

```hcl
terraform {
  required_version = ">= 1.6.0"

  # Remote state stored in Azure Blob Storage with encryption-at-rest and state locking.
  # Override with -backend-config or a backend.hcl file at init time.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "__TF_STATE_STORAGE_ACCOUNT__"
    container_name       = "tfstate"
    key                  = "azure-landing-zone.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

Create `azure-landing-zone/terraform/backend.hcl.example`:
```hcl
# Copy to backend.hcl (gitignored) and fill in your values.
# Run: terraform init -backend-config=backend.hcl
resource_group_name  = "rg-tfstate"
storage_account_name = "<globally-unique-storage-account>"
container_name       = "tfstate"
key                  = "azure-landing-zone.tfstate"
```

Add to `.gitignore`:
```
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
backend.hcl
```

Commit message: `security: add azurerm remote backend for encrypted state storage`

---

## TASK 3 — Fix: Azure Firewall Default Should Be `true` (SECURITY)

File: `azure-landing-zone/terraform/variables.tf`

Change `enable_firewall` default from `false` to `true`:
```hcl
variable "enable_firewall" {
  type        = bool
  description = "Deploy Azure Firewall in hub VNet. Defaults to true for production-grade security. Set false only in dev/lab to reduce cost."
  default     = true
}
```

In `envs/dev.tfvars`, explicitly add:
```hcl
enable_firewall = false
```

Commit message: `security: set enable_firewall default to true for production-hardened baseline`

---

## TASK 4 — Fix: Increase Log Retention to 90 Days (COMPLIANCE)

File: `azure-landing-zone/terraform/variables.tf`

```hcl
variable "log_retention_days" {
  type        = number
  description = "Log Analytics Workspace retention in days. Minimum 90 for CIS/SOC2/PCI-DSS compliance. Max 730."
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}
```

Commit message: `compliance: increase default log retention to 90 days (CIS/SOC2 baseline)`

---

## TASK 5 — Fix: Refactor RBAC Module for Multiple Role Assignments

### `variables.tf` — replace `principal_object_id` with:
```hcl
variable "rbac_assignments" {
  type = list(object({
    principal_id    = string
    role_definition = string
    description     = optional(string, "")
  }))
  description = "List of AAD principal-to-role mappings at subscription scope. Use least-privilege roles."
  default     = []
}
```

### `modules/rbac/variables.tf`:
```hcl
variable "scope"           { type = string }
variable "name_prefix"     { type = string }
variable "rbac_assignments" {
  type = list(object({
    principal_id    = string
    role_definition = string
    description     = optional(string, "")
  }))
  default = []
}
```

### `modules/rbac/main.tf` — use `for_each`:
```hcl
resource "azurerm_role_assignment" "this" {
  for_each = {
    for a in var.rbac_assignments :
    "${a.principal_id}-${replace(lower(a.role_definition), " ", "-")}" => a
  }

  scope                = var.scope
  role_definition_name = each.value.role_definition
  principal_id         = each.value.principal_id
  description          = each.value.description
}
```

### `modules/rbac/outputs.tf`:
```hcl
output "role_assignment_ids" {
  description = "Map of role assignment resource IDs keyed by principal-role pair."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
```

Commit message: `feat(rbac): refactor module to support multiple role assignments with for_each`

---

## TASK 6 — Add: Microsoft Defender for Cloud Module

Create `azure-landing-zone/terraform/modules/defender/`

### `main.tf`:
```hcl
resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = toset(var.enable_defender_plans)
  pricing_tier  = "Standard"
  resource_type = each.value
}

resource "azurerm_security_center_workspace" "this" {
  count        = var.log_analytics_workspace_id != null ? 1 : 0
  scope        = var.scope
  workspace_id = var.log_analytics_workspace_id
}

resource "azurerm_security_center_contact" "this" {
  count               = var.security_contact_email != null ? 1 : 0
  email               = var.security_contact_email
  phone               = var.security_contact_phone
  alert_notifications = true
  alerts_to_admins    = true
}
```

### `variables.tf`:
```hcl
variable "scope"                      { type = string }
variable "log_analytics_workspace_id" { type = string; default = null; nullable = true }
variable "security_contact_email"     { type = string; default = null; nullable = true }
variable "security_contact_phone"     { type = string; default = "" }
variable "enable_defender_plans" {
  type    = list(string)
  default = ["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm", "Dns"]
  description = "Defender for Cloud resource types to enable. Set to [] in dev to avoid cost."
}
```

### `outputs.tf`:
```hcl
output "defender_plans_enabled" {
  value = var.enable_defender_plans
}
```

Wire into root `main.tf`:
```hcl
module "defender" {
  source                     = "./modules/defender"
  scope                      = data.azurerm_subscription.current.id
  log_analytics_workspace_id = module.logging.log_analytics_workspace_id
  enable_defender_plans      = var.enable_defender_plans
  security_contact_email     = var.security_contact_email
}
```

Add to root `variables.tf`:
```hcl
variable "enable_defender_plans" {
  type        = list(string)
  description = "Defender for Cloud resource types to enable at Standard tier. Set to [] in dev to avoid cost."
  default     = ["VirtualMachines", "StorageAccounts", "KeyVaults", "Arm", "Dns"]
}

variable "security_contact_email" {
  type     = string
  default  = null
  nullable = true
}
```

In `envs/dev.tfvars`: `enable_defender_plans = []`

Commit message: `feat(defender): add Microsoft Defender for Cloud module with configurable plans`

---

## TASK 7 — Add: Azure Key Vault Module

Create `azure-landing-zone/terraform/modules/keyvault/`

### `main.tf`:
```hcl
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = "${var.name_prefix}-kv"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  tags                          = var.tags
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.admin_ip_allowlist
  }
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
  certificate_permissions = ["Get", "List", "Import", "Delete", "Recover"]
  key_permissions         = ["Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt"]
}
```

### `variables.tf`:
```hcl
variable "name_prefix"         { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tags"                { type = map(string) }
variable "admin_ip_allowlist"  { type = list(string); default = [] }
```

### `outputs.tf`:
```hcl
output "key_vault_id"   { value = azurerm_key_vault.this.id }
output "key_vault_uri"  { value = azurerm_key_vault.this.vault_uri }
output "key_vault_name" { value = azurerm_key_vault.this.name }
```

Wire into root `main.tf` and add Key Vault `azurerm_monitor_diagnostic_setting` (mirror the pattern already used for storage/LAW).

Add to root `variables.tf`:
```hcl
variable "admin_ip_allowlist" {
  type        = list(string)
  description = "CIDR blocks allowed to access Key Vault and management subnets."
  default     = []
}
```

Commit message: `feat(keyvault): add Azure Key Vault module with purge-protection, private access, and diagnostics`

---

## TASK 8 — Add: GitHub Actions DevSecOps Pipeline

Create `azure-landing-zone/.github/workflows/terraform-security.yml`:

```yaml
name: Terraform Security Scan

on:
  pull_request:
    paths:
      - "azure-landing-zone/terraform/**"
      - "azure-landing-zone/policies/**"
  push:
    branches: [main]
    paths:
      - "azure-landing-zone/terraform/**"
      - "azure-landing-zone/policies/**"

permissions:
  contents: read
  security-events: write

jobs:
  fmt:
    name: Terraform Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "~1.6" }
      - run: terraform fmt -check -recursive
        working-directory: azure-landing-zone/terraform

  validate:
    name: Terraform Validate
    runs-on: ubuntu-latest
    needs: fmt
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "~1.6" }
      - run: terraform init -backend=false
        working-directory: azure-landing-zone/terraform
      - run: terraform validate
        working-directory: azure-landing-zone/terraform

  checkov:
    name: Checkov IaC Scan
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4
      - uses: bridgecrewio/checkov-action@v12
        with:
          directory: azure-landing-zone/terraform
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: checkov-results.sarif
          category: checkov

  tfsec:
    name: tfsec Scan
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/tfsec-sarif-action@v1
        with:
          sarif_file: tfsec-results.sarif
          working_directory: azure-landing-zone/terraform
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: tfsec-results.sarif
          category: tfsec

  trivy:
    name: Trivy Misconfiguration Scan
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: config
          scan-ref: azure-landing-zone/terraform
          format: sarif
          output: trivy-results.sarif
          severity: HIGH,CRITICAL
          exit-code: 1
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif
          category: trivy

  policy-lint:
    name: Validate Policy JSON
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate JSON
        run: |
          for f in azure-landing-zone/policies/*.json; do
            python3 -m json.tool "$f" > /dev/null && echo "OK: $f" || exit 1
          done
```

Commit message: `ci: add GitHub Actions pipeline — Terraform fmt/validate, Checkov, tfsec, Trivy, policy lint`

---

## TASK 9 — Add: Azure Monitor Security Alerts Module

Create `azure-landing-zone/terraform/modules/alerts/`

### `main.tf`:
```hcl
resource "azurerm_monitor_action_group" "security" {
  name                = "${var.name_prefix}-ag-security"
  resource_group_name = var.resource_group_name
  short_name          = "sec-alerts"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "nsg_change" {
  name                = "${var.name_prefix}-alert-nsg-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "NSG security rule created, updated, or deleted."
  tags                = var.tags
  criteria { category = "Administrative"; operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write" }
  action { action_group_id = azurerm_monitor_action_group.security.id }
}

resource "azurerm_monitor_activity_log_alert" "rbac_change" {
  name                = "${var.name_prefix}-alert-rbac-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Subscription-level role assignment change — privilege escalation detection."
  tags                = var.tags
  criteria { category = "Administrative"; operation_name = "Microsoft.Authorization/roleAssignments/write" }
  action { action_group_id = azurerm_monitor_action_group.security.id }
}

resource "azurerm_monitor_activity_log_alert" "policy_change" {
  name                = "${var.name_prefix}-alert-policy-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.subscription_id]
  description         = "Azure Policy assignment created or deleted."
  tags                = var.tags
  criteria { category = "Administrative"; operation_name = "Microsoft.Authorization/policyAssignments/write" }
  action { action_group_id = azurerm_monitor_action_group.security.id }
}

resource "azurerm_monitor_activity_log_alert" "kv_policy_change" {
  count               = var.key_vault_id != null ? 1 : 0
  name                = "${var.name_prefix}-alert-kv-policy-change"
  resource_group_name = var.resource_group_name
  scopes              = [var.key_vault_id]
  description         = "Key Vault access policy modified."
  tags                = var.tags
  criteria { category = "Administrative"; operation_name = "Microsoft.KeyVault/vaults/accessPolicies/write" }
  action { action_group_id = azurerm_monitor_action_group.security.id }
}
```

### `variables.tf`:
```hcl
variable "name_prefix"           { type = string }
variable "resource_group_name"   { type = string }
variable "subscription_id"       { type = string }
variable "tags"                  { type = map(string) }
variable "key_vault_id"          { type = string; default = null; nullable = true }
variable "alert_email_addresses" { type = list(string); default = [] }
```

### `outputs.tf`:
```hcl
output "action_group_id" { value = azurerm_monitor_action_group.security.id }
```

Wire into root `main.tf` and add `alert_email_addresses` variable to root `variables.tf`.

Commit message: `feat(alerts): add Azure Monitor activity log alerts for NSG, RBAC, policy, and Key Vault changes`

---

## TASK 10 — Update providers.tf for azurerm 4.x

File: `azure-landing-zone/terraform/providers.tf`

```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
```

Commit message: `chore: upgrade azurerm provider to ~> 4.0 with explicit features block`

---

## TASK 11 — Write: Complete README.md

Create `README.md` at the **repository root** AND at `azure-landing-zone/README.md`.
Replace any existing content entirely. Write real, accurate content — no placeholder text.

The README must include ALL of the following sections:

1. **Title with badges** — CI badge, tfsec badge, checkov badge, License badge, Terraform version badge, Azure badge
2. **One-line tagline** — what this project is and why it matters
3. **Table of Contents**
4. **Overview** — table: Component | Azure Resource | Purpose
5. **Architecture Diagram** — ASCII art: subscription → resource groups → hub-spoke VNets → policy scope
6. **Security Controls** — by domain: Network, Identity & Access, Data Protection, Compliance & Audit (with CIS control references)
7. **Module Structure** — directory tree with one-line description per file/module
8. **Azure Policies** — table: Policy File | Effect | CIS Control
9. **CI/CD Pipeline** — ASCII flow of GitHub Actions stages
10. **Prerequisites** — table: Tool | Min Version | Install Link
11. **Quick Start** — step-by-step: clone → az login → bootstrap state backend (full az CLI commands) → terraform init → plan → apply
12. **Configuration Reference** — table of all key variables
13. **Per-Environment Deployment** — how to use dev.tfvars vs prod.tfvars
14. **Compliance Mapping** — table: Control Domain | Framework | Implementation
15. **Contributing** — fork, branch, commit conventions, PR process

Commit message: `docs: add comprehensive README with architecture diagram, compliance mapping, and quick start guide`

---

## TASK 12 — Complete envs/prod.tfvars and envs/dev.tfvars

Write fully populated, realistic example values for both files.
Every variable defined in `variables.tf` must appear in at least one of the two files.
Add inline comments explaining the purpose of each value.

### `envs/prod.tfvars` example:
```hcl
# Production — all security controls enforced.
project_name            = "myapp"
environment             = "prod"
location                = "canadacentral"

enable_firewall         = true
log_retention_days      = 365
policy_enforcement_mode = "Deny"
allow_public_ip         = false

security_contact_email  = "security-team@example.com"
alert_email_addresses   = ["security-team@example.com"]

enable_defender_plans = [
  "VirtualMachines",
  "StorageAccounts",
  "KeyVaults",
  "Arm",
  "Dns"
]

rbac_assignments = [
  {
    principal_id    = "00000000-0000-0000-0000-000000000000" # Replace with real object ID
    role_definition = "Reader"
    description     = "Security audit read access"
  }
]

tags = {
  owner              = "platform-team"
  environment        = "prod"
  costCenter         = "cc-9001"
  dataClassification = "Confidential"
}

admin_ip_allowlist = [] # No direct SSH/RDP in prod — use Azure Bastion or JIT
```

### `envs/dev.tfvars` example:
```hcl
# Development — cost-optimized, audit-mode policies.
project_name            = "myapp"
environment             = "dev"
location                = "canadacentral"

enable_firewall         = false   # Save cost in dev
log_retention_days      = 30
policy_enforcement_mode = "Audit" # Non-blocking in dev
allow_public_ip         = true    # Allow for dev testing

enable_defender_plans   = []      # Disable to save cost in dev

tags = {
  owner              = "dev-team"
  environment        = "dev"
  costCenter         = "cc-dev"
  dataClassification = "Internal"
}

admin_ip_allowlist = ["YOUR_DEV_IP/32"] # Replace with your IP
```

Commit message: `docs(envs): add complete prod.tfvars and update dev.tfvars with all variables`

---

## Final Verification Checklist

After all tasks are complete, run from `azure-landing-zone/terraform/`:

```bash
# All must pass before pushing
terraform fmt -check -recursive   # No output = pass
terraform init -backend=false     # Must succeed
terraform validate                # Must print "Success! The configuration is valid."
find . -name "._*" -not -path "./.git/*"  # Must return NOTHING
```

---

## Summary of All Changes

| # | Task | Files Changed | Priority |
|---|---|---|---|
| 1 | Remove `._*` artifacts | All dirs + `.gitignore` | 🔴 Critical |
| 2 | Remote state backend | `versions.tf`, `backend.hcl.example`, `.gitignore` | 🔴 Security |
| 3 | Firewall default=true | `variables.tf`, `envs/dev.tfvars` | 🔴 Security |
| 4 | Log retention 90d | `variables.tf` | 🟠 Compliance |
| 5 | RBAC multi-principal | `variables.tf`, `modules/rbac/*` | 🟠 Architecture |
| 6 | Defender for Cloud | `modules/defender/*`, `main.tf`, `variables.tf` | 🔴 Security |
| 7 | Azure Key Vault | `modules/keyvault/*`, `main.tf`, `variables.tf` | 🔴 Security |
| 8 | CI/CD workflows | `.github/workflows/terraform-security.yml` | 🟠 DevSecOps |
| 9 | Monitor alerts | `modules/alerts/*`, `main.tf`, `variables.tf` | 🟠 Detection |
| 10 | azurerm 4.x features | `providers.tf`, `versions.tf` | 🟡 Modernization |
| 11 | Root README | `README.md`, `azure-landing-zone/README.md` | 🟡 Documentation |
| 12 | Complete tfvars | `envs/prod.tfvars`, `envs/dev.tfvars` | 🟡 Usability |
