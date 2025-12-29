# Policy Module

Registers custom policy definitions from the /policies folder and assigns them at the provided scope.

Inputs:
- name_prefix: Prefix for assignment names.
- scope: Assignment scope (subscription or management group ID).
- policy_path: Filesystem path to policy JSON files.
- allowed_locations: Allowed location list for the allowed-locations policy.
- policy_enforcement_mode: Deny or Audit for deny-based policies.
- allow_public_ip: If true, public IP policy is set to Audit.
- admin_ip_allowlist: Admin IP allowlist used by the SSH/RDP policy.

Outputs:
- policy_assignment_ids: Map of assignment IDs.
