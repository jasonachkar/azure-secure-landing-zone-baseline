# Production — all baseline security controls enforced.
project_name = "myapp"         # Short workload name used in resource names.
environment  = "prod"          # Environment suffix used for isolation and tagging.
location     = "canadacentral" # Primary Azure deployment region.

allowed_locations = [ # Regions accepted by the allowed-locations policy.
  "canadacentral",
  "canadaeast",
]

enable_firewall         = true   # Deploy Azure Firewall in the hub network.
log_retention_days      = 365    # Retain security telemetry for one year.
policy_enforcement_mode = "Deny" # Block resources that violate enforceable baseline policies.
allow_public_ip         = false  # Deny public IP creation outside approved exceptions.

enable_defender_plans = [ # Enable paid Defender protection for core production services.
  "VirtualMachines",
  "StorageAccounts",
  "KeyVaults",
  "Arm",
  "Dns",
]

security_contact_email = "security-team@example.com"   # Defender for Cloud notification contact.
alert_email_addresses  = ["security-team@example.com"] # Azure Monitor security-alert recipient.

rbac_assignments = [ # Subscription-scope least-privilege assignments.
  {
    principal_id    = "00000000-0000-0000-0000-000000000000" # Replace with the security group's object ID.
    role_definition = "Reader"
    description     = "Security audit read access"
  },
]

hub_vnet_address_space   = ["10.0.0.0/16"] # Production hub address space.
spoke_vnet_address_space = ["10.1.0.0/16"] # Production workload spoke address space.

hub_subnet_prefixes = { # Dedicated hub prefixes, including the Azure Firewall subnet.
  app      = "10.0.1.0/24"
  data     = "10.0.2.0/24"
  mgmt     = "10.0.3.0/24"
  firewall = "10.0.254.0/24"
}

spoke_subnet_prefixes = { # Production workload subnet prefixes.
  app  = "10.1.1.0/24"
  data = "10.1.2.0/24"
  mgmt = "10.1.3.0/24"
}

admin_ip_allowlist   = []   # No direct SSH/RDP; use Azure Bastion or Defender JIT access.
storage_account_name = null # Use the generated diagnostics storage name; override on a global-name collision.

tags = { # Required ownership, environment, cost, and classification metadata.
  owner              = "platform-team@example.com"
  environment        = "prod"
  costCenter         = "cc-9001"
  dataClassification = "Confidential"
}
