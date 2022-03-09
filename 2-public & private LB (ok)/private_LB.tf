# Configure the Microsoft Azure Provider

terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 2.65"
        }
    }

    required_version = ">=1.1.0"
}

provider "azurerm"{
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "terraform_lb_vm_group" {
    name = "tf-test-private"
    location = "eastus"

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Avaliability set
resource "azurerm_availability_set" "avset" {
    name                         = "tf-lb-as2"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.terraform_lb_vm_group.name
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    proximity_placement_group_id = azurerm_proximity_placement_group.lbppg.id
    managed                      = true
}

# Create virtual network
resource "azurerm_virtual_network" "terraform_lb_vm_network" {
    name                = "tf_lb_vm_Vnet2"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

## Create subnet (vm1)
#resource "azurerm_subnet" "terraform_lb_vm1_subnet" {
#    name                 = "tf_lb_vm1_Subnet2"
#    resource_group_name  = azurerm_resource_group.terraform_lb_vm_group.name
#    virtual_network_name = azurerm_virtual_network.terraform_lb_vm_network.name
#    address_prefixes       = ["10.0.1.0/24"]
#}

## Create subnet (vm2)
#resource "azurerm_subnet" "terraform_lb_vm2_subnet" {
#    name                 = "tf_lb_vm2_Subnet2"
#    resource_group_name  = azurerm_resource_group.terraform_lb_vm_group.name
#    virtual_network_name = azurerm_virtual_network.terraform_lb_vm_network.name
#    address_prefixes       = ["10.0.2.0/24"]
#}

# Create subnet (lb)
resource "azurerm_subnet" "terraform_lb_subnet" {
    name                 = "tf_lb_Subnet2"
    resource_group_name  = azurerm_resource_group.terraform_lb_vm_group.name
    virtual_network_name = azurerm_virtual_network.terraform_lb_vm_network.name
    address_prefixes       = ["10.0.3.0/24"]
}

# Create network interface (vm1)
resource "azurerm_network_interface" "terraform_lb_vm1_nic" {
    name                      = "tf_lb_vm1_NIC2"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.terraform_lb_vm_group.name

    ip_configuration {
        name                          = "tf_lb_vm1_NicConfiguration2"
        subnet_id                     = azurerm_subnet.terraform_lb_subnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create network interface (vm2)
resource "azurerm_network_interface" "terraform_lb_vm2_nic" {
    name                      = "tf_lb_vm2_NIC2"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.terraform_lb_vm_group.name

    ip_configuration {
        name                          = "tf_lb_vm2_NicConfiguration2"
        subnet_id                     = azurerm_subnet.terraform_lb_subnet.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create Network Security Group and rule (vm1)
resource "azurerm_network_security_group" "terraform_lb_vm1_nsg" {
    name                = "tf_lb_vm1_NetworkSecurityGroup2"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    
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
        environment = "Terraform lb-as-2vm"
    }
}

# Create Network Security Group and rule (vm2)
resource "azurerm_network_security_group" "terraform_lb_vm2_nsg" {
    name                = "tf_lb_vm2_NetworkSecurityGroup2"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    
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
        environment = "Terraform lb-as-2vm"
    }
}

# Connect the security group to the network interface (vm1)
resource "azurerm_network_interface_security_group_association" "vm1" {
    network_interface_id      = azurerm_network_interface.terraform_lb_vm1_nic.id
    network_security_group_id = azurerm_network_security_group.terraform_lb_vm1_nsg.id
}

# Connect the security group to the network interface (vm2)
resource "azurerm_network_interface_security_group_association" "vm2" {
    network_interface_id      = azurerm_network_interface.terraform_lb_vm2_nic.id
    network_security_group_id = azurerm_network_security_group.terraform_lb_vm2_nsg.id
}

# Generate random text for a unique storage account name (vm1)
resource "random_id" "randomId_vm1" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.terraform_lb_vm_group.name
    }
    
    byte_length = 8
}

# Generate random text for a unique storage account name (vm2)
resource "random_id" "randomId_vm2" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.terraform_lb_vm_group.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics (vm1)
resource "azurerm_storage_account" "vm1_storage_account" {
    name                        = "diag${random_id.randomId_vm1.hex}"
    resource_group_name         = azurerm_resource_group.terraform_lb_vm_group.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create storage account for boot diagnostics (vm2)
resource "azurerm_storage_account" "vm2_storage_account" {
    name                        = "diag${random_id.randomId_vm2.hex}"
    resource_group_name         = azurerm_resource_group.terraform_lb_vm_group.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create public IPs (NAT)
resource "azurerm_public_ip" "example" {
    name                = "nat-gateway_publicIP"
    location            = "eastus" 
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    allocation_method   = "Static"
    sku                 = "Standard"
  
    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

resource "azurerm_nat_gateway" "nat_vmms_outbound" {
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    location = "eastus"
    name = "nat-vmss-outbound"
    
    idle_timeout_in_minutes = 15
    sku_name = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip" {
  nat_gateway_id        = azurerm_nat_gateway.nat_vmms_outbound.id
  public_ip_address_id  = azurerm_public_ip.example.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_vmss_subnet" {
  nat_gateway_id = azurerm_nat_gateway.nat_vmms_outbound.id
  subnet_id      = azurerm_subnet.terraform_lb_subnet.id  
}

#Load Balancer
resource "azurerm_lb" "alb-01" {
    name                = "LB-instance2"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    sku                 = "Standard"
    frontend_ip_configuration {
    name                          = "LB-FIA2"
    # public_ip_address_id          = azurerm_public_ip.terraform_lb_publicip.id
    subnet_id                     = azurerm_subnet.terraform_lb_subnet.id
    private_ip_address            = "10.0.3.6"
    private_ip_address_allocation = "Static"
  }
}

# Backend address pool
resource "azurerm_lb_backend_address_pool" "abp-01" {
    name                = "BackendPool12"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    loadbalancer_id     = azurerm_lb.alb-01.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm1" {
    network_interface_id    = azurerm_network_interface.terraform_lb_vm1_nic.id
    ip_configuration_name   = "tf_lb_vm1_NicConfiguration2"
    backend_address_pool_id = azurerm_lb_backend_address_pool.abp-01.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2" {
    network_interface_id    = azurerm_network_interface.terraform_lb_vm2_nic.id
    ip_configuration_name   = "tf_lb_vm2_NicConfiguration2"
    backend_address_pool_id = azurerm_lb_backend_address_pool.abp-01.id
}

# Probe
resource "azurerm_lb_probe" "albp-01" {
    name                = "LB-HP2"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name
    port                = 80
    # protocol            = "tcp"
    interval_in_seconds = 5
    number_of_probes    = 2
    loadbalancer_id     = azurerm_lb.alb-01.id
    protocol            = "Http"
    request_path        = "/"
}

# Loadbalancing rule
resource "azurerm_lb_rule" "albrule-01" {
    name                            = "LB-R2"
    resource_group_name             = azurerm_resource_group.terraform_lb_vm_group.name
    backend_address_pool_id         = azurerm_lb_backend_address_pool.abp-01.id 
    probe_id                        = azurerm_lb_probe.albp-01.id
    protocol                        = "tcp"
    backend_port                    = 80
    frontend_port                   = 80
    idle_timeout_in_minutes         = 15
    frontend_ip_configuration_name  = "LB-FIA2"
    loadbalancer_id                 = azurerm_lb.alb-01.id
}

locals {
  custom_data = <<CUSTOM_DATA
#!/bin/bash
sudo apt-get update -y
sudo apt-get install git -y
cd /
sudo git clone https://github.com/xiehuangjun/terraform.git
cd /terraform/script
sudo sh Ubuntu_install_nginx.sh
CUSTOM_DATA
}

locals {
  custom_data1 = <<CUSTOM_DATA
#!/bin/bash
sudo apt-get update -y
sudo apt-get install git -y
cd /
sudo git clone https://github.com/xiehuangjun/terraform.git
cd /terraform/script
sudo sh Ubuntu_install_apache2.sh
CUSTOM_DATA
}

resource "azurerm_proximity_placement_group" "lbppg" {
    name                = "LB-PPG2"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraform_lb_vm_group.name

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create virtual machine (vm1)
resource "azurerm_linux_virtual_machine" "terraform_vm1" {
    name                            = "tf_lb_VM12"
    location                        = "eastus"
    resource_group_name             = azurerm_resource_group.terraform_lb_vm_group.name
    network_interface_ids           = [azurerm_network_interface.terraform_lb_vm1_nic.id]
    availability_set_id             = azurerm_availability_set.avset.id
    size                            = "Standard_DS1_v2"

    os_disk {
        name              = "vm1_OsDisk2"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "tf-lb-vm1"
    admin_username = "hj"
    admin_password = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.vm1_storage_account.primary_blob_endpoint
    }

    custom_data = base64encode(local.custom_data)

    tags = {
        environment = "Terraform lb-as-2vm"
    }
}

# Create virtual machine (vm2)
resource "azurerm_linux_virtual_machine" "terraform_vm2" {
    name                  = "tf_lb_VM22"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.terraform_lb_vm_group.name
    network_interface_ids = [azurerm_network_interface.terraform_lb_vm2_nic.id]
    availability_set_id   = azurerm_availability_set.avset.id
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "vm2_OsDisk2"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "tf-lb-vm2"
    admin_username = "hj"
    admin_password = "Password1234!"
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.vm2_storage_account.primary_blob_endpoint
    }

    custom_data = base64encode(local.custom_data1)
    
    tags = {
        environment = "Terraform lb-as-2vm"
    }
}