project_name = "azure-lz"
environment  = "prod"
location     = "eastus"

allowed_locations = [
  "eastus"
]

tags = {
  owner             = "owner@example.com"
  environment       = "prod"
  costCenter        = "0000"
  dataClassification = "confidential"
}

admin_ip_allowlist = []
enable_firewall    = false
principal_object_id = null
policy_enforcement_mode = "Deny"
allow_public_ip          = false
