locals {
  name_prefix = "${var.env_name}-plane"
  uaa_name_prefix = "${var.env_name}-uaa"
  credhub_name_prefix = "${var.env_name}-credhub"
  web_ports   = [80, 443, 8443, 8844, 2222]
}

# DNS

resource "azurerm_dns_a_record" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "plane"
  zone_name           = "${var.dns_zone_name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.plane.ip_address}"]
}

resource "azurerm_dns_a_record" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "uaa"
  zone_name           = "${var.dns_zone_name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.uaa.ip_address}"]
}

resource "azurerm_dns_a_record" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "credhub"
  zone_name           = "${var.dns_zone_name}"
  ttl                 = "60"
  records             = ["${azurerm_public_ip.credhub.ip_address}"]
}

# Load Balancers

resource "azurerm_public_ip" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.name_prefix}-ip"
  location            = "${var.location}"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.uaa_name_prefix}-ip"
  location            = "${var.location}"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.credhub_name_prefix}-ip"
  location            = "${var.location}"
  allocation_method   = "Static"
}

resource "azurerm_lb" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${var.env_name}-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                 = "${local.name_prefix}-ip"
    public_ip_address_id = "${azurerm_public_ip.plane.id}"
  }
}
resource "azurerm_lb" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.uaa_name_prefix}-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                 = "${local.uaa_name_prefix}-ip"
    public_ip_address_id = "${azurerm_public_ip.uaa.id}"
  }
}

resource "azurerm_lb" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.credhub_name_prefix}-lb"
  location            = "${var.location}"

  frontend_ip_configuration {
    name                 = "${local.credhub_name_prefix}-ip"
    public_ip_address_id = "${azurerm_public_ip.credhub.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "plane" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.name_prefix}-pool"
  loadbalancer_id     = "${azurerm_lb.plane.id}"
}

resource "azurerm_lb_backend_address_pool" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.uaa_name_prefix}-pool"
  loadbalancer_id     = "${azurerm_lb.uaa.id}"
}

resource "azurerm_lb_backend_address_pool" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "${local.credhub_name_prefix}-pool"
  loadbalancer_id     = "${azurerm_lb.credhub.id}"
}

resource "azurerm_lb_probe" "plane" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.name_prefix}-${element(local.web_ports, count.index)}-probe"

  port     = "${element(local.web_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.plane.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.uaa_name_prefix}-${element(local.web_ports, count.index)}-probe"

  port     = "${element(local.web_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.uaa.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.credhub_name_prefix}-${element(local.web_ports, count.index)}-probe"

  port     = "${element(local.web_ports, count.index)}"
  protocol = "Tcp"

  loadbalancer_id     = "${azurerm_lb.credhub.id}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "plane" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.name_prefix}-${element(local.web_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.plane.id}"
  frontend_port                  = "${element(local.web_ports, count.index)}"
  backend_port                   = "${element(local.web_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.plane.id}"
  frontend_ip_configuration_name = "${azurerm_public_ip.plane.name}"
  probe_id                       = "${element(azurerm_lb_probe.plane.*.id, count.index)}"
}

resource "azurerm_lb_rule" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.uaa_name_prefix}-${element(local.web_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.uaa.id}"
  frontend_port                  = "${element(local.web_ports, count.index)}"
  backend_port                   = "${element(local.web_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.uaa.id}"
  frontend_ip_configuration_name = "${azurerm_public_ip.uaa.name}"
  probe_id                       = "${element(azurerm_lb_probe.uaa.*.id, count.index)}"
}

resource "azurerm_lb_rule" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  count               = "${length(local.web_ports)}"
  name                = "${local.credhub_name_prefix}-${element(local.web_ports, count.index)}"

  protocol                       = "Tcp"
  loadbalancer_id                = "${azurerm_lb.credhub.id}"
  frontend_port                  = "${element(local.web_ports, count.index)}"
  backend_port                   = "${element(local.web_ports, count.index)}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.credhub.id}"
  frontend_ip_configuration_name = "${azurerm_public_ip.credhub.name}"
  probe_id                       = "${element(azurerm_lb_probe.credhub.*.id, count.index)}"
}

# Firewall

resource "azurerm_network_security_group" "plane" {
  name                = "${local.name_prefix}-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_group" "uaa" {
  name                = "${local.uaa_name_prefix}-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_group" "credhub" {
  name                = "${local.credhub_name_prefix}-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "plane" {
  resource_group_name = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.plane.name}"

  name                       = "${local.name_prefix}-security-group-rule"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.web_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.uaa.name}"

  name                       = "${local.uaa_name_prefix}-security-group-rule"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.web_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.credhub.name}"

  name                       = "${local.credhub_name_prefix}-security-group-rule"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = "${local.web_ports}"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Network

resource "azurerm_subnet" "plane" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${var.network_name}"
  address_prefix       = "${var.cidr}"
}

# Database

resource "azurerm_postgresql_server" "plane" {
  name                = "${local.name_prefix}-postgres"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"

  sku {
    name     = "B_Gen5_2"
    capacity = 2
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 10240
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${var.postgres_username}"
  administrator_login_password = "${random_string.postgres_password.result}"
  version                      = "9.6"
  ssl_enforcement              = "Enabled"

  count = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_firewall_rule" "plane" {
  name                = "${local.name_prefix}-postgres-firewall"
  resource_group_name = "${var.resource_group_name}"
  server_name         = "${element(azurerm_postgresql_server.plane.*.name, 0)}"

  # Note, these only refer to internal AZURE IPs and not external
  # access from anywhere. Please don't change them unless you know
  # what you are doing. See terraform docs for details

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
  count            = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "atc" {
  resource_group_name = "${var.resource_group_name}"
  name                = "atc"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  count = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "credhub" {
  resource_group_name = "${var.resource_group_name}"
  name                = "credhub"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  depends_on = ["azurerm_postgresql_database.atc"]
  count      = "${var.external_db ? 1 : 0}"
}

resource "azurerm_postgresql_database" "uaa" {
  resource_group_name = "${var.resource_group_name}"
  name                = "uaa"

  server_name = "${azurerm_postgresql_server.plane.name}"
  charset     = "UTF8"
  collation   = "English_United States.1252"

  depends_on = ["azurerm_postgresql_database.credhub"]
  count      = "${var.external_db ? 1 : 0}"
}

resource "random_string" "postgres_password" {
  length  = 16
  special = false
}

# Storage

resource random_string "control_plane_storage_account_name" {
  length  = 20
  special = false
  upper   = false
}
resource "azurerm_storage_account" "control_plane_storage_account" {
  name                     = "${random_string.control_plane_storage_account_name.result}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "${var.env_name}"
    account_for = "bosh"
  }
}

resource "azurerm_storage_container" "products_storage_container" {
  name                  = "products"
  depends_on            = ["azurerm_storage_account.control_plane_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.control_plane_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups_storage_container" {
  name                  = "backups"
  depends_on            = ["azurerm_storage_account.control_plane_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.control_plane_storage_account.name}"
  container_access_type = "private"
}

resource "azurerm_storage_container" "state_storage_container" {
  name                  = "state"
  depends_on            = ["azurerm_storage_account.control_plane_storage_account"]
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${azurerm_storage_account.control_plane_storage_account.name}"
  container_access_type = "private"
}
