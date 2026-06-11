output "vpc_id"              { value = module.vpc.vpc_id }
output "alb_dns"             { value = module.alb.alb_dns }
output "api_endpoint"        { value = module.api_gateway.api_endpoint }
output "cloudfront_url"      { value = module.frontend.cloudfront_url }
output "cloudfront_id"       { value = module.frontend.cloudfront_id }
output "rds_endpoint"        { value = module.rds.endpoint }
output "redis_endpoint"      { value = module.elasticache.endpoint }
output "cognito_pool_id"     { value = module.cognito.pool_id }
output "cognito_client_id"   { value = module.cognito.client_id }
output "frontend_bucket"     { value = module.frontend.bucket_name }

# NEW Route53 outputs
output "website_url"         { value = "https://${var.domain_name}" }
output "dev_website_url"     { value = "https://dev.${var.domain_name}" }
output "name_servers"        { value = module.route53.name_servers }