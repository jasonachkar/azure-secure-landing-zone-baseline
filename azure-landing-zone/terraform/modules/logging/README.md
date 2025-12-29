# Logging Module

Creates a Log Analytics workspace and a secure storage account for diagnostics retention.

Inputs:
- name_prefix: Prefix for resource naming.
- resource_group_name: Resource group for logging resources.
- location: Azure region.
- tags: Resource tags.
- log_retention_days: Log Analytics retention in days.
- storage_account_name: Storage account name override.

Outputs:
- log_analytics_workspace_id: Log Analytics workspace ID.
- log_analytics_workspace_name: Log Analytics workspace name.
- storage_account_id: Storage account ID.
- storage_account_name: Storage account name.
