# Azure Zero-Trust Hub-and-Spoke Landing Zone

Modular Terraform project that deploys a Hub-and-Spoke network on Microsoft Azure with bidirectional VNet peering, Azure Firewall, a private Azure Key Vault (Private Endpoint + Private DNS zone + public network access disabled), and an Azure Policy assignment denying public IPs on network interfaces.

---

## Architecture

![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?logo=microsoftazure&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-Zero--Trust%20%7C%20Policy--as--Code-0A66C2)

Modular Terraform implementation of an **Azure Zero-Trust Hub-and-Spoke Landing Zone** featuring bidirectional VNet peering, centralized egress inspection via **Azure Firewall**, private data-plane access to **Azure Key Vault** via **Private Endpoint + Private DNS**, and preventive governance via **Azure Policy**.

---

## Architecture Overview

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
```

---

## Security & Architecture Highlights

* **Hub-and-Spoke Segmentation:** Separates shared hub network and security subnets (`vnet-hub-eastus`) from spoke workload and private endpoint subnets (`vnet-spoke-app-eastus`) with bidirectional VNet peering.
* **Centralized Egress Inspection:** Deploys **Azure Firewall** (`AZFW_VNet`, Standard SKU) in `AzureFirewallSubnet` with an application rule collection permitting OS and package repository traffic (`archive.ubuntu.com`, `security.ubuntu.com`, `packages.microsoft.com`).
* **Zero Public Exposure on Key Vault:** Configures Azure Key Vault with `public_network_access_enabled = false`, RBAC authorization enabled, and a Private Endpoint in `snet-privatelink` bound to `privatelink.vaultcore.azure.net`.
* **Policy-as-Code Enforcement:** Assigns built-in Azure Policy (`Network interfaces should not have public IPs`) at the resource group scope to block NICs created with public IP addresses.
* **Modular Terraform & Remote State:** Organizes reusable modules under `modules/` (`network`, `security`, `policy`) and environment configuration under `envs/dev/` backed by Azure Blob Storage.

---

## Folder Structure

```text
azure-zero-trust-landing-zone/
├── docs/
│   └── screenshots/          # Captured portal & CLI verification screenshots
├── envs/
│   └── dev/
│       ├── main.tf           # Resource group, random suffix, and module calls
│       ├── outputs.tf        # Exported RG name, Firewall private IP, and Key Vault name
│       └── providers.tf      # Terraform & provider config + Azure Blob backend
├── modules/
│   ├── network/              # Hub/Spoke VNets, subnets, NSG, peering, Private DNS
│   ├── security/             # Azure Firewall, Key Vault, Private Endpoint
│   └── policy/               # Azure Policy assignment denying NIC public IPs
├── .gitignore
└── README.md
```

---

## Step-by-Step Deployment & Verification Guide

### Step 1: Prerequisites & Azure Authentication
1. Ensure **Azure CLI** (`az`) and **Terraform** (`>= 1.9.0`) are installed.
2. Sign in to Azure, select your target subscription, and register required resource providers:

```bash
az login
az account list --output table
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.PolicyInsights
az provider register --namespace Microsoft.Security
az provider register --namespace Microsoft.Compute
```

### Step 2: Bootstrap Remote Terraform State Storage
Run once to create a private storage account and `tfstate` container:

```bash
export TF_RG="rg-tfstate-landingzone"
export TF_SA="sttfzl$(openssl rand -hex 4)"
export LOCATION="eastus"

az group create --name "$TF_RG" --location "$LOCATION"

az storage account create \
  --name "$TF_SA" \
  --resource-group "$TF_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name "$TF_SA" \
  --auth-mode login

echo "Storage Account Name: $TF_SA"
```

Copy the generated storage account name into `envs/dev/providers.tf` under `storage_account_name`.

### Step 3: Initialize, Validate, and Apply Terraform
Navigate to `envs/dev` and deploy the landing zone:

```bash
cd envs/dev
terraform init -upgrade
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4: Verify Zero-Trust & Policy Controls
Confirm Key Vault disables public internet access and Azure Policy blocks a NIC configured with a public IP:

```bash
KV_NAME=$(terraform output -raw key_vault_name)
RG_NAME=$(terraform output -raw resource_group_name)

# 1. Confirm Key Vault public network access is disabled (Expected: "Disabled")
az keyvault show --name "$KV_NAME" --query "properties.publicNetworkAccess"

# 2. Verify Policy-as-Code denies creating a NIC with a public IP
az network public-ip create --resource-group "$RG_NAME" --name pip-policy-test --sku Standard
az network nic create \
  --resource-group "$RG_NAME" \
  --name nic-policy-test \
  --vnet-name vnet-spoke-app-eastus \
  --subnet snet-workload \
  --public-ip-address pip-policy-test

# Clean up temporary test public IP
az network public-ip delete --resource-group "$RG_NAME" --name pip-policy-test
```

### Step 5: Capture Verification Screenshots & Push to GitHub
Save screenshots inside `docs/screenshots/`:
* `docs/screenshots/01-vnets-peerings.png` — Hub and Spoke VNets showing `Connected` peering status
* `docs/screenshots/02-keyvault-private-endpoint.png` — Key Vault networking showing public access disabled and the Private Endpoint connection
* `docs/screenshots/03-private-dns-zone.png` — `privatelink.vaultcore.azure.net` Private DNS zone and Spoke VNet link
* `docs/screenshots/04-policy-denial.png` — Terminal output showing Azure Policy denying the public-IP NIC

Stage, commit, and push your documentation and screenshots to GitHub:

```bash
mkdir -p docs/screenshots
git add README.md docs/screenshots/
git commit -m "Add end-to-end project README and verification screenshots"
git push -u origin main
```

### Step 6: Teardown Resources (Cost & Credit Hygiene)
Destroy billable resources (such as Azure Firewall) as soon as verification and screenshot capture are finished:

```bash
cd envs/dev
terraform destroy
```
>>>>>>> ceb97b0 (Add end-to-end project README and verification screenshots)
