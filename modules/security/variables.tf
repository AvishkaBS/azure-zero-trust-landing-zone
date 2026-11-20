# modules/security/variables.tf
variable "resource_group_name"        { type = string }
variable "location"                   { type = string }
variable "tags"                       { type = map(string) }
variable "suffix"                     { type = string }
variable "firewall_subnet_id"         { type = string }
variable "spoke_privatelink_subnet_id"{ type = string }
variable "kv_private_dns_zone_id"     { type = string }