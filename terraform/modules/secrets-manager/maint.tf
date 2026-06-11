# Generate Random Password
resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "db" {
  name                    = "/${var.project_name}/${var.environment}/database/password"
  description             = "RDS PostgreSQL master password for ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 7 : 0  # 0 = force delete without recovery

  tags = var.tags
}

# Secret Version (stores the actual password)
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db.result
    engine   = "postgres"
    host     = var.db_host
    port     = 5432
    dbname   = "ecommercedb"
  })
}