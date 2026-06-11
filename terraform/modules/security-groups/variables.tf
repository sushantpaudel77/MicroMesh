variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "security_groups" {
  description = "Security groups configuration map"
  type = map(object({
    name        = string
    description = string
    ingress = map(object({
      from      = number
      to        = number
      proto     = string
      cidr      = optional(string)
      source_sg = optional(string)
    }))
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
