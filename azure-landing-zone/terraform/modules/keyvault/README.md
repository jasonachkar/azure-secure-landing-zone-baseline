# Key Vault Module

Creates a private Premium Key Vault, HSM-backed Blob-storage encryption key with explicit expiry and a 90-day rotation policy, least-privilege user-assigned CMK identity, private endpoint, and private DNS links for the hub and spoke VNets.

Inputs:
- name_prefix: Prefix for resource naming.
- resource_group_name: Resource group for Key Vault resources.
- location: Azure region.
- tags: Resource tags.
- admin_ip_allowlist: Legacy network ACL input retained for compatibility; public access remains disabled.
- private_endpoint_subnet_id: Subnet that hosts the Key Vault private endpoint.
- virtual_network_ids: VNets linked to the Key Vault private DNS zone.

Outputs:
- key_vault_id: Key Vault resource ID.
- key_vault_uri: Key Vault data-plane URI.
- key_vault_name: Key Vault name.
- storage_encryption_key_id: Versioned storage CMK ID.
- storage_encryption_identity_id: User-assigned CMK identity ID.
- private_endpoint_id: Key Vault private endpoint ID.
