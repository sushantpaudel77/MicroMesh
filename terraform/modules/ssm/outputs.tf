output "parameter_names" {
  description = "All SSM parameter names"
  value = {
    custom    = keys(aws_ssm_parameter.main)
    services  = keys(aws_ssm_parameter.service_urls)
    sns       = keys(aws_ssm_parameter.sns_topics)
    dynamodb  = keys(aws_ssm_parameter.dynamodb_tables)
    cognito   = var.cognito_pool_id != "" ? ["user-pool-id", "client-id"] : []
    database  = var.rds_endpoint != "" ? ["host", "name"] : []
    redis     = var.redis_endpoint != "" ? ["host"] : []
    region    = ["aws-region"]
  }
}

output "parameter_arns" {
  description = "SSM Parameter ARNs"
  value = merge(
    { for k, v in aws_ssm_parameter.main : k => v.arn },
    { for k, v in aws_ssm_parameter.service_urls : "service_${k}" => v.arn },
    { for k, v in aws_ssm_parameter.sns_topics : "sns_${k}" => v.arn },
    { for k, v in aws_ssm_parameter.dynamodb_tables : "dynamodb_${k}" => v.arn }
  )
}

output "parameter_map" {
  description = "All parameter names by path"
  value = {
    region = "/${var.project_name}/${var.environment}/aws/region"
    db_host = "/${var.project_name}/${var.environment}/db/host"
    db_name = "/${var.project_name}/${var.environment}/db/name"
    redis_host = "/${var.project_name}/${var.environment}/redis/host"
    cognito_pool_id = "/${var.project_name}/${var.environment}/cognito/user-pool-id"
    cognito_client_id = "/${var.project_name}/${var.environment}/cognito/client-id"
  }
}