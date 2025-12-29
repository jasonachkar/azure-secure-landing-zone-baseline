# Prod Environment

This directory is the root Terraform working directory for the prod environment.

Steps:
1. Update backend.tf or pass backend settings with -backend-config.
2. Edit prod.tfvars with your project name, locations, and tags.
3. Run:
   - terraform init
   - terraform plan -var-file=prod.tfvars
   - terraform apply -var-file=prod.tfvars
