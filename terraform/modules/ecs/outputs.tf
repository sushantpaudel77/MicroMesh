output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "service_names" {
  description = "Service names"
  value       = { for k, v in aws_ecs_service.main : k => v.name }
}

output "log_group_names" {
  description = "Log group names"
  value       = { for k, v in aws_cloudwatch_log_group.main : k => v.name }
}