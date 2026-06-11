variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ECS Security Group ID"
  type        = string
}

variable "services" {
  description = "Microservices configuration"
  type = map(object({
    name        = string
    port        = number
    health_path = string
    cpu         = number
    memory      = number
    desired     = number
  }))
}

variable "dynamodb_table_names" {
  description = "DynamoDB table names map"
  type        = map(string)
}

variable "redis_host" {
  description = "Redis host endpoint"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = string
  default     = "6379"
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB password"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "target_groups" {
  description = "Target group ARNs map"
  type        = map(string)
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
