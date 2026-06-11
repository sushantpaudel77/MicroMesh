output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_name" {
  description = "WAF Web ACL Name"
  value       = aws_wafv2_web_acl.main.name
}

output "web_acl_capacity" {
  description = "WAF Web ACL Capacity Units used"
  value       = aws_wafv2_web_acl.main.capacity
}

output "log_group_arn" {
  description = "WAF Log Group ARN"
  value       = aws_cloudwatch_log_group.waf.arn
}

output "log_group_name" {
  description = "WAF Log Group Name"
  value       = aws_cloudwatch_log_group.waf.name
}