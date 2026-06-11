output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "listener_arn" {
  description = "ALB Listener ARN"
  value       = aws_lb_listener.main.arn
}

output "target_group_arns" {
  description = "Target group ARNs mapped by service key"
  value       = { for k, v in aws_lb_target_group.main : k => v.arn }
}