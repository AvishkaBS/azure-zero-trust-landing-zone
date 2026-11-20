# modules/security/outputs.tf
output "firewall_private_ip" { value = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address }
output "key_vault_name"      { value = azurerm_key_vault.kv.name }
output "key_vault_id"        { value = azurerm_key_vault.kv.id }