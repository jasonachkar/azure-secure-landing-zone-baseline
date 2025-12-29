# Dev Environment

This directory is the root Terraform working directory for the dev environment.

Steps:
1. Update backend.tf or pass backend settings with -backend-config.
2. Edit dev.tfvars with your project name, locations, and tags.
3. Run:
   - terraform init
   - terraform plan -var-file=dev.tfvars
   - terraform apply -var-file=dev.tfvars
