resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "/ecommerce/${var.environment}/database/password"
  description             = "RDS PostgreSQL master password for ${var.environment}"
  recovery_window_in_days = var.environment == "prod" ? 7 : 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db.result
    engine   = "postgres"
    port     = 5432
    dbname   = "ecommercedb"
  })
}
