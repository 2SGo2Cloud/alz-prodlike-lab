data "azurerm_client_config" "current" {}

module "alz_core" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "~> 4.0"

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  root_parent_id    = module.shared.core_config["root_parent_id"]
  root_id           = module.shared.core_config["root_id"]
  root_name         = module.shared.core_config["root_name"]
  disable_telemetry = true
  library_path      = "${path.module}/lib"
  default_location  = module.shared.core_config["default_location"]

  subscription_id_connectivity    = local.subscription_id_connectivity
  subscription_id_management      = local.subscription_id_management
  subscription_id_identity        = local.subscription_id_identity
  strict_subscription_association = false

  deploy_core_landing_zones   = true
  deploy_online_landing_zones = true
  deploy_corp_landing_zones   = true

  custom_landing_zones = local.custom_landing_zones

  # These are deployed in different Terraform states
  deploy_identity_resources     = false
  deploy_connectivity_resources = false
  deploy_management_resources   = false

  # Not necessary
  deploy_demo_landing_zones = false
  deploy_sap_landing_zones  = false
}

module "shared" {
  #TODO: Set this to a tag or some form of versioned reference before go live.
  #Pointing to main branch as reference is not considered best practice.
  source = "git@github.com:<organization/user>/<shared-repo>.git//shared_variables/?ref=shared_variables/v1"
}
