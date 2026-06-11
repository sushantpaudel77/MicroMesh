variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "parameters" {
  description = "Custom SSM Parameters"
  type = map(object({
    name        = string
    description = optional(string, "")
    type        = string
    value       = string
    tier        = optional(string, "Standard")
    overwrite   = optional(bool, true)
  }))
  default = {}
}

variable "service_urls" {
  description = "Service URL parameters"
  type = object({
    alb_dns = string
    services = map(object({
      name = string
      path = string
    }))
  })
  default = null
}

variable "rds_endpoint" {
  description = "RDS endpoint address"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint address"
  type        = string
}

variable "sns_topic_arns" {
  description = "SNS Topic ARNs map"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_names" {
  description = "DynamoDB table names"
  type        = map(string)
  default     = {}
}

variable "cognito_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito Client ID"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}