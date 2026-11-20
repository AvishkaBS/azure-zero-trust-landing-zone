# Azure Zero-Trust Hub-and-Spoke Landing Zone (Terraform)

Modular Terraform configuration for an Azure Hub-and-Spoke landing zone with VNet peering, Azure Firewall, a Private Endpoint + Private DNS zone for Azure Key Vault (with public network access disabled), and an Azure Policy assignment denying public IPs on network interfaces.

## Repository Structure
- `modules/network`: Hub/Spoke VNets, subnets, NSG, peering, Private DNS zone & link
- `modules/security`: Azure Firewall, Key Vault (public access disabled), Private Endpoint
- `modules/policy`: Azure Policy assignment denying public IPs on NICs
- `envs/dev`: Dev environment wiring modules, remote backend, and outputs

## Usage & Teardown
Run `terraform init`, `terraform validate`, `terraform plan -out=tfplan`, and `terraform apply tfplan` from `envs/dev`. Run `terraform destroy` when finished testing so credits aren't wasted before December 10, 2026.
