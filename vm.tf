resource "azurerm_public_ip" "vm_pip" {
  name                = "aks-admin-pip"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "aks-admin-nsg"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Kubernetes-NodePort"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "vm_nic" {
  name                = "aks-admin-nic"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.aks_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}


resource "azurerm_linux_virtual_machine" "aks_admin" {
  name                = "aks-admin-vm"
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  size                = "Standard_D2s_v3"

  admin_username = "azureuser"
  admin_password = "Aadvik@143143"

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  custom_data = base64encode(<<-EOF
#cloud-config
package_update: true
package_upgrade: true

runcmd:
  - apt-get update
  - apt-get install -y curl unzip apt-transport-https ca-certificates gnupg lsb-release jq

  # Azure CLI
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

  # kubectl
  - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  - rm kubectl

  # Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


EOF
  )

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
