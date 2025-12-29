# RBAC Module

Creates a custom read-only role and optionally assigns it (and basic reader roles) to a provided principal.

Inputs:
- name_prefix: Prefix for role naming.
- scope: Subscription or management group scope.
- principal_object_id: Optional principal object ID for assignments.

Outputs:
- role_definition_id: Custom role definition resource ID.
