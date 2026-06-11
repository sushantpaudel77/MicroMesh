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
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "VPC Link SG ID"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB Listener ARN"
  type        = string
}

variable "alb_dns" {
  description = "ALB DNS name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito Pool ARN (used for JWT authorizer audience validation)"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID (used to construct the JWT issuer URL)"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito Client ID"
  type        = string
}

variable "frontend_domain" {
  description = "Frontend domain for CORS"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
