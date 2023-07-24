# Definition of the providers, then we run terrafomr init to apply the config

#Let's create our ACR in a separate Resource group as suggested in the Best practices

#1. create the rg using var file
resource "azurerm_resource_group" "rg_acr" {
    name = var.rg_acr
    location = var.location

  
}

#deploy the acr resource on the rg created with the admin enabled
resource "azurerm_container_registry" "acr" {
    name = "acrlabfran"
    resource_group_name = var.rg_acr
    location = var.location
    sku = "Basic"
    #add the following option to allow the login with user and pass
    admin_enabled = true

  
}

#create the vnet and the subnets and rg

# we will use the following rg for all the future deployments
resource "azurerm_resource_group" "rg_compute" {
  name = var.rg_compute
  location = var.location
  
}

#We will use the following vnet for furutre deployments
resource "azurerm_virtual_network" "vnet_prac2" {
  name = var.vnet
  address_space = ["10.0.0.0/16"]
  location = var.location
  resource_group_name = var.rg_compute
  
}

#will use the following subnet for further deployments
resource "azurerm_subnet" "subnet_prac2" {
  name = var.subnet
  resource_group_name = var.rg_compute
  virtual_network_name = var.vnet
  address_prefixes =["10.0.1.0/24"]
  
  
}

#create a nsg to manage the connectivity of the resources, adding the ssh rule to acces the vm
resource "azurerm_network_security_group" "prac2_nsg" {
  name = var.nsg
  location = var.location
  resource_group_name = var.rg_compute

  security_rule {# security rule que permite el acceso al puerto 22
    name                       = "conexion_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {# security rule que permite el acceso al puerto 443 solo en la ip de la vm
    name                       = "conexion_443"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}

#Creamos 2 public ip's para las maquinas

 

# Create public IPs
resource "azurerm_public_ip" "publicipweb" {

  name                = "pulicip-web"
  location            = var.location
  resource_group_name = var.rg_compute
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "publicipansible" {

  name                = "pulicip-ansible"
  location            = var.location
  resource_group_name = var.rg_compute
  allocation_method   = "Static"
}

#creamos la nic para la VM de ansible y para la vm web y les atacheamos public ip's
resource "azurerm_network_interface" "nic_web" {
    name = "nic-web"
    location = var.location
    resource_group_name = var.rg_compute

    ip_configuration {
        name = "nic-web-config"
        subnet_id=azurerm_subnet.subnet_prac2.id
        private_ip_address_allocation = "Static"
        public_ip_address_id = azurerm_public_ip.publicipweb.id
      
    }  
}

resource "azurerm_network_interface" "nic_ansible" {
    name = "nic-ansible"
    location = var.location
    resource_group_name = var.rg_compute

    ip_configuration {
        name = "nic-ansible-config"
        subnet_id=azurerm_subnet.subnet_prac2.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.publicipansible.id
      
    }
}

#añadimos las dos nics al Sg

resource "azurerm_network_interface_security_group_association" "web-nic" {
    network_interface_id = azurerm_network_interface.nic_web.id
    network_security_group_id = azurerm_network_security_group.prac2_nsg.id
  
}

resource "azurerm_network_interface_security_group_association" "ansible-nic" {
    network_interface_id = azurerm_network_interface.nic_ansible.id
    network_security_group_id = azurerm_network_security_group.prac2_nsg.id
  
}

#creamos una clave ssh con ssh-keygen en el terminal local
#

#creamos la vm web

resource "azurerm_linux_virtual_machine" "vm-web" {
  name                  = "vm-web"
  location              = var.location
  resource_group_name   = var.rg_compute
  network_interface_ids = [azurerm_network_interface.nic_web.id]
  size                  = "Standard_B1ms"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

#con esta config nos conectamos como azureuser a la VM con las claves generadas anteriormente en local
  computer_name                   = "vm-web"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Fran/.ssh/id_rsa.pub")
  }

}


#creamos la vm de ansible:

resource "azurerm_linux_virtual_machine" "vm-ansible" {
  name                  = "vm-ansible"
  location              = var.location
  resource_group_name   = var.rg_compute
  network_interface_ids = [azurerm_network_interface.nic_ansible.id]
  size                  = "Standard_B1ms"

  os_disk {
    name                 = "ansibleDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  
# CON ESTA INYECTOS EL SCRIPT EN LA VM, the script can be found in this directory "ansible.sh":

custom_data = filebase64("ansible.sh")# specify the directory in case it is not here




#con esta config nos conectamos como azureuser a la VM con las claves generadas anteriormente en local
  computer_name                   = "vm-ansible"
  admin_username                  = "franky"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "franky"
    public_key = file("C:/Users/Fran/.ssh/id_rsa.pub")
  }
  

}


####LET'S CREATE THE AKS

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = var.location
  name                = "fran_aks"
  resource_group_name = var.rg_compute
  dns_prefix=  "fran"

default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = 1
  }

   identity {
    type = "SystemAssigned"
  }
}

#atacheando container con aks de esta forma hacemos que el cluster tenga acceso al repositorio previamente ccreado

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}










#Once the resources are defined lets run tf plan and then terraform apply