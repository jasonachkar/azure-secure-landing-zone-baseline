# Threat Model (STRIDE)

## Spoofing
- Risk: Compromised identities or service principals used to access the landing zone.
- Mitigations: Azure AD authentication, least-privilege RBAC, optional custom read-only role.

## Tampering
- Risk: Unauthorized changes to IaC, policies, or networking rules.
- Mitigations: Policy assignments, protected branches, CI validation, immutable infra patterns.

## Repudiation
- Risk: Lack of audit trails for changes.
- Mitigations: Activity logs sent to Log Analytics, diagnostic settings on VNets/NSGs/storage.

## Information Disclosure
- Risk: Public access to resources (storage, management ports).
- Mitigations: Deny public IPs by policy, NSG deny inbound from Internet, storage public access disabled.

## Denial of Service
- Risk: Excessive traffic to exposed services or misconfigured network paths.
- Mitigations: NSG baseline, optional Azure Firewall, documented guidance for DDoS protection.

## Elevation of Privilege
- Risk: Over-privileged principals and role assignments.
- Mitigations: Minimal custom role example, conditional assignments, policy enforcement.
