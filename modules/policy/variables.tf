# modules/policy/variables.tf
variable "resource_group_id" { type = string }

# modules/policy/main.tf
data "azurerm_policy_definition" "deny_nic_public_ip" {
  display_name = "Network interfaces should not have public IPs"
}

resource "azurerm_resource_group_policy_assignment" "deny_public_ip" {
  name                 = "deny-nic-public-ip"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.deny_nic_public_ip.id
  enforce              = true
}