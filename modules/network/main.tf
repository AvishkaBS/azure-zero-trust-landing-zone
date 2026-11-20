# modules/network/main.tf
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.location}"
  address_space       = [var.hub_vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 2)]
}

resource "azurerm_subnet" "hub_mgmt" {
  name                 = "snet-hub-mgmt"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 3)]
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-app-${var.location}"
  address_space       = [var.spoke_vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "spoke_workload" {
  name                 = "snet-workload"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(var.spoke_vnet_cidr, 8, 1)]
}

resource "azurerm_subnet" "spoke_privatelink" {
  name                 = "snet-privatelink"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(var.spoke_vnet_cidr, 8, 2)]
}

resource "azurerm_network_security_group" "spoke_workload_nsg" {
  name                = "nsg-spoke-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "spoke_workload_assoc" {
  subnet_id                 = azurerm_subnet.spoke_workload.id
  network_security_group_id = azurerm_network_security_group.spoke_workload_nsg.id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link_spoke" {
  name                 = "link-kv-dns-spoke"
  private_dns_zone_id  = azurerm_private_dns_zone.kv_dns.id
  virtual_network_id   = azurerm_virtual_network.spoke.id
  registration_enabled = false
  tags                 = var.tags
}