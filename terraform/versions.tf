terraform {
  required_version = ">= 1.6.0"

  # Remote state stored in Azure Blob Storage with encryption-at-rest and state locking.
  # Override with -backend-config or a backend.hcl file at init time.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "__TF_STATE_STORAGE_ACCOUNT__"
    container_name       = "tfstate"
    key                  = "azure-landing-zone.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
