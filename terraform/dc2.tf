# --- DC2 (second domain controller) ---
resource "azurerm_public_ip" "dc2" {
  name                = "pip-inflab-dc2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "dc2" {
  name                = "nic-inflab-dc2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.1.5"
    public_ip_address_id          = azurerm_public_ip.dc2.id
  }
}

resource "azurerm_windows_virtual_machine" "dc2" {
  name                  = "dc2"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "dc2" {
  virtual_machine_id    = azurerm_windows_virtual_machine.dc2.id
  location              = azurerm_resource_group.main.location
  daily_recurrence_time = "2130"
  timezone              = "India Standard Time"

  notification_settings {
    enabled = false
  }
}
