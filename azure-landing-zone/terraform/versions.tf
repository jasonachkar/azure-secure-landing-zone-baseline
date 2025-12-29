terraform {
  # Keep core version aligned with module features and CI tooling.
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Track stable 3.x releases without breaking changes.
      version = "~> 3.110"
    }
  }
}
