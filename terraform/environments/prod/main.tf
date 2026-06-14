# MODULE: VPC
module "vpc" {
  source = "../../modules/vpc"

  environment   = var.environment
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  azs           = local.azs
  subnets       = local.subnets
  nat_single_az = false  # PROD: Multi-AZ NAT Gateways
  tags          = var.tags
}

# MODULE: Security Groups
module "security_groups" {
  source = "../../modules/security-groups"

  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  security_groups = local.security_groups
  tags            = var.tags
}

# MODULE: VPC Endpoints
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  region             = var.aws_region
  ecs_subnet_ids     = module.vpc.ecs_subnet_ids
  ecs_route_table_id = module.vpc.ecs_route_table_id
  endpoint_sg_id     = module.security_groups.sg_ids["endpoints"]
  tags               = var.tags
}

# MODULE: Secrets Manager
module "secrets" {
  source = "../../modules/secrets-manager"

  environment  = var.environment
  project_name = var.project_name
  tags         = var.tags
}

# MODULE: DynamoDB
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment = var.environment
  tables      = local.dynamodb_tables
  tags        = var.tags
}

# MODULE: RDS - PROD values
module "rds" {
  source = "../../modules/rds"

  environment         = var.environment
  project_name        = var.project_name
  subnet_ids          = module.vpc.database_subnet_ids
  security_group_id   = module.security_groups.sg_ids["rds"]
  db_password         = module.secrets.db_password
  instance_class      = "db.t4g.small"    # PROD: larger instance
  allocated_storage   = 100               # PROD: more storage
  multi_az            = true              # PROD: Multi-AZ
  backup_days         = 30               # PROD: 30 day backups
  deletion_protection = true             # PROD: protect from deletion
  skip_final_snapshot = false            # PROD: take final snapshot
  tags                = var.tags
}

# MODULE: ElastiCache - PROD values
module "elasticache" {
  source = "../../modules/elasticache"

  environment       = var.environment
  project_name      = var.project_name
  subnet_ids        = module.vpc.ecs_subnet_ids
  security_group_id = module.security_groups.sg_ids["elasticache"]
  node_type         = "cache.t3.medium"  # PROD: larger node
  num_nodes         = 2                  # PROD: multi-node
  tags              = var.tags
}

# MODULE: ALB
module "alb" {
  source = "../../modules/alb"

  environment       = var.environment
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.ecs_subnet_ids
  security_group_id = module.security_groups.sg_ids["alb"]
  services          = local.services
  tags              = var.tags
}

# MODULE: IAM
module "iam" {
  source = "../../modules/iam"

  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  tags         = var.tags
}

# MODULE: ECS
module "ecs" {
  source = "../../modules/ecs"

  environment       = var.environment
  project_name      = var.project_name
  aws_region        = var.aws_region
  account_id        = data.aws_caller_identity.current.account_id
  subnet_ids        = module.vpc.ecs_subnet_ids
  security_group_id = module.security_groups.sg_ids["ecs"]
  services          = local.services

  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn

  target_groups = module.alb.target_group_arns

  db_secret_arn = module.secrets.secret_arn

  redis_host = module.elasticache.endpoint
  redis_port = "6379"

  dynamodb_table_names = module.dynamodb.table_names

  tags = var.tags
}

# MODULE: Cognito - PROD domain
module "cognito" {
  source = "../../modules/cognito"

  environment   = var.environment
  project_name  = var.project_name
  callback_urls = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
  logout_urls   = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
  tags          = var.tags
}

# MODULE: SNS
module "sns" {
  source = "../../modules/sns"

  environment  = var.environment
  project_name = var.project_name
  topics       = local.sns_topics
  admin_email  = var.admin_email
  tags         = var.tags
}

# MODULE: SQS
module "sqs" {
  source = "../../modules/sqs"

  environment   = var.environment
  project_name  = var.project_name
  order_sns_arn = module.sns.topic_arns["order_events"]
  tags          = var.tags
}

# MODULE: Lambda
module "lambda" {
  source = "../../modules/lambda"

  environment       = var.environment
  project_name      = var.project_name
  subnet_ids        = module.vpc.ecs_subnet_ids
  security_group_id = module.security_groups.sg_ids["ecs"]
  sqs_queue_arn     = module.sqs.queue_arn
  alb_dns           = module.alb.alb_dns
  lambda_role_arn   = module.iam.lambda_role_arn
  tags              = var.tags
}

