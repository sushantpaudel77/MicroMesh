variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "callback_urls" {
  description = "Callback URLs"
  type        = list(string)
}

variable "logout_urls" {
  description = "Logout URLs"
  type        = list(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}