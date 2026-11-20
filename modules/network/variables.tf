variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "hub_vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "spoke_vnet_cidr" {
  type    = string
  default = "10.20.0.0/16"
}