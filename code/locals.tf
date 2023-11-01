locals {

  subscription_id_connectivity = coalesce(module.shared.alz_subscriptions["connectivity"].id, local.subscription_id_management)
  subscription_id_identity     = coalesce(module.shared.alz_subscriptions["identity"].id, local.subscription_id_management)
  subscription_id_management   = coalesce(module.shared.alz_subscriptions["management"].id, data.azurerm_client_config.current.subscription_id)

  custom_landing_zones = {
    "${module.shared.core_config["root_id"]}-online-example-1" = {
      display_name               = "${upper(module.shared.core_config["root_id"])} Online Example 1"
      parent_management_group_id = "${module.shared.core_config["root_id"]}-landing-zones"
      subscription_ids           = []
      archetype_config = {
        archetype_id   = "customer_online"
        parameters     = {}
        access_control = {}
      }
    }
    "${module.shared.core_config["root_id"]}-online-example-2" = {
      display_name               = "${upper(module.shared.core_config["root_id"])} Online Example 2"
      parent_management_group_id = "${module.shared.core_config["root_id"]}-landing-zones"
      subscription_ids           = []
      archetype_config = {
        archetype_id = "customer_online"
        parameters = {
          Deny-Resource-Locations = {
            listOfAllowedLocations = [
              module.shared.core_config["default_location"],
            ]
          }
          Deny-RSG-Locations = {
            listOfAllowedLocations = [
              module.shared.core_config["default_location"],
            ]
          }
        }
        access_control = {}
      }
    }
    "${module.shared.core_config["root_id"]}-security" = {
      display_name               = "Security"
      parent_management_group_id = "${module.shared.core_config["root_id"]}-platform"
      subscription_ids           = []
      archetype_config = {
        archetype_id   = "default_empty" # This is equivalent to creating a standard Management Group without creating any custom Policy Assignments, Policy Definitions, Policy Set Definitions (Initiatives) or Role Definitions.
        parameters     = {}
        access_control = {}
      }
    }
  }
}
