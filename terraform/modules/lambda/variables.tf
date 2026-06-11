variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS Queue ARN"
  type        = string
}

variable "alb_dns" {
  description = "ALB DNS name"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}