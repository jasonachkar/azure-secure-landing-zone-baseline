# Architecture Decisions

1. Hub-and-spoke networking with explicit peering keeps shared services centralized and isolates workloads.
2. Two primary resource groups (core and network) balance separation with operational simplicity.
3. Diagnostics flow to Log Analytics with a dedicated storage account for retention and export scenarios.
4. Policies are custom JSON definitions under /policies and assigned at subscription scope for portability.
5. Deny-based policies default to enforcement, with a controlled dev override for public IPs.
6. Optional Azure Firewall is included but disabled by default to avoid baseline cost spikes.
7. Environment wrappers in terraform/envs keep backends and tfvars isolated without duplicating module logic.
