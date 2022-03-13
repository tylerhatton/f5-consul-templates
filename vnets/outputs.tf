output "resource_group_name" {
  value = azurerm_resource_group.instruqt.name
}

output "resource_group_location" {
  value = azurerm_resource_group.instruqt.location
}

output "shared_svcs_vnet" {
  value = module.shared_svcs_network.vnet_id
}

output "shared_svcs_subnets" {
  value = module.shared_svcs_network.vnet_subnets
}

output "legacy_vnet" {
  value = module.legacy-network.vnet_id
}

output "legacy_subnets" {
  value = module.legacy-network.vnet_subnets
}

output "bastion_ip" {
  value = azurerm_public_ip.bastion.ip_address
}