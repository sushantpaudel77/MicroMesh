variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for naming"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "subnets" {
  description = "Subnet configuration map"
  type = map(object({
    cidr = string
    az   = string
    type = string
    tier = string
  }))
}

variable "nat_single_az" {
  description = "Use single AZ NAT (true) or multi-AZ (false)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
