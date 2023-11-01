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
  default = "test-alz"
}

variable "subscription_id" {
  type    = string
  default = ""
}

variable "default_location" {
  type    = string
  default = "norwayeast"
}
