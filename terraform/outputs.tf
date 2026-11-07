output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "servers_subnet_id" {
  value = azurerm_subnet.servers.id
}

output "management_subnet_id" {
  value = azurerm_subnet.management.id
}

output "nsg_management" {
  value = azurerm_network_security_group.management.name
}

output "nsg_servers" {
  value = azurerm_network_security_group.servers.name
}

output "bastion_enabled" {
  value = var.enable_bastion
}

output "dc1_rdp" {
  value = azurerm_public_ip.dc1.ip_address
}

output "dc1_private_ip" {
  value = azurerm_network_interface.dc1.private_ip_address
}
