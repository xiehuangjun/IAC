#-----------------S4 HANA PRD ASCS-----------------


# Avaliability set
resource "azurerm_availability_set" "S4_HANA_PRD_ASCS" {
    name                         = "S4_HANA_PRD_ASCS"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.SAP.name
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    proximity_placement_group_id = azurerm_proximity_placement_group.S4_HANA.id
    managed                      = true
}

# Create subnet (lb)
resource "azurerm_subnet" "S4_HANA_PRD_ASCS_Subnet" {
    name                 = "S4_HANA_PRD_ASCS_Subnet"
    resource_group_name  = azurerm_resource_group.SAP.name
    virtual_network_name = azurerm_virtual_network.PRD_Vnet.name
    address_prefixes       = ["10.1.103.0/24"]
}

# Create network interface (S4_HANA_PRD_ASCS_1)
resource "azurerm_network_interface" "S4_HANA_PRD_ASCS_1" {
    name                      = "S4_HANA_PRD_ASCS_1"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "S4_HANA_PRD_ASCS_1_NicConfiguration"
        subnet_id                     = azurerm_subnet.S4_HANA_PRD_ASCS_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.103.5"
    }

    tags = {
        environment = "S4_HANA"
    }
}

# Create network interface (S4_HANA_PRD_ASCS_2)
resource "azurerm_network_interface" "S4_HANA_PRD_ASCS_2" {
    name                      = "S4_HANA_PRD_ASCS_2"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "S4_HANA_PRD_ASCS_2_NicConfiguration"
        subnet_id                     = azurerm_subnet.S4_HANA_PRD_ASCS_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.103.6"
    }

    tags = {
        environment = "S4_HANA"
    }
}

# Create Network Security Group and rule (S4_HANA_PRD_ASCS_1)
resource "azurerm_network_security_group" "S4_HANA_PRD_ASCS_1_NSG" {
    name                = "S4_HANA_PRD_ASCS_1_NSG"
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

# Create Network Security Group and rule (S4_HANA_PRD_ASCS_2)
resource "azurerm_network_security_group" "S4_HANA_PRD_ASCS_2_NSG" {
    name                = "S4_HANA_PRD_ASCS_2_NSG"
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
        name                       = "APACHE2"
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

# Connect the security group to the network interface (S4_HANA_PRD_ASCS_1)
resource "azurerm_network_interface_security_group_association" "S4_HANA_PRD_ASCS_1" {
    network_interface_id      = azurerm_network_interface.S4_HANA_PRD_ASCS_1.id
    network_security_group_id = azurerm_network_security_group.S4_HANA_PRD_ASCS_1_NSG.id
}

# Connect the security group to the network interface (S4_HANA_PRD_ASCS_2)
resource "azurerm_network_interface_security_group_association" "S4_HANA_PRD_ASCS_2" {
    network_interface_id      = azurerm_network_interface.S4_HANA_PRD_ASCS_2.id
    network_security_group_id = azurerm_network_security_group.S4_HANA_PRD_ASCS_2_NSG.id
}

# Generate random text for a unique storage account name (S4_HANA_PRD_ASCS_1)
resource "random_id" "Random_S4_HANA_PRD_ASCS_1" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Generate random text for a unique storage account name (S4_HANA_PRD_ASCS_2)
resource "random_id" "Random_S4_HANA_PRD_ASCS_2" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (S4_HANA_PRD_ASCS_1)
resource "azurerm_storage_account" "S4_HANA_PRD_ASCS_1_storage_account" {
    name                        = "diag${random_id.Random_S4_HANA_PRD_ASCS_1.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "S4_HANA"
    }
}

# Create storage account for boot diagnostics (S4_HANA_PRD_ASCS_2)
resource "azurerm_storage_account" "S4_HANA_PRD_ASCS_2_storage_account" {
    name                        = "diag${random_id.Random_S4_HANA_PRD_ASCS_2.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "S4_HANA"
    }
}

# Create public IPs (NAT)
resource "azurerm_public_ip" "S4_HANA_PRD_ASCS_external" {
    name                = "S4_HANA_PRD_ASCS_nat_gateway_publicIP"
    location            = var.location 
    resource_group_name = azurerm_resource_group.SAP.name
    allocation_method   = "Static"
    sku                 = "Standard"
  
    tags = {
        environment = "S4_HANA"
    }
}

