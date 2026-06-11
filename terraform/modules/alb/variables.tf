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

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "services" {
  description = "Microservices configuration"
  type = map(object({
    name         = string
    port         = number
    health_path  = string
    alb_priority = number
    path_pattern = string
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}