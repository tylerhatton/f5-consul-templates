provider "azurerm" {
  features {}
}

data "terraform_remote_state" "vnet" {
  backend = "local"

  config = {
    path = "../vnets/terraform.tfstate"
  }
}

##############
# BIG-IP
##############

resource "random_integer" "password-length" {
  min = 12
  max = 25
}

resource "random_password" "bigippassword" {
  length           = random_integer.password-length.result
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "_%@"
}

data "template_file" "vm_onboard" {
  template = file("${path.module}/templates/bigip.tpl")

  vars = {
    uname       = var.admin_username
    upassword   = random_password.bigippassword.result
    DO_URL      = var.DO_URL
    AS3_URL     = var.AS3_URL
    TS_URL      = var.TS_URL
    FAST_URL    = var.FAST_URL
    libs_dir    = var.libs_dir
    onboard_log = var.onboard_log
  }
}

resource "azurerm_marketplace_agreement" "f5" {
  publisher = "f5-networks"
  offer     = "f5-big-ip-better"
  plan      = "f5-bigip-virtual-edition-25m-better-hourly"
}

# Create F5 BIGIP VMs
resource "azurerm_virtual_machine" "f5bigip" {
  name       = "bigip"
  depends_on = [azurerm_marketplace_agreement.f5]

  location            = data.terraform_remote_state.vnet.outputs.resource_group_location
  resource_group_name = data.terraform_remote_state.vnet.outputs.resource_group_name

  network_interface_ids           = [azurerm_network_interface.ext-nic.id]
  vm_size                         = var.instance_type

  os_profile {
    computer_name  = "bigip"
    admin_username = var.admin_username
    admin_password = random_password.bigippassword.result
    custom_data = data.template_file.vm_onboard.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_image_reference {
    publisher = var.publisher
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  plan {
    name      = var.image_name
    publisher = var.publisher
    product   = var.product
  }

  storage_os_disk {
    name                 = "bigip-disk"
    caching              = "ReadWrite"
    managed_disk_type    = "Standard_LRS"
    disk_size_gb         = "100"
    create_option        = "FromImage"
  }

  tags = {
    Name        = "bigip"
    environment = "instruqt"
    workload    = "ltm"
  }
}

resource "azurerm_virtual_machine_extension" "f5bigip" {
  name                 = "f5bigip"
  depends_on           = [azurerm_virtual_machine.f5bigip]
  virtual_machine_id   = azurerm_virtual_machine.f5bigip.id
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  settings             = <<EOF
    {
      "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
EOF
}

resource "time_sleep" "wait_for_azurerm_virtual_machine_f5vm" {
  depends_on      = [azurerm_virtual_machine_extension.f5bigip]
  create_duration = "600s"
}

resource "azurerm_public_ip" "sip_public_ip" {
  name                = "bigip-public-ip"
  location            = data.terraform_remote_state.vnet.outputs.resource_group_location
  resource_group_name = data.terraform_remote_state.vnet.outputs.resource_group_name
  allocation_method   = "Static"   # Static is required due to the use of the Standard sku
  sku                 = "Standard" # the Standard sku is required due to the use of availability zones
  domain_name_label   = data.terraform_remote_state.vnet.outputs.resource_group_name
  tags = {
    environment = "instruqt"
  }
}

resource "azurerm_network_interface" "ext-nic" {
  name                 = "bigip-external-nic"
  location             = data.terraform_remote_state.vnet.outputs.resource_group_location
  resource_group_name  = data.terraform_remote_state.vnet.outputs.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.terraform_remote_state.vnet.outputs.legacy_subnets[0]
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.sip_public_ip.id
  }


  tags = {
    environment = "instruqt"

  }
}
resource "azurerm_network_interface_security_group_association" "ext-nic-security" {
  network_interface_id      = azurerm_network_interface.ext-nic.id
  network_security_group_id = azurerm_network_security_group.f5_public.id
}

resource "azurerm_network_security_group" "f5_public" {
  name                = "f5-public-security-group"
  location            = data.terraform_remote_state.vnet.outputs.resource_group_location
  resource_group_name = data.terraform_remote_state.vnet.outputs.resource_group_name

  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "MGMT"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "App-HTTP"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
