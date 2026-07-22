# RBAC Module

Creates any number of Azure role assignments at a supplied scope. Each assignment maps one Microsoft Entra principal object ID to a built-in or custom role name.

Inputs:
- name_prefix: Prefix for role naming.
- scope: Subscription or management group scope.
- rbac_assignments: List of principal IDs, role definition names, and optional descriptions.

Outputs:
- role_assignment_ids: Map of assignment resource IDs keyed by principal-role pair.
