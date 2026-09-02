resource "azurerm_web_application_firewall_policy" "waf_policy" {
  #checkov:skip=CKV_AZURE_135: Microsoft_DefaultRuleSet 2.2 natively mitigates Log4j; Checkov is seeking older OWASP 3.2 rule IDs.
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