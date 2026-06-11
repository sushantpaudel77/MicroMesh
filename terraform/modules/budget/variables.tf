variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "budget_amount" {
  type = number
  default = 10
}

variable "notification_email" {
  description = "Email for budget alerts"
  type        = string
}

variable "sns_topic_arns" {
  type    = list(string)
  default = []
}

variable "time_period_start" {
  description = "Start date for budget"
  type        = string
  default     = "2026-06-01_00:00"  
}

variable "warning_threshold" {
  type    = number
  default = 50
}

variable "critical_threshold" {
  type    = number
  default = 80
}

variable "forecast_threshold" {
  type    = number
  default = 100
}

variable "enable_anomaly_detection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}