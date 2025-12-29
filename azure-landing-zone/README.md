# Azure Secure Landing Zone Baseline

A secure-by-default Azure landing zone built with Terraform. It provides a hub-and-spoke network baseline, centralized logging, governance policies, and RBAC scaffolding for dev and prod environments.

## Architecture Overview
- Hub VNet with app, data, and mgmt subnets.
- Spoke VNet with app, data, and mgmt subnets.
- NSGs per subnet with explicit deny-internet and allow-vnet rules.
- Optional Azure Firewall for centralized egress (disabled by default).
- Log Analytics workspace and a diagnostics storage account.
- Subscription-scoped policy assignments for baseline governance.

See `docs/architecture.puml` for a diagram source (render to PNG if desired).

## Security by Default
- No public IPs created by default; policy denies public IP creation.
- NSGs deny inbound from Internet; SSH/RDP only from explicit allowlist.
- Storage accounts require HTTPS, disable blob public access, and default to deny network rules.
- Mandatory tags enforced by policy.

## What Gets Deployed
- Resource groups: core and network.
- Hub + spoke VNets with subnets and peering.
- NSGs with secure baseline rules.
- Log Analytics workspace and diagnostic storage account.
- Diagnostic settings for VNets, NSGs, storage, and Log Analytics.
- Custom policies and assignments (8 baseline policies).
- Custom read-only role and optional role assignments.

## Prerequisites
- Terraform >= 1.6
- Azure CLI (`az`) and `az login`
- Permissions to create resource groups, policies, and RBAC assignments at subscription scope

## Deploy Dev
1. `bash scripts/preflight.sh`
2. `cd terraform/envs/dev`
3. Edit `dev.tfvars` (project name, allowed locations, tags, etc.)
4. `terraform init`
5. `terraform plan -var-file=dev.tfvars`
6. `terraform apply -var-file=dev.tfvars`

## Deploy Prod
1. `bash scripts/preflight.sh`
2. `cd terraform/envs/prod`
3. Edit `prod.tfvars`
4. `terraform init`
5. `terraform plan -var-file=prod.tfvars`
6. `terraform apply -var-file=prod.tfvars`

## Customize Policies
- Policy definitions live in `policies/` as JSON.
- Update JSON files and re-apply Terraform to register new definitions.
- For exceptions, use policy exemptions at the resource scope.
- Use `policy_enforcement_mode` to switch between `Deny` and `Audit`.
- Use `allow_public_ip = true` for dev scenarios that require public IPs.

## Destroy Safely
- Run `terraform destroy -var-file=<env>.tfvars` from the env directory.
- Remove policy assignments or role assignments manually if you need to keep shared governance.

## Cost Notes and Optional Components
- Azure Firewall is optional and disabled by default; enabling it creates a public IP.
- If you enable the firewall, set `allow_public_ip = true` or `policy_enforcement_mode = "Audit"` to avoid policy denial.
- Diagnostics storage uses an LRS account; adjust retention or tier as needed.
- Log Analytics retention defaults to 30 days.

## Testing and CI
- `scripts/validate-repo.sh` checks required files and runs terraform fmt/validate.
- GitHub Actions workflow runs fmt, validate, tflint, checkov, and a best-effort plan.

## Notes
- Storage account public endpoint is restricted by network rules; for private-only access, add private endpoints and update diagnostics accordingly.
- Storage account names must be globally unique; set `storage_account_name` if the default collides.
- Resource names are derived from `project_name` and `environment`; keep them short to avoid Azure length limits.
- Treat the included tfvars files as templates and avoid committing secrets.
