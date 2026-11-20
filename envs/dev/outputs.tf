# envs/dev/outputs.tf
output "resource_group_name" { value = azurerm_resource_group.lz.name }
output "firewall_private_ip" { value = module.security.firewall_private_ip }
output "key_vault_name"      { value = module.security.key_vault_name }