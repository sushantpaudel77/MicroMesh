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

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "ecs_subnet_ids" {
  description = "ECS Subnet IDs"
  type        = list(string)
}

variable "ecs_route_table_id" {
  description = "ECS Route Table ID"
  type        = string
}

variable "endpoint_sg_id" {
  description = "Endpoint Security Group ID"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}