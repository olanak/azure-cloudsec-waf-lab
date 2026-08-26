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