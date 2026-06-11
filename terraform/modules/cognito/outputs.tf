output "pool_id" {
  description = "User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "pool_arn" {
  description = "User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "client_id" {
  description = "Client ID"
  value       = aws_cognito_user_pool_client.main.id
}