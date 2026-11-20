# modules/security/main.tf
data "azurerm_client_config" "current" {}

resource "azurerm_public_ip" "fw_pip" {
  name                = "pip-azfw-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "hub_fw" {
  name                = "azfw-hub-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_application_rule_collection" "allow_updates" {
  name                = "arc-os-updates"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  rule {
    name             = "Allow-Ubuntu-And-Microsoft-Repos"
    source_addresses = ["10.20.0.0/16"]
    target_fqdns = [
      "archive.ubuntu.com",
      "security.ubuntu.com",
      "packages.microsoft.com"
    ]
    protocol {
      port = 443
      type = "Https"
    }
    protocol {
      port = 80
      type = "Http"
    }
  }
}

resource "azurerm_key_vault" "kv" {
  name                          = "kv-zt-${var.suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-kv-zt"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.spoke_privatelink_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-zt"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-kv"
    private_dns_zone_ids = [var.kv_private_dns_zone_id]
  }
}