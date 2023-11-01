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

The default deployment will not deploy any costly resources. It deploys approximately 260 objects where most of it is policy definitions and assignments.

Log analytics workspace and automation account is also created.

## Add connectivity

You need to decide on Hub/Spoke or Virtual WAN. Both is possible with this module.

- Set the "deploy_connectivity_resources" property to true.
- Uncomment the part of locals.connectivity_settings.tf to use for either Hub & Spoke or Virtual WAN.
- Uncomment #configure_connectivity_resources in main.tf.

## More information

For more information, check the official [Terraform Enterprise Scale CAF github repository wiki](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/wiki)
