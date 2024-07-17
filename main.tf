# Ressource groupe
resource "azurerm_resource_group" "rg" {
  name     = "resources_VM_ImportCSV"
  location = "West Europe"
}

# Réseau virtuel
resource "azurerm_virtual_network" "vnet" {
  name                = "Myvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "Mysubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Adresse IP publique
resource "azurerm_public_ip" "public_ip" {
  name                = "Mypublic-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Interface réseau
resource "azurerm_network_interface" "nic" {
  name                = "Mynic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Machine virtuelle
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "MYvm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = var.username
  admin_password = var.password

  disable_password_authentication = false
}

# Provisioner pour copier le fichier CSV
resource "null_resource" "copy_csv" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  provisioner "file" {
    source      = "C:/Users/Utilisateur/Downloads/Nouveau dossier/list_customers_dataset.csv"
    destination = "/home/adminuser/csvfile.csv"

    connection {
      type     = "ssh"
      host     = azurerm_public_ip.public_ip.ip_address
      user     = "adminuser"
      password = "Password1234!"
    }
  }
}

# Provisioner pour copier le script Python
resource "null_resource" "copy_python_script" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  provisioner "file" {
    source      = "C:/Users/Utilisateur/Documents/vscode/examdevop/import_csv.py"
    destination = "/home/adminuser/import_csv.py"

    connection {
      type     = "ssh"
      host     = azurerm_public_ip.public_ip.ip_address
      user     = "adminuser"
      password = "Password1234!"
    }
  }
}

# Provisioner pour exécuter le script Python
resource "null_resource" "import_csv" {
  depends_on = [null_resource.copy_csv, null_resource.copy_python_script]

  provisioner "remote-exec" {
    inline = [
      "sleep 10",  # Ajoutez un délai pour garantir la copie des fichiers
      "echo 'Listing directory...'",
      "ls -l /home/adminuser/",
      "echo 'Updating package list...'",
      "sudo apt-get update",
      "echo 'Installing python3-pip...'",
      "sudo apt-get install -y python3-pip",
      "echo 'Installing pandas...'",
      "pip3 install pandas",
      "echo 'Running Python script...'",
      "python3 /home/adminuser/import_csv.py"
    ]

    connection {
      type     = "ssh"
      host     = azurerm_public_ip.public_ip.ip_address
      user     = var.username
      password = var.password
    }
  }
}  
