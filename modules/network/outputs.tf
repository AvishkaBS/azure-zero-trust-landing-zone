# modules/network/outputs.tf
output "hub_vnet_id"                { value = azurerm_virtual_network.hub.id }
output "spoke_vnet_id"              { value = azurerm_virtual_network.spoke.id }
output "firewall_subnet_id"         { value = azurerm_subnet.firewall.id }
output "spoke_workload_subnet_id"   { value = azurerm_subnet.spoke_workload.id }
output "spoke_privatelink_subnet_id"{ value = azurerm_subnet.spoke_privatelink.id }
output "kv_private_dns_zone_id"     { value = azurerm_private_dns_zone.kv_dns.id }