output "topic_arns" {
  description = "SNS Topic ARNs"
  value       = { for k, v in aws_sns_topic.main : k => v.arn }
}