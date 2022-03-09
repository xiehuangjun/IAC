#-----------------PO PRD AP-----------------


# Create network interface (PO_PRD_AP)
resource "azurerm_network_interface" "PO_PRD_AP" {
    name                      = "PO_PRD_AP"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "PO_PRD_AP_NicConfiguration"
        subnet_id                     = azurerm_subnet.PO_HANA_PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.101.8"
    }

    tags = {
        environment = "PO"
    }
}

# Create Network Security Group and rule (PO_PRD_AP)
resource "azurerm_network_security_group" "PO_PRD_AP_NSG" {
    name                = "PO_PRD_AP_NSG"
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
        environment = "PO"
    }
}

# Connect the security group to the network interface (PO_PRD_AP)
resource "azurerm_network_interface_security_group_association" "PO_PRD_AP" {
    network_interface_id      = azurerm_network_interface.PO_PRD_AP.id
    network_security_group_id = azurerm_network_security_group.PO_PRD_AP_NSG.id
}

# Generate random text for a unique storage account name (PO_PRD_AP)
resource "random_id" "Random_PO_PRD_AP" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (PO_PRD_AP)
resource "azurerm_storage_account" "PO_PRD_AP_storage_account" {
    name                        = "diag${random_id.Random_PO_PRD_AP.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PO"
    }
}

# Create virtual machine (PO_PRD_AP)
resource "azurerm_linux_virtual_machine" "PO_PRD_AP" {
    proximity_placement_group_id    = azurerm_proximity_placement_group.PO.id
    name                            = "PO_PRD_AP"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.PO_PRD_AP.id]
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "PO_PRD_AP_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name                   = "PO PRD AP"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.PO_PRD_AP_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "PO"
    }
}