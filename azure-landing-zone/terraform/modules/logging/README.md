# Logging Module

Creates a Log Analytics workspace and a private diagnostics storage account with GRS, infrastructure encryption, Key Vault CMK encryption, Azure AD-only authorization, soft delete, versioning, SAS expiry, and queue request logging.

Inputs:
- name_prefix: Prefix for resource naming.
- resource_group_name: Resource group for logging resources.
- location: Azure region.
- tags: Resource tags.
- log_retention_days: Log Analytics retention in days.
- storage_account_name: Storage account name override.
- private_endpoint_subnet_id: Subnet that hosts the Blob private endpoint.
- virtual_network_ids: VNets linked to the Blob private DNS zone.
- customer_managed_key_id: Versioned Key Vault key ID for storage encryption.
- customer_managed_key_identity_id: User-assigned identity authorized to use the CMK.

Outputs:
- log_analytics_workspace_id: Log Analytics workspace ID.
- log_analytics_workspace_name: Log Analytics workspace name.
- storage_account_id: Storage account ID.
- storage_account_name: Storage account name.
- storage_private_endpoint_id: Blob private endpoint ID.
