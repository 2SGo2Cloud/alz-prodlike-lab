# The landing zone module will be called once per landing_zone_*.yaml file
# in the data directory.

locals {
  # landing_zone_data_dir is the directory containing the YAML files for the landing zones.
  landing_zone_data_dir = "${path.root}/landingzones"

  # landing_zone_files is the list of landing zone YAML files to be processed
  landing_zone_files = fileset(local.landing_zone_data_dir, "landing_zone_*.yaml")

  # landing_zone_data_map is the decoded YAML data stored in a map
  landing_zone_data_map = {
    for f in local.landing_zone_files :
    f => yamldecode(file("${local.landing_zone_data_dir}/${f}"))
  }
}

module "lz_vending" {
  source   = "Azure/lz-vending/azurerm"
  version  = "~> 3.1"
  for_each = local.landing_zone_data_map

  location          = each.value.location
  disable_telemetry = true

  # subscription variables
  subscription_id = each.value.subscription_id

  # subscription tags
  subscription_tags = {
    contact     = each.value.contact
    application = each.value.application
  }

  # management group association variables
  subscription_management_group_association_enabled     = each.value.management_group_id != null ? true : false
  subscription_management_group_id                      = each.value.management_group_id
  subscription_register_resource_providers_and_features = {}

  # virtual network variables
  virtual_network_enabled = length(each.value.virtual_networks) > 0 ? true : false
  virtual_networks = {
    for k, v in each.value.virtual_networks : k => merge(
      v,
      {
        vwan_hub_resource_id            = v.vwan_connection_enabled ? "/subscriptions/${var.subscription_id}/resourceGroups/${var.root_id}-connectivity/providers/Microsoft.Network/virtualHubs/${var.root_id}-hub-${var.connectivity_resources_location}" : null
        vwan_connection_enabled         = v.vwan_connection_enabled
        hub_peering_enabled             = v.hub_peering_enabled
        hub_network_resource_id         = v.hub_peering_enabled ? "/subscriptions/${var.subscription_id}/resourceGroups/${var.root_id}-connectivity-${var.connectivity_resources_location}/providers/Microsoft.Network/virtualNetworks/${var.root_id}-hub-${var.connectivity_resources_location}" : null
        hub_peering_use_remote_gateways = v.hub_peering_enabled ? v.hub_peering_use_remote_gateways : null
        mesh_peering_enabled            = v.mesh_peering_enabled
      }
    )
  }

  # role assignment variables
  role_assignment_enabled = length(each.value.role_assignments) > 0 ? true : false
  role_assignments        = { for k, v in each.value.role_assignments : k => v }
}
