locals {
  custom_landing_zones = {
    "${var.root_id}-online-example-1" = {
      display_name               = "${upper(var.root_id)} Online Example 1"
      parent_management_group_id = "${var.root_id}-landing-zones"
      subscription_ids           = []
      archetype_config = {
        archetype_id   = "customer_online"
        parameters     = {}
        access_control = {}
      }
    }
    "${var.root_id}-online-example-2" = {
      display_name               = "${upper(var.root_id)} Online Example 2"
      parent_management_group_id = "${var.root_id}-landing-zones"
      subscription_ids           = []
      archetype_config = {
        archetype_id = "customer_online"
        parameters = {
          Deny-Resource-Locations = {
            listOfAllowedLocations = [
              var.default_location,
            ]
          }
          Deny-RSG-Locations = {
            listOfAllowedLocations = [
              var.default_location,
            ]
          }
        }
        access_control = {}
      }
    }
    "${var.root_id}-security" = {
      display_name               = "Security"
      parent_management_group_id = "${var.root_id}-platform"
      subscription_ids           = []
      archetype_config = {
        archetype_id   = "default_empty" # This is equivalent to creating a standard Management Group without creating any custom Policy Assignments, Policy Definitions, Policy Set Definitions (Initiatives) or Role Definitions.
        parameters     = {}
        access_control = {}
      }
    }
  }
}
