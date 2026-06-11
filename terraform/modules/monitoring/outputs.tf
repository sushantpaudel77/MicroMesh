output "alarm_ids" {
  description = "Alarm IDs by key"
  value       = { for k, v in aws_cloudwatch_metric_alarm.main : k => v.id }
}

output "alarm_arns" {
  description = "Alarm ARNs by key"
  value       = { for k, v in aws_cloudwatch_metric_alarm.main : k => v.arn }
}

output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "CloudWatch Dashboard ARN"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "composite_alarm_id" {
  description = "Composite alarm ID (prod only)"
  value       = try(aws_cloudwatch_composite_alarm.system_health[0].id, null)
}