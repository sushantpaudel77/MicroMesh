variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "topics" {
  type = map(string)
}

variable "admin_email" {
  description = "Email for order confirmations and system alarms"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}