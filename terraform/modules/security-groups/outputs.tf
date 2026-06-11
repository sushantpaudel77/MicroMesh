output "sg_ids" {
  description = "Security group IDs mapped by key"
  value       = { for k, v in aws_security_group.main : k => v.id }
}

output "sg_arns" {
  description = "Security group ARNs mapped by key"
  value       = { for k, v in aws_security_group.main : k => v.arn }
}