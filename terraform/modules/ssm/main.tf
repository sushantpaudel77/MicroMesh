# ============================================
# SSM Parameters
# ============================================

# Custom Parameters
resource "aws_ssm_parameter" "main" {
  for_each = var.parameters

  name        = "/${var.project_name}/${var.environment}/${each.value.name}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value
  tier        = each.value.tier
  overwrite   = each.value.overwrite

  tags = var.tags
}

# Service URLs
resource "aws_ssm_parameter" "service_urls" {
  for_each = var.service_urls != null ? var.service_urls.services : {}

  name  = "/${var.project_name}/${var.environment}/services/${each.key}-url"
  type  = "String"
  value = "http://${var.service_urls.alb_dns}"

  tags = var.tags
}

# SNS Topic ARNs
resource "aws_ssm_parameter" "sns_topics" {
  for_each = var.sns_topic_arns

  name  = each.key == "order" ? "/${var.project_name}/${var.environment}/sns/order-topic-arn" : "/${var.project_name}/${var.environment}/sns/${each.key}-topic-arn"
  type  = "String"
  value = each.value

  tags = var.tags
}

# DynamoDB Table Names
resource "aws_ssm_parameter" "dynamodb_tables" {
  for_each = var.dynamodb_table_names

  name  = "/${var.project_name}/${var.environment}/dynamodb/${each.key}-table"
  type  = "String"
  value = each.value

  tags = var.tags
}

# Database Host
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project_name}/${var.environment}/db/host"
  type  = "String"
  value = var.rds_endpoint

  tags = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project_name}/${var.environment}/db/name"
  type  = "String"
  value = "ecommercedb"

  tags = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.project_name}/${var.environment}/db/port"
  type  = "String"
  value = "5432"

  tags = var.tags
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/${var.project_name}/${var.environment}/db/username"
  type  = "String"
  value = "postgres"

  tags = var.tags
}

# Redis Endpoint
resource "aws_ssm_parameter" "redis_host" {
  name  = "/${var.project_name}/${var.environment}/redis/host"
  type  = "String"
  value = var.redis_endpoint

  tags = var.tags
}

resource "aws_ssm_parameter" "redis_port" {
  name  = "/${var.project_name}/${var.environment}/redis/port"
  type  = "String"
  value = "6379"

  tags = var.tags
}

# Cognito
resource "aws_ssm_parameter" "cognito_pool_id" {
  name  = "/${var.project_name}/${var.environment}/cognito/user-pool-id"
  type  = "String"
  value = var.cognito_pool_id

  tags = var.tags
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/${var.project_name}/${var.environment}/cognito/client-id"
  type  = "String"
  value = var.cognito_client_id

  tags = var.tags
}

# AWS Region
resource "aws_ssm_parameter" "region" {
  name  = "/${var.project_name}/${var.environment}/aws/region"
  type  = "String"
  value = var.aws_region

  tags = var.tags
}

# Shipping Table Name
resource "aws_ssm_parameter" "shipping_table" {
  name  = "/${var.project_name}/${var.environment}/shipping/table"
  type  = "String"
  value = var.dynamodb_table_names["shipping"]

  tags = var.tags
}