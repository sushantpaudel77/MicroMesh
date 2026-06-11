variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "domain_name" {
  description = "Root domain"
  type        = string
}

variable "subdomain" {
  description = "Subdomain"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  type        = string
}

variable "waf_acl_arn" {
  description = "WAF ACL ARN"
  type        = string
}

variable "api_endpoint" {
  description = "API Gateway URL"
  type        = string
}

variable "cognito_pool_id" {
  description = "Cognito Pool ID"
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