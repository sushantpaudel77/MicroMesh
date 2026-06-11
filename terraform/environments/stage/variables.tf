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

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "alarm_email" {
  description = "Alarm email"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  type        = string
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

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
