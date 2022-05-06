provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# waf policy for route /app-a
resource "azurerm_web_application_firewall_policy" "app-a" {
  name                = "app-a-waf-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = {
    target_app = "app-a"
  }

  custom_rules {
    name      = "block_windows_user_agent"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }

}

# waf policy for route /app-b
resource "azurerm_web_application_firewall_policy" "app-b" {
  name                = "app-b-waf-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = {
    target_app = "app-b"
  }

  custom_rules {
    name      = "block_curl_user_agent"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["curl"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }

}