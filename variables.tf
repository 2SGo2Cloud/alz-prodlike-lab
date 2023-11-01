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
