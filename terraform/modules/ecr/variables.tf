variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "services" {
  description = "Services map"
  type = map(object({
    name = string
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}