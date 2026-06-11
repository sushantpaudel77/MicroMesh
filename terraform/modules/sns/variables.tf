variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "topics" {
  description = "SNS topics map"
  type        = map(string)
}

variable "alarm_email" {
  description = "Email for alarm subscription"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}