# Development — cost-optimized controls with non-blocking policy evaluation.
project_name = "myapp"         # Short workload name used in resource names.
environment  = "dev"           # Environment suffix used for isolation and tagging.
location     = "canadacentral" # Primary Azure deployment region.

allowed_locations = [ # Regions accepted by the allowed-locations policy.
  "canadacentral",
  "canadaeast",
]

enable_firewall         = false   # Avoid Azure Firewall cost in this development example.
log_retention_days      = 30      # Lowest permitted retention for short-lived development logs.
policy_enforcement_mode = "Audit" # Report policy violations without blocking test deployments.
allow_public_ip         = true    # Audit public IP creation for development testing.

enable_defender_plans  = []   # Disable paid Defender plans in this cost-optimized environment.
security_contact_email = null # Do not create a Defender security contact in this example.
alert_email_addresses  = []   # Create the action group without email receivers.
rbac_assignments       = []   # Add explicit development principals when required.

hub_vnet_address_space   = ["10.10.0.0/16"] # Development hub address space.
spoke_vnet_address_space = ["10.11.0.0/16"] # Development workload spoke address space.

hub_subnet_prefixes = { # Dedicated hub prefixes, including the reserved firewall subnet.
  app      = "10.10.1.0/24"
  data     = "10.10.2.0/24"
  mgmt     = "10.10.3.0/24"
  firewall = "10.10.254.0/24"
}

spoke_subnet_prefixes = { # Development workload subnet prefixes.
  app  = "10.11.1.0/24"
  data = "10.11.2.0/24"
  mgmt = "10.11.3.0/24"
}

admin_ip_allowlist   = ["203.0.113.10/32"] # Replace the documentation IP with your trusted egress IP.
storage_account_name = null                # Use the generated diagnostics storage name; override on a global-name collision.

tags = { # Required ownership, environment, cost, and classification metadata.
  owner              = "dev-team@example.com"
  environment        = "dev"
  costCenter         = "cc-dev"
  dataClassification = "Internal"
}
