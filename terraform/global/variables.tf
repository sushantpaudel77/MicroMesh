variable "aws_region" {
  description = "AWS Region for backend resources (must be us-east-1)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "The Terraform state backend must be in us-east-1. Do not change this region."
  }
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "ecommerce-terraform-state-cloudnerd"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce"
}

variable "environments" {
  description = "Environments to create state prefixes for"
  type        = list(string)
  default     = ["dev", "stage", "prod"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project   = "ecommerce"
    ManagedBy = "terraform"
    Purpose   = "terraform-state-backend"
  }
}