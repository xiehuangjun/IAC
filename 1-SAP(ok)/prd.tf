# Create subnet (PRD)
resource "azurerm_subnet" "PRD_Subnet" {
    name                 = "PRD_Subnet"
    resource_group_name  = azurerm_resource_group.SAP.name
    virtual_network_name = azurerm_virtual_network.PRD_Vnet.name
    address_prefixes       = ["10.1.104.0/24"]
}


#-----------------jumpbox MTS PRD-----------------


# Create public IPs (Jumpbox_MTS_PRD)
resource "azurerm_public_ip" "Jumpbox_MTS_PRD" {
    name                         = "Jumpbox_MTS_PRD"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.SAP.name
    allocation_method            = "Static"

    tags = {
        environment = "PRD"
    }
}

# Create network interface (Jumpbox_MTS_PRD)
resource "azurerm_network_interface" "Jumpbox_MTS_PRD" {
    name                      = "Jumpbox_MTS_PRD"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "Jumpbox_MTS_PRD_NicConfiguration"
        subnet_id                     = azurerm_subnet.PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.104.8"
        public_ip_address_id          = azurerm_public_ip.Jumpbox_MTS_PRD.id
    }

    tags = {
        environment = "PRD"
    }
}

# Create Network Security Group and rule (Jumpbox_MTS_PRD)
resource "azurerm_network_security_group" "Jumpbox_MTS_PRD_NSG" {
    name                = "Jumpbox_MTS_PRD_NSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "NGINX"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    tags = {
        environment = "PRD"
    }
}

# Connect the security group to the network interface (Jumpbox_MTS_PRD)
resource "azurerm_network_interface_security_group_association" "Jumpbox_MTS_PRD" {
    network_interface_id      = azurerm_network_interface.Jumpbox_MTS_PRD.id
    network_security_group_id = azurerm_network_security_group.Jumpbox_MTS_PRD_NSG.id
}

# Generate random text for a unique storage account name (Jumpbox_MTS_PRD)
resource "random_id" "Random_Jumpbox_MTS_PRD" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (Jumpbox_MTS_PRD)
resource "azurerm_storage_account" "Jumpbox_MTS_PRD_storage_account" {
    name                        = "diag${random_id.Random_Jumpbox_MTS_PRD.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PRD"
    }
}

# Create virtual machine (Jumpbox_MTS_PRD)
resource "azurerm_linux_virtual_machine" "Jumpbox_MTS_PRD" {
    name                            = "Jumpbox_MTS_PRD"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.Jumpbox_MTS_PRD.id]
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "Jumpbox_MTS_PRD_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name                   = "Jumpbox MTS PRD"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.Jumpbox_MTS_PRD_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "PRD"
    }
}


#-----------------Terminal Server-----------------


# Create network interface (Terminal_Server)
resource "azurerm_network_interface" "Terminal_Server" {
    name                      = "Terminal_Server"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "Terminal_Server_NicConfiguration"
        subnet_id                     = azurerm_subnet.PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.104.9"
    }

    tags = {
        environment = "PRD"
    }
}

# Create Network Security Group and rule (Terminal_Server)
resource "azurerm_network_security_group" "Terminal_Server_NSG" {
    name                = "Terminal_Server_NSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "NGINX"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    tags = {
        environment = "PRD"
    }
}

# Connect the security group to the network interface (Terminal_Server)
resource "azurerm_network_interface_security_group_association" "Terminal_Server" {
    network_interface_id      = azurerm_network_interface.Terminal_Server.id
    network_security_group_id = azurerm_network_security_group.Terminal_Server_NSG.id
}

# Generate random text for a unique storage account name (Terminal_Server)
resource "random_id" "Random_Terminal_Server" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (Terminal_Server)
resource "azurerm_storage_account" "Terminal_Server_storage_account" {
    name                        = "diag${random_id.Random_Terminal_Server.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PRD"
    }
}

# Create virtual machine (Terminal_Server)
resource "azurerm_linux_virtual_machine" "Terminal_Server" {
    name                            = "Terminal_Server"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.Terminal_Server.id]
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "Terminal_Server_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name                   = "Terminal Server"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.Terminal_Server_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "PRD"
    }
}


#-----------------PRD SFTP Server-----------------


# Create network interface (PRD_SFTP_Server)
resource "azurerm_network_interface" "PRD_SFTP_Server" {
    name                      = "PRD_SFTP_Server"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "PRD_SFTP_Server_NicConfiguration"
        subnet_id                     = azurerm_subnet.PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.104.10"
    }

    tags = {
        environment = "PRD"
    }
}

# Create Network Security Group and rule (PRD_SFTP_Server)
resource "azurerm_network_security_group" "PRD_SFTP_Server_NSG" {
    name                = "PRD_SFTP_Server_NSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "NGINX"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    tags = {
        environment = "PRD"
    }
}

# Connect the security group to the network interface (PRD_SFTP_Server)
resource "azurerm_network_interface_security_group_association" "PRD_SFTP_Server" {
    network_interface_id      = azurerm_network_interface.PRD_SFTP_Server.id
    network_security_group_id = azurerm_network_security_group.PRD_SFTP_Server_NSG.id
}

# Generate random text for a unique storage account name (PRD_SFTP_Server)
resource "random_id" "Random_PRD_SFTP_Server" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (PRD_SFTP_Server)
resource "azurerm_storage_account" "PRD_SFTP_Server_storage_account" {
    name                        = "diag${random_id.Random_PRD_SFTP_Server.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PRD"
    }
}

# Create virtual machine (PRD_SFTP_Server)
resource "azurerm_linux_virtual_machine" "PRD_SFTP_Server" {
    name                            = "PRD_SFTP_Server"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.PRD_SFTP_Server.id]
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "PRD_SFTP_Server_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name                   = "PRD SFTP Server"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.PRD_SFTP_Server_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "PRD"
    }
}