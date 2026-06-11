variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "admin_email" {
  description = "Email for admin alerts"
  type        = string
  default     = "cloudforsushant7@gmail.com"
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  type        = string
}
variable "time_period_start" {
  description = "Start date for budget"
  type        = string
  default     = "2026-06-01_00:00"  
}

variable "waf_enable_rate_limiting" {
  description = "Enable WAF rate limiting"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate limit threshold"
  type        = number
  default     = 200
}

# Already have this, but make sure it's there:
variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "cloudforsushant.xyz"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
