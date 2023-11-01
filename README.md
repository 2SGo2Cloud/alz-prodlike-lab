# Azure Landing Zones lab

This repository will help you deploy a production-like lab environment for Azure Landing Zones in your own tenant with a single subscription.

## Prerequisites

Please update the following before running this:

- Subscription_id
- root_id
- root_parent_id (if needed)
- root_name

Please be aware of the following prerequisites:

1. Your own tenant where you are global admin and owner of all resources.
2. Your own subscription for platform services.
3. A credit card associated to your tenant to be able to deploy resources.
4. Terraform and Azure CLI installed locally.
5. Visual Studio Code for editing Terraform config.
6. Git for cloning the repository

## Deployment guide

### Variables replace

- Replace the variables in vars.auto.tfvars.example and remove the ".example" extension. This will make Terraform use these variables instead of the default values in variables.tf.
- Replace the settings in settings.connectivity.tf or settings.management.tf as needed. No change is needed if you want the default setup.

1. Clone the alz-prodlike-lab repository to your local computer
2. Replace all the necessary variable values to suit your environment
3. Log in to azure with Azure CLI `az login`
4. Make sure you are in the correct tenant and subscription with `az account show`
5. Make sure you have terraform installed at least version 1.5.5
6. Create a management group for deployment with `az account management-group create --name 'contoso' --display-name 'contoso'`
7. Run `terraform init`
8. Run `terraform plan -out "tfplan"`
9. Run `terraform apply "tfplan"`

If you want to deploy the ALZ management group topology directly in your Tenant Root Group, you just don't supply the root_parent_id variable in tfvars-file.

## Default deployment resources

The default deployment will not deploy any costly resources, but there will be an automation account and a log analytics workspace. It deploys approximately 260 objects where most are policy definitions and assignments.

## Add connectivity

You need to decide on Hub/Spoke or Virtual WAN. Both is possible with this module, but if you enable connectivity Hub & Spoke is the default.

- Set the "deploy_connectivity_resources" variable to true.
- Default connectivity configuration is Hub & Spoke. 
- Update settings.connectivity.tf to get Virtual WAN (the config is commented out in this file).

## More information

For more information, check the official [Terraform Enterprise Scale CAF github repository wiki](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/wiki)

## Azure Landing Zone solution for Vending Machine

This repository is responsible for creating landing zones in Azure Landing Zones framework. For more information on this vending machine, check the [Terraform landing zone vending module for Azure](https://github.com/Azure/terraform-azurerm-lz-vending#terraform-landing-zone-vending-module-for-azure) github repository.

### Create a new landing zone

Creation of landing zones are supposed to be easy and straightforward. This module performs many basic tasks for a new landing zone, and simplifies the process.

You can either create a new subscription via EA billing scope (currently not supported) or use an existing subscription. If you want to use an existing subscription, you need to provide the subscription id in the yaml file.


#### Existing subscription with hub/spoke

```yaml
---
name: lz##
location: norwayeast
subscription_id: "00000000-0000-0000-0000-000000000000"
management_group_id: online-management-group-id
contact: email
application: example-application
virtual_networks:
  vnet1:
    name: lz##-network-vnet1
    address_space:
      - "10.x.0.0/16"
    resource_group_name: lz##-network-rg
    vwan_connection_enabled: false
    hub_peering_enabled: true
    mesh_peering_enabled: true/false
role_assignments:
  my_ra_1:
    principal_id: 00000000-0000-0000-0000-000000000000
    definition: Owner
    relative_scope: ''
  my_ra_2:
    principal_id: 11111111-1111-1111-1111-111111111111
    definition: Reader
    relative_scope: ''
```

#### Existing subscription with Virtual WAN

Add a new landing zone by creating a new yaml file under lzdata folder for each new landing zone. The yaml file should contain the following information:

```yaml
---
name: lz##
location: norwayeast
subscription_id: "00000000-0000-0000-0000-000000000000"
management_group_id: online-management-group-id
contact: subscription-contact-email
application: application-name-for-tag
virtual-wan-enabled: true
virtual_networks:
  vnet1:
    name: lz##-network-vnet1
    address_space:
      - "10.x.0.0/16"
    resource_group_name: lz##-network-rg
    vwan_connection_enabled: true
    hub_peering_enabled: false
    mesh_peering_enabled: true/false
role_assignments:
  my_ra_1:
    principal_id: 00000000-0000-0000-0000-000000000000
    definition: Owner
    relative_scope: ''
  my_ra_2:
    principal_id: 11111111-1111-1111-1111-111111111111
    definition: Reader
    relative_scope: ''
```
