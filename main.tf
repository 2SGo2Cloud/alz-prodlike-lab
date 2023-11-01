data "azurerm_client_config" "current" {}

module "alz_core" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "~> 5.0"

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  root_parent_id    = var.root_parent_id
  root_id           = var.root_id
  root_name         = var.root_name
  disable_telemetry = true
  library_path      = "${path.module}/lib"
  default_location  = var.default_location

  subscription_id_connectivity    = var.subscription_id
  subscription_id_management      = var.subscription_id
  subscription_id_identity        = var.subscription_id
  strict_subscription_association = false

  deploy_core_landing_zones     = true
  deploy_online_landing_zones   = true
  deploy_corp_landing_zones     = true
  deploy_identity_resources     = true
  deploy_management_resources   = true
  deploy_connectivity_resources = false

  custom_landing_zones = local.custom_landing_zones

  # Not necessary
  deploy_demo_landing_zones = false
  deploy_sap_landing_zones  = false
}
