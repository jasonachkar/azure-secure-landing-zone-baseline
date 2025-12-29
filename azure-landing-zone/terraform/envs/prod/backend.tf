terraform {
  backend "azurerm" {}
}

# Configure backend settings via -backend-config or by editing this file.
# Example:
# terraform init \
#   -backend-config="resource_group_name=rg-terraform-state" \
#   -backend-config="storage_account_name=sttfstate" \
#   -backend-config="container_name=tfstate" \
#   -backend-config="key=prod.terraform.tfstate"