# MODULE: API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  environment           = var.environment
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.ecs_subnet_ids
  security_group_id     = module.security_groups.sg_ids["vpclink"]
  alb_listener_arn      = module.alb.listener_arn
  alb_dns               = module.alb.alb_dns
  cognito_user_pool_arn = module.cognito.pool_arn
  cognito_user_pool_id  = module.cognito.pool_id
  cognito_client_id     = module.cognito.client_id
  frontend_domain       = var.domain_name
  tags                  = var.tags
}

# MODULE: WAF - PROD enables rate limiting
module "waf" {
  source = "../../modules/waf"
  providers = {
    aws = aws.us_east_1
  }

  environment          = var.environment
  project_name         = var.project_name
  enable_rate_limiting = true   # PROD: enable rate limiting
  rate_limit           = 2000
  tags                 = var.tags
}

# MODULE: Frontend - PROD domain
module "frontend" {
  source = "../../modules/frontend"
  providers = {
    aws = aws.us_east_1
  }

  environment         = var.environment
  project_name        = var.project_name
  domain_name         = var.domain_name
  subdomain           = ""          # PROD: no subdomain
  acm_certificate_arn = var.acm_certificate_arn
  waf_acl_arn         = module.waf.web_acl_arn
  api_endpoint        = module.api_gateway.api_endpoint
  cognito_pool_id     = module.cognito.pool_id
  cognito_client_id   = module.cognito.client_id
  tags                = var.tags
}

# MODULE: Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  environment     = var.environment
  project_name    = var.project_name
  alarms          = local.alarms
  alarm_topic_arn = module.sns.topic_arns["alarms"]
  tags            = var.tags
}

# MODULE: SSM Parameter Store
module "ssm" {
  source = "../../modules/ssm"

  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region

  service_urls = {
    alb_dns = module.alb.alb_dns
    services = {
      product  = { name = "product-service", path = "/products" }
      cart     = { name = "cart-service", path = "/cart" }
      user     = { name = "user-service", path = "/users" }
      order    = { name = "order-service", path = "/orders" }
      shipping = { name = "shipping-service", path = "/shipments" }
    }
  }

  rds_endpoint   = module.rds.address
  redis_endpoint = module.elasticache.endpoint

  sns_topic_arns = {
    order    = module.sns.topic_arns["order_events"]
    shipping = module.sns.topic_arns["shipping_events"]
  }

  dynamodb_table_names = {
    products = module.dynamodb.table_names["products"]
    cart     = module.dynamodb.table_names["cart"]
    shipping = module.dynamodb.table_names["shipping"]
  }

  cognito_pool_id   = module.cognito.pool_id
  cognito_client_id = module.cognito.client_id

  parameters = {
    environment = {
      name        = "environment"
      description = "Current environment"
      type        = "String"
      value       = var.environment
    }
    frontend_url = {
      name        = "frontend-url"
      description = "Frontend application URL"
      type        = "String"
      value       = "https://${var.domain_name}"
    }
    api_url = {
      name        = "api-url"
      description = "API Gateway URL"
      type        = "String"
      value       = module.api_gateway.api_endpoint
    }
  }

  depends_on = [
    module.secrets,
    module.rds,
    module.alb,
    module.elasticache,
    module.sns,
    module.dynamodb,
    module.cognito,
    module.api_gateway
  ]

  tags = var.tags
}

module "route53" {
  source = "../../modules/route53"

  domain_name               = var.domain_name
  cloudfront_domain_name    = module.frontend.cloudfront_domain
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"

  create_dev_record = false  # PROD: no dev subdomain

  depends_on = [module.frontend]

  tags = var.tags
}

# MODULE: Budget - PROD higher budget
module "budget" {
  source = "../../modules/budget"

  environment              = var.environment
  project_name             = var.project_name
  budget_amount            = 50   # PROD: $50 budget
  notification_email       = var.admin_email
  sns_topic_arns           = [module.sns.topic_arns["alarms"]]
  enable_anomaly_detection = true  # PROD: enable anomaly detection

  tags = var.tags
}