resource "azurerm_proximity_placement_group" "PO" {
    name                = "PO_PPG"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name

    tags = {
        environment = "PO"
    }
}


#-----------------PO HANA PRD-----------------


# Avaliability set
resource "azurerm_availability_set" "PO_HANA_PRD" {
    name                         = "PO_HANA_PRD"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.SAP.name
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    proximity_placement_group_id = azurerm_proximity_placement_group.PO.id
    managed                      = true
}

# Create subnet (lb)
resource "azurerm_subnet" "PO_HANA_PRD_Subnet" {
    name                 = "PO_HANA_PRD_Subnet"
    resource_group_name  = azurerm_resource_group.SAP.name
    virtual_network_name = azurerm_virtual_network.PRD_Vnet.name
    address_prefixes       = ["10.1.101.0/24"]
}

# Create network interface (PO_HANA_PRD_1)
resource "azurerm_network_interface" "PO_HANA_PRD_1" {
    name                      = "PO_HANA_PRD_1"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "PO_HANA_PRD_1_NicConfiguration"
        subnet_id                     = azurerm_subnet.PO_HANA_PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.101.5"
    }

    tags = {
        environment = "PO"
    }
}

# Create network interface (PO_HANA_PRD_2)
resource "azurerm_network_interface" "PO_HANA_PRD_2" {
    name                      = "PO_HANA_PRD_2"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.SAP.name

    ip_configuration {
        name                          = "PO_HANA_PRD_2_NicConfiguration"
        subnet_id                     = azurerm_subnet.PO_HANA_PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.101.6"
    }

    tags = {
        environment = "PO"
    }
}

# Create Network Security Group and rule (PO_HANA_PRD_1)
resource "azurerm_network_security_group" "PO_HANA_PRD_1_NSG" {
    name                = "PO_HANA_PRD_1_NSG"
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

# Create Network Security Group and rule (PO_HANA_PRD_2)
resource "azurerm_network_security_group" "PO_HANA_PRD_2_NSG" {
    name                = "PO_HANA_PRD_2_NSG"
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
        environment = "PO"
    }
}

# Connect the security group to the network interface (PO_HANA_PRD_1)
resource "azurerm_network_interface_security_group_association" "PO_HANA_PRD_1" {
    network_interface_id      = azurerm_network_interface.PO_HANA_PRD_1.id
    network_security_group_id = azurerm_network_security_group.PO_HANA_PRD_1_NSG.id
}

# Connect the security group to the network interface (PO_HANA_PRD_2)
resource "azurerm_network_interface_security_group_association" "PO_HANA_PRD_2" {
    network_interface_id      = azurerm_network_interface.PO_HANA_PRD_2.id
    network_security_group_id = azurerm_network_security_group.PO_HANA_PRD_2_NSG.id
}

# Generate random text for a unique storage account name (PO_HANA_PRD_1)
resource "random_id" "Random_PO_HANA_PRD_1" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Generate random text for a unique storage account name (PO_HANA_PRD_2)
resource "random_id" "Random_PO_HANA_PRD_2" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.SAP.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (PO_HANA_PRD_1)
resource "azurerm_storage_account" "PO_HANA_PRD_1_storage_account" {
    name                        = "diag${random_id.Random_PO_HANA_PRD_1.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PO"
    }
}

# Create storage account for boot diagnostics (PO_HANA_PRD_2)
resource "azurerm_storage_account" "PO_HANA_PRD_2_storage_account" {
    name                        = "diag${random_id.Random_PO_HANA_PRD_2.hex}"
    resource_group_name         = azurerm_resource_group.SAP.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "PO"
    }
}

# Create public IPs (NAT)
resource "azurerm_public_ip" "PO_external" {
    name                = "PO-nat-gateway-publicIP"
    location            = var.location 
    resource_group_name = azurerm_resource_group.SAP.name
    allocation_method   = "Static"
    sku                 = "Standard"
  
    tags = {
        environment = "PO"
    }
}

