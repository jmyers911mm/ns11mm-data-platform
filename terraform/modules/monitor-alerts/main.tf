resource "azurerm_monitor_action_group" "ns11mm_alerts" {
  name                = "ag-ns11mm-data-platform"
  resource_group_name = var.resource_group_name
  short_name          = "ns11mm"

  email_receiver {
    name          = "Jeremy Myers"
    email_address = var.alert_email
  }

  webhook_receiver {
    name        = "teams-webhook"
    service_uri = var.teams_webhook_url
  }
}
