#-----------------S4 PRD API-----------------


# Create network interface (S4_PRD_API)
resource "azurerm_network_interface" "S4_PRD_API" {
    name                      = "S4_PRD_API"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "S4_PRD_API_NicConfiguration"
        subnet_id                     = azurerm_subnet.S4_HANA_PRD_ASCS_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.103.8"
    }

    tags = {
        environment = "S4_HANA"
    }
}

# Create Network Security Group and rule (S4_PRD_API)
resource "azurerm_network_security_group" "S4_PRD_API_NSG" {
    name                = "S4_PRD_API_NSG"
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
        environment = "S4_HANA"
    }
}

# Connect the security group to the network interface (S4_PRD_API)
resource "azurerm_network_interface_security_group_association" "S4_PRD_API" {
    network_interface_id      = azurerm_network_interface.S4_PRD_API.id
    network_security_group_id = azurerm_network_security_group.S4_PRD_API_NSG.id
}

# Generate random text for a unique storage account name (S4_PRD_API)
resource "random_id" "Random_S4_PRD_API" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (S4_PRD_API)
resource "azurerm_storage_account" "S4_PRD_API_storage_account" {
    name                        = "diag${random_id.Random_S4_PRD_API.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "S4_HANA"
    }
}

# Create virtual machine (S4_PRD_API)
resource "azurerm_linux_virtual_machine" "S4_PRD_API" {
    proximity_placement_group_id    = azurerm_proximity_placement_group.S4_HANA.id
    name                            = "S4_PRD_API"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.S4_PRD_API.id]
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "S4_PRD_API_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name                   = "S4 PRD API"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.S4_PRD_API_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "S4_HANA"
    }
}