resource "azurerm_nat_gateway" "nat_PO_outbound" {
    resource_group_name     = azurerm_resource_group.SAP.name
    location                = var.location
    name                    = "PO-nat-outbound"
    
    idle_timeout_in_minutes = 15
    sku_name                = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "PO_HANA_PRD_nat_pip" {
    nat_gateway_id        = azurerm_nat_gateway.nat_PO_outbound.id
    public_ip_address_id  = azurerm_public_ip.PO_external.id
}

resource "azurerm_subnet_nat_gateway_association" "PO_HANA_PRD_nat_subnet" {
    nat_gateway_id = azurerm_nat_gateway.nat_PO_outbound.id
    subnet_id      = azurerm_subnet.PO_HANA_PRD_Subnet.id  
}

#Load Balancer
resource "azurerm_lb" "PO_HANA_PRD_LB" {
    name                = "PO_HANA_PRD_LB"
    location            = var.location
    resource_group_name = azurerm_resource_group.SAP.name
    sku                 = "Standard"
    frontend_ip_configuration {
        name                          = "PO_HANA_PRD_LB_FIA"
        subnet_id                     = azurerm_subnet.PO_HANA_PRD_Subnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.1.101.7"
  }
}

# Backend address pool
resource "azurerm_lb_backend_address_pool" "PO_HANA_PRD_BAP" {
    name                = "PO_HANA_PRD_BAP"
    resource_group_name = azurerm_resource_group.SAP.name
    loadbalancer_id     = azurerm_lb.PO_HANA_PRD_LB.id
}

resource "azurerm_network_interface_backend_address_pool_association" "PO_HANA_PRD_1" {
    network_interface_id    = azurerm_network_interface.PO_HANA_PRD_1.id
    ip_configuration_name   = "PO_HANA_PRD_1_NicConfiguration"
    backend_address_pool_id = azurerm_lb_backend_address_pool.PO_HANA_PRD_BAP.id
}

resource "azurerm_network_interface_backend_address_pool_association" "PO_HANA_PRD_2" {
    network_interface_id    = azurerm_network_interface.PO_HANA_PRD_2.id
    ip_configuration_name   = "PO_HANA_PRD_2_NicConfiguration"
    backend_address_pool_id = azurerm_lb_backend_address_pool.PO_HANA_PRD_BAP.id
}

# Probe
resource "azurerm_lb_probe" "PO_HANA_PRD_Probe" {
    name                = "PO_HANA_PRD_Probe"
    resource_group_name = azurerm_resource_group.SAP.name
    port                = 80
    interval_in_seconds = 5
    number_of_probes    = 2
    loadbalancer_id     = azurerm_lb.PO_HANA_PRD_LB.id
    protocol            = "Http"
    request_path        = "/"
}

# Loadbalancing rule
resource "azurerm_lb_rule" "PO_HANA_PRD_LB_Rule" {
    name                            = "PO_HANA_PRD_LB_Rule"
    resource_group_name             = azurerm_resource_group.SAP.name
    backend_address_pool_id         = azurerm_lb_backend_address_pool.PO_HANA_PRD_BAP.id 
    probe_id                        = azurerm_lb_probe.PO_HANA_PRD_Probe.id
    protocol                        = "tcp"
    backend_port                    = 80
    frontend_port                   = 80
    idle_timeout_in_minutes         = 15
    frontend_ip_configuration_name  = "PO_HANA_PRD_LB_FIA"
    loadbalancer_id                 = azurerm_lb.PO_HANA_PRD_LB.id
}

# Create virtual machine (PO_HANA_PRD_1)
resource "azurerm_linux_virtual_machine" "PO_HANA_PRD_1" {
    name                            = "PO_HANA_PRD_1"
    location                        = var.location
    resource_group_name             = azurerm_resource_group.SAP.name
    network_interface_ids           = [azurerm_network_interface.PO_HANA_PRD_1.id]
    availability_set_id             = azurerm_availability_set.PO_HANA_PRD.id
    size                            = "Standard_DS1_v2"

    os_disk {
        name                    = "PO_HANA_PRD_1_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "SUSE"
        offer     = "sles-sap-15-sp3"
        sku       = "gen2"
        version   = "2022.01.26"
    }

    computer_name                   = "PO HANA PRD 1"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.PO_HANA_PRD_1_storage_account.primary_blob_endpoint
    }

    tags = {
        environment = "PO"
    }
}

# Create virtual machine (PO_HANA_PRD_2)
resource "azurerm_linux_virtual_machine" "PO_HANA_PRD_2" {
    name                  = "PO_HANA_PRD_2"
    location              = var.location
    resource_group_name   = azurerm_resource_group.SAP.name
    network_interface_ids = [azurerm_network_interface.PO_HANA_PRD_2.id]
    availability_set_id   = azurerm_availability_set.PO_HANA_PRD.id
    size                  = "Standard_DS1_v2"

    os_disk {
        name                    = "PO_HANA_PRD_2_OsDisk"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "SUSE"
        offer     = "sles-sap-15-sp3"
        sku       = "gen2"
        version   = "2022.01.26"
    }

    computer_name                   = "PO HANA PRD 2"
    admin_username                  = "hj"
    admin_password                  = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.PO_HANA_PRD_2_storage_account.primary_blob_endpoint
    }

    tags = {
        environment = "PO"
    }
}