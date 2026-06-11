variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "alarms" {
  description = "CloudWatch alarms configuration"
  type = map(object({
    name          = string
    description   = string
    metric        = string
    namespace     = string
    statistic     = string
    period        = number
    threshold     = number
    eval_periods  = number
    dimensions    = map(string)
  }))
  default = {}
}

variable "alarm_topic_arn" {
  description = "SNS Topic ARN for alarm notifications"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}