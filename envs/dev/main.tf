# envs/dev/main.tf
variable "location" {
  type    = string
  default = "southeastasia"
}

locals {
  tags = {
    Project     = "ZeroTrust-LandingZone"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Owner       = "Avishka"
  }
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "lz" {
  name     = "rg-zt-landingzone-dev"
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.lz.name
  location            = var.location
  tags                = local.tags
}

module "security" {
  source                      = "../../modules/security"
  resource_group_name         = azurerm_resource_group.lz.name
  location                    = var.location
  tags                        = local.tags
  suffix                      = random_string.suffix.result
  firewall_subnet_id          = module.network.firewall_subnet_id
  spoke_privatelink_subnet_id = module.network.spoke_privatelink_subnet_id
  kv_private_dns_zone_id      = module.network.kv_private_dns_zone_id
}

module "policy" {
  source            = "../../modules/policy"
  resource_group_id = azurerm_resource_group.lz.id
}