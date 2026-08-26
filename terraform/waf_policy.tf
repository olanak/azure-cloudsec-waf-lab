resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "waf-pol-cloudsec-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  policy_settings {
    enabled            = true
    mode               = "Detection"
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      # Microsoft Default Rule Set (OWASP Baseline + Microsoft Threat Intel)
      type    = "Microsoft_DefaultRuleSet"
      version = "2.2"
    }
  }

}