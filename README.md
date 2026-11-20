# Azure Zero-Trust Hub-and-Spoke Landing Zone

Modular Terraform project that deploys a Hub-and-Spoke network on Microsoft Azure with bidirectional VNet peering, Azure Firewall, a private Azure Key Vault (Private Endpoint + Private DNS zone + public network access disabled), and an Azure Policy assignment denying public IPs on network interfaces.

---

## Architecture

```text
                         [Azure Subscription]
         ├── Azure Policy: Deny Public IPs on NICs (deny-nic-public-ip)
         └── RBAC / Least-Privilege Governance
                                 │
         ┌───────────────────────┴───────────────────────┐
         ▼                                               ▼
[Hub VNet: 10.10.0.0/16]                       [Spoke VNet: 10.20.0.0/16]
 ├── AzureFirewallSubnet (10.10.1.0/26)         ├── snet-workload (10.20.1.0/24)
 ├── AzureBastionSubnet (10.10.2.0/26)          │    └── NSG Attached (nsg-spoke-workload)
 └── snet-hub-mgmt (10.10.3.0/24)              └── snet-privatelink (10.20.2.0/24)
         │                                           └── Private Endpoint -> Key Vault
         └───────────► Bidirectional Peering ◄───────┘
                      + Private DNS Zone (privatelink.vaultcore.azure.net)
