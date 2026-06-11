variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "db_host" {
  description = "RDS host (can be empty initially)"
  type        = string
  default     = "pending"
}

variable "tags" {
  type    = map(string)
  default = {}
}