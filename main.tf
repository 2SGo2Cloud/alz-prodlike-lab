data "azurerm_client_config" "current" {}

data "azurerm_management_group" "tenant_root_group" {
  display_name = "Tenant Root Group"
}

module "alz_core" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "~> 5.0"

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  root_parent_id    = var.root_parent_id != "" ? var.root_parent_id : data.azurerm_management_group.tenant_root_group.id
  root_id           = var.root_id
  root_name         = var.root_name
  disable_telemetry = true
  library_path      = "${path.module}/lib"
  default_location  = var.default_location

  deploy_identity_resources = var.deploy_identity_resources # Currently deploys no resources but the management group hierarchy

  deploy_management_resources    = var.deploy_management_resources # Deploy log analytics workspace and automation account
  configure_management_resources = local.configure_management_resources

  deploy_connectivity_resources    = var.deploy_connectivity_resources # Deploy firewall and virtual hub/wan if selected
  configure_connectivity_resources = local.configure_connectivity_resources

  subscription_id_connectivity    = var.subscription_id
  subscription_id_management      = var.subscription_id
  subscription_id_identity        = var.subscription_id
  strict_subscription_association = false

  deploy_core_landing_zones   = true
  deploy_online_landing_zones = true
  deploy_corp_landing_zones   = true

  custom_landing_zones = local.custom_landing_zones

  # Not necessary
  deploy_demo_landing_zones = false
  deploy_sap_landing_zones  = false
}
