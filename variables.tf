# Use variables to customize the deployment
variable "root_id" {
  type    = string
  default = "alz"
}

variable "root_name" {
  type    = string
  default = "My ALZ lab"
}

variable "root_parent_id" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type = string
}

variable "default_location" {
  type    = string
  default = "norwayeast"
}

variable "deploy_connectivity_resources" {
  type    = bool
  default = false
}

variable "connectivity_resources_location" {
  type    = string
  default = "norwayeast"
}

variable "connectivity_resources_tags" {
  type = map(string)
  default = {
    demo_type = "deploy_connectivity_resources_custom"
  }
}

variable "deploy_management_resources" {
  type    = bool
  default = true
}

variable "log_retention_in_days" {
  type    = number
  default = 30
}

variable "security_alerts_email_address" {
  type    = string
  default = "my_valid_security_contact@replace_me" # Replace this value with your own email address.
}

variable "management_resources_location" {
  type    = string
  default = "norwayeast"
}

variable "management_resources_tags" {
  type = map(string)
  default = {
    demo_type = "deploy_management_resources_custom"
  }
}

variable "deploy_identity_resources" {
  type    = bool
  default = true
}
