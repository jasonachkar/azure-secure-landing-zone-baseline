locals {
  require_tags              = jsondecode(file("${var.policy_path}/require-tags.json"))
  allowed_locations         = jsondecode(file("${var.policy_path}/allowed-locations.json"))
  deny_public_ip            = jsondecode(file("${var.policy_path}/deny-public-ip.json"))
  deny_internet_ssh_rdp      = jsondecode(file("${var.policy_path}/deny-internet-ssh-rdp.json"))
  storage_secure_transfer   = jsondecode(file("${var.policy_path}/storage-secure-transfer.json"))
  storage_disable_public     = jsondecode(file("${var.policy_path}/storage-disable-public-access.json"))
  audit_vm_disk_encryption   = jsondecode(file("${var.policy_path}/audit-vm-disk-encryption.json"))
  audit_diagnostics          = jsondecode(file("${var.policy_path}/audit-diagnostics.json"))

  enforcement_effect = var.policy_enforcement_mode
  public_ip_effect   = var.allow_public_ip ? "Audit" : var.policy_enforcement_mode
}

resource "azurerm_policy_definition" "require_tags" {
  name         = local.require_tags.name
  policy_type  = local.require_tags.properties.policyType
  mode         = local.require_tags.properties.mode
  display_name = local.require_tags.properties.displayName
  description  = local.require_tags.properties.description
  metadata     = jsonencode(local.require_tags.properties.metadata)
  policy_rule  = jsonencode(local.require_tags.properties.policyRule)
  parameters   = jsonencode(local.require_tags.properties.parameters)
}

resource "azurerm_policy_definition" "allowed_locations" {
  name         = local.allowed_locations.name
  policy_type  = local.allowed_locations.properties.policyType
  mode         = local.allowed_locations.properties.mode
  display_name = local.allowed_locations.properties.displayName
  description  = local.allowed_locations.properties.description
  metadata     = jsonencode(local.allowed_locations.properties.metadata)
  policy_rule  = jsonencode(local.allowed_locations.properties.policyRule)
  parameters   = jsonencode(local.allowed_locations.properties.parameters)
}

resource "azurerm_policy_definition" "deny_public_ip" {
  name         = local.deny_public_ip.name
  policy_type  = local.deny_public_ip.properties.policyType
  mode         = local.deny_public_ip.properties.mode
  display_name = local.deny_public_ip.properties.displayName
  description  = local.deny_public_ip.properties.description
  metadata     = jsonencode(local.deny_public_ip.properties.metadata)
  policy_rule  = jsonencode(local.deny_public_ip.properties.policyRule)
  parameters   = jsonencode(local.deny_public_ip.properties.parameters)
}

resource "azurerm_policy_definition" "deny_internet_ssh_rdp" {
  name         = local.deny_internet_ssh_rdp.name
  policy_type  = local.deny_internet_ssh_rdp.properties.policyType
  mode         = local.deny_internet_ssh_rdp.properties.mode
  display_name = local.deny_internet_ssh_rdp.properties.displayName
  description  = local.deny_internet_ssh_rdp.properties.description
  metadata     = jsonencode(local.deny_internet_ssh_rdp.properties.metadata)
  policy_rule  = jsonencode(local.deny_internet_ssh_rdp.properties.policyRule)
  parameters   = jsonencode(local.deny_internet_ssh_rdp.properties.parameters)
}

resource "azurerm_policy_definition" "storage_secure_transfer" {
  name         = local.storage_secure_transfer.name
  policy_type  = local.storage_secure_transfer.properties.policyType
  mode         = local.storage_secure_transfer.properties.mode
  display_name = local.storage_secure_transfer.properties.displayName
  description  = local.storage_secure_transfer.properties.description
  metadata     = jsonencode(local.storage_secure_transfer.properties.metadata)
  policy_rule  = jsonencode(local.storage_secure_transfer.properties.policyRule)
  parameters   = jsonencode(local.storage_secure_transfer.properties.parameters)
}

