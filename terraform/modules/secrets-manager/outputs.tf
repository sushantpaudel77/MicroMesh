output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.db.name
}

output "db_password" {
  description = "Database password (sensitive)"
  value       = random_password.db.result
  sensitive   = true
}

output "db_username" {
  description = "Database username"
  value       = "postgres"
}