# Policy Definitions

This folder contains custom Azure Policy definitions used by the landing zone. Policies are authored as JSON and wrapped by the Terraform policy module.

Policies included:
- require-tags.json: Require owner, environment, costCenter, and dataClassification tags.
- allowed-locations.json: Restrict deployments to approved regions.
- deny-public-ip.json: Deny or audit public IP creation.
- deny-internet-ssh-rdp.json: Deny inbound SSH/RDP from Internet with an allowlist parameter.
- storage-secure-transfer.json: Require HTTPS-only storage.
- storage-disable-public-access.json: Disable blob public access.
- audit-vm-disk-encryption.json: Audit VMs without disk encryption sets.
- audit-diagnostics.json: Audit key resources without diagnostic settings.

Common parameters:
- effect: Most policies accept an effect parameter (Deny/Audit/Disabled).
- allowedSourceIps: Used by deny-internet-ssh-rdp to allow specific admin CIDRs.
- listOfAllowedLocations: Used by allowed-locations.

Customization:
1. Edit a policy JSON file to adjust rules or add parameters.
2. Run terraform plan/apply from the env directory to update the policy definitions/assignments.
3. For exceptions, prefer Azure Policy exemptions at the resource scope.