resource "azurerm_policy_definition" "storage_disable_public" {
  name         = local.storage_disable_public.name
  policy_type  = local.storage_disable_public.properties.policyType
  mode         = local.storage_disable_public.properties.mode
  display_name = local.storage_disable_public.properties.displayName
  description  = local.storage_disable_public.properties.description
  metadata     = jsonencode(local.storage_disable_public.properties.metadata)
  policy_rule  = jsonencode(local.storage_disable_public.properties.policyRule)
  parameters   = jsonencode(local.storage_disable_public.properties.parameters)
}

resource "azurerm_policy_definition" "audit_vm_disk_encryption" {
  name         = local.audit_vm_disk_encryption.name
  policy_type  = local.audit_vm_disk_encryption.properties.policyType
  mode         = local.audit_vm_disk_encryption.properties.mode
  display_name = local.audit_vm_disk_encryption.properties.displayName
  description  = local.audit_vm_disk_encryption.properties.description
  metadata     = jsonencode(local.audit_vm_disk_encryption.properties.metadata)
  policy_rule  = jsonencode(local.audit_vm_disk_encryption.properties.policyRule)
  parameters   = jsonencode(local.audit_vm_disk_encryption.properties.parameters)
}

resource "azurerm_policy_definition" "audit_diagnostics" {
  name         = local.audit_diagnostics.name
  policy_type  = local.audit_diagnostics.properties.policyType
  mode         = local.audit_diagnostics.properties.mode
  display_name = local.audit_diagnostics.properties.displayName
  description  = local.audit_diagnostics.properties.description
  metadata     = jsonencode(local.audit_diagnostics.properties.metadata)
  policy_rule  = jsonencode(local.audit_diagnostics.properties.policyRule)
  parameters   = jsonencode(local.audit_diagnostics.properties.parameters)
}

resource "azurerm_policy_assignment" "require_tags" {
  name                 = "${var.name_prefix}-require-tags"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.require_tags.id
  parameters = jsonencode({
    effect = {
      value = local.enforcement_effect
    }
  })
}

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "${var.name_prefix}-allowed-locations"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
    effect = {
      value = local.enforcement_effect
    }
  })
}

resource "azurerm_policy_assignment" "deny_public_ip" {
  name                 = "${var.name_prefix}-deny-public-ip"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  parameters = jsonencode({
    effect = {
      value = local.public_ip_effect
    }
  })
}

resource "azurerm_policy_assignment" "deny_internet_ssh_rdp" {
  name                 = "${var.name_prefix}-deny-internet-ssh-rdp"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.deny_internet_ssh_rdp.id
  parameters = jsonencode({
    allowedSourceIps = {
      value = var.admin_ip_allowlist
    }
    effect = {
      value = local.enforcement_effect
    }
  })
}

resource "azurerm_policy_assignment" "storage_secure_transfer" {
  name                 = "${var.name_prefix}-storage-secure-transfer"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.storage_secure_transfer.id
  parameters = jsonencode({
    effect = {
      value = local.enforcement_effect
    }
  })
}

resource "azurerm_policy_assignment" "storage_disable_public" {
  name                 = "${var.name_prefix}-storage-disable-public"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.storage_disable_public.id
  parameters = jsonencode({
    effect = {
      value = local.enforcement_effect
    }
  })
}

resource "azurerm_policy_assignment" "audit_vm_disk_encryption" {
  name                 = "${var.name_prefix}-audit-vm-disk-encryption"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.audit_vm_disk_encryption.id
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

resource "azurerm_policy_assignment" "audit_diagnostics" {
  name                 = "${var.name_prefix}-audit-diagnostics"
  scope                = var.scope
  policy_definition_id = azurerm_policy_definition.audit_diagnostics.id
  parameters = jsonencode({
    effect = {
      value = "AuditIfNotExists"
    }
  })
}
