variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ecommerce"
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting rule (recommended for prod)"
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Rate limit threshold (requests per 5 minutes per IP)"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100 && var.rate_limit <= 20000
    error_message = "Rate limit must be between 100 and 20000."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}