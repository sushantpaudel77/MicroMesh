variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "RDS Security Group ID"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
}

variable "backup_days" {
  description = "Backup retention days"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}