resource "azurerm_nat_gateway" "S4_HANA_PRD_ASCS_nat_outbound" {
    resource_group_name     = azurerm_resource_group.SAP.name
    location                = var.location
    name                    = "S4_HANA_PRD_ASCS_nat_outbound"
    
    idle_timeout_in_minutes = 15
    sku_name                = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "S4_HANA_PRD_ASCS_nat_pip" {
    nat_gateway_id        = azurerm_nat_gateway.S4_HANA_PRD_ASCS_nat_outbound.id
    public_ip_address_id  = azurerm_public_ip.S4_HANA_PRD_ASCS_external.id
}

resource "azurerm_subnet_nat_gateway_association" "S4_HANA_PRD_ASCS_nat_subnet" {
    nat_gateway_id = azurerm_nat_gateway.S4_HANA_PRD_ASCS_nat_outbound.id
    subnet_id      = azurerm_subnet.S4_HANA_PRD_ASCS_Subnet.id  
}

#Load Balancer
resource "azurerm_lb" "S4_HANA_PRD_ASCS_LB" {
    name                = "S4_HANA_PRD_ASCS_LB"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name
    sku                 = "Standard"
    frontend_ip_configuration {
        name                          = "S4_HANA_PRD_ASCS_LB_FIA"
        subnet_id                     = azurerm_subnet.S4_HANA_PRD_ASCS_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.103.7"
  }
}

# Backend address pool
resource "azurerm_lb_backend_address_pool" "S4_HANA_PRD_ASCS_BAP" {
    name                = "S4_HANA_PRD_ASCS_BAP"
    resource_group_name = azurerm_resource_group.SAP.name
    loadbalancer_id     = azurerm_lb.S4_HANA_PRD_ASCS_LB.id
}

resource "azurerm_network_interface_backend_address_pool_association" "S4_HANA_PRD_ASCS_1" {
    network_interface_id    = azurerm_network_interface.S4_HANA_PRD_ASCS_1.id
    ip_configuration_name   = "S4_HANA_PRD_ASCS_1_NicConfiguration"
    backend_address_pool_id = azurerm_lb_backend_address_pool.S4_HANA_PRD_ASCS_BAP.id
}

resource "azurerm_network_interface_backend_address_pool_association" "S4_HANA_PRD_ASCS_2" {
    network_interface_id    = azurerm_network_interface.S4_HANA_PRD_ASCS_2.id
    ip_configuration_name   = "S4_HANA_PRD_ASCS_2_NicConfiguration"
    backend_address_pool_id = azurerm_lb_backend_address_pool.S4_HANA_PRD_ASCS_BAP.id
}

# Probe
resource "azurerm_lb_probe" "S4_HANA_PRD_ASCS_Probe" {
    name                = "S4_HANA_PRD_ASCS_Probe"
    resource_group_name = azurerm_resource_group.SAP.name
    port                = 80
    interval_in_seconds = 5
    number_of_probes    = 2
    loadbalancer_id     = azurerm_lb.S4_HANA_PRD_ASCS_LB.id
    protocol            = "Http"
    request_path        = "/"
}

# Loadbalancing rule
resource "azurerm_lb_rule" "S4_HANA_PRD_ASCS_LB_Rule" {
    name                            = "S4_HANA_PRD_ASCS_LB_Rule"
    resource_group_name             = azurerm_resource_group.SAP.name
    backend_address_pool_id         = azurerm_lb_backend_address_pool.S4_HANA_PRD_ASCS_BAP.id 
    probe_id                        = azurerm_lb_probe.S4_HANA_PRD_ASCS_Probe.id
    protocol                        = "tcp"
    backend_port                    = 80
    frontend_port                   = 80
    idle_timeout_in_minutes         = 15
    frontend_ip_configuration_name  = "S4_HANA_PRD_ASCS_LB_FIA"
    loadbalancer_id                 = azurerm_lb.S4_HANA_PRD_ASCS_LB.id
}

# Create virtual machine (S4_HANA_PRD_ASCS_1)
resource "azurerm_windows_virtual_machine" "S4_HANA_PRD_ASCS_1" {
    name                            = "S4_HANA_PRD_ASCS_1"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.S4_HANA_PRD_ASCS_1.id]
    availability_set_id             = azurerm_availability_set.S4_HANA_PRD_ASCS.id
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "S4_HANA_PRD_ASCS_1_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter"
        version   = "latest"
    }

    computer_name                   = "S4HANAPRDASCS1"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.S4_HANA_PRD_ASCS_1_storage_account.primary_blob_endpoint
    }

    tags = {
        environment = "S4_HANA"
    }
}

# Create virtual machine (S4_HANA_PRD_ASCS_2)
resource "azurerm_windows_virtual_machine" "S4_HANA_PRD_ASCS_2" {
    name                  = "S4_HANA_PRD_ASCS_2"
    location              = var.location
    resource_group_name   = azurerm_resource_group.SAP.name
    network_interface_ids = [azurerm_network_interface.S4_HANA_PRD_ASCS_2.id]
    availability_set_id   = azurerm_availability_set.S4_HANA_PRD_ASCS.id
    size                  = "Standard_DS1_v2"

    os_disk {
        name                    = "S4_HANA_PRD_ASCS_2_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-datacenter"
        version   = "latest"
    }
    
    computer_name                   = "S4HANAPRDASCS2"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.S4_HANA_PRD_ASCS_2_storage_account.primary_blob_endpoint
    }
    
    tags = {
        environment = "S4_HANA"
    }
}