# IP Plan — inflab

Virtual network: `10.10.0.0/16` (Central India — only koreacentral, centralindia, malaysiawest, southeastasia, uaenorth are allowed by subscription policy)

| Subnet        | CIDR           | Purpose                    | NSG            | Inbound allow (explicit)                          |
|---------------|----------------|----------------------------|----------------|---------------------------------------------------|
| management    | 10.10.2.0/24   | Jump/admin VMs, RDP/SSH    | nsg-inflab-mgmt| RDP/SSH from admin_source_ip only; VNet; deny all|
| servers       | 10.10.1.0/24   | Workload VMs (AD, Linux)   | nsg-inflab-srv | RDP/SSH from management subnet only; VNet; deny all |
| AzureBastionSubnet (optional) | 10.10.3.0/26 | Bastion host, if enabled | nsg (platform) | Azure-managed; no custom rules                    |

## Address allocations (update as VMs are added)

| Host              | Subnet     | IP          | Notes                          |
|-------------------|------------|-------------|--------------------------------|
| dc1               | servers    | 10.10.1.4   | Windows DC1 — deployed, PIP for RDP |
| (reserve)         | servers    | 10.10.1.5   | DC2 — second domain controller           |
| (reserve)         | servers    | 10.10.1.6   | Linux VM — reserved              |
| (reserve)         | management | 10.10.2.4   | jump box — only if needed      |

DNS: after DC1 promotion, VNet DNS = 10.10.1.4 (DC forwards internet to 168.63.129.16).
DHCP scope: 10.10.1.100–200 (not used by static lab VMs).
