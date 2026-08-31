resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "pip-appgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-cloudsec-lab-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.snet-appgw.id
  }

  probe {
    name                                      = "dvwa-health-probe"
    protocol                                  = "Http"
    host                                      = "127.0.0.1"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    match {
      status_code = ["200-399"]
    }
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.appgw_public_ip.id
  }


  backend_address_pool {
    name = "dvwa-backend-pool"
  }


  backend_http_settings {
    name                  = "http-settings-80"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    probe_name            = "dvwa-health-probe"
  }

  http_listener {
    name                           = "listener-80"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule-80"
    rule_type                  = "Basic"
    http_listener_name         = "listener-80"
    backend_address_pool_name  = "dvwa-backend-pool"
    backend_http_settings_name = "http-settings-80"
    priority                   = 100
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw_nic_association" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nic-dvwa[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
}


