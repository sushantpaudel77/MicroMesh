# MODULE: VPC
module "vpc" {
  source = "../../modules/vpc"

  environment   = var.environment
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  azs           = local.azs
  subnets       = local.subnets
  nat_single_az = true # Dev uses single NAT
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
  db_host      = module.rds.address
  tags         = var.tags
}

# MODULE: DynamoDB
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment = var.environment
  tables      = local.dynamodb_tables
  tags        = var.tags
}

# MODULE: RDS
module "rds" {
  source = "../../modules/rds"

  environment         = var.environment
  project_name        = var.project_name
  subnet_ids          = module.vpc.database_subnet_ids
  security_group_id   = module.security_groups.sg_ids["rds"]
  db_password         = module.secrets.db_password
  instance_class      = "db.t4g.micro"
  allocated_storage   = 20
  multi_az            = false
  backup_days         = 0
  deletion_protection = false
  skip_final_snapshot = true
  tags                = var.tags
}

# MODULE: ElastiCache
module "elasticache" {
  source = "../../modules/elasticache"

  environment       = var.environment
  project_name      = var.project_name
  subnet_ids        = module.vpc.ecs_subnet_ids
  security_group_id = module.security_groups.sg_ids["elasticache"]
  node_type         = "cache.t3.micro"
  num_nodes         = 1
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

  # Database
  db_secret_arn = module.secrets.secret_arn

  # Redis
  redis_host = module.elasticache.endpoint
  redis_port = "6379"

  # DynamoDB Table Names (NEW)
  dynamodb_table_names = module.dynamodb.table_names

  tags = var.tags
}
# MODULE: Cognito
module "cognito" {
  source = "../../modules/cognito"

  environment   = var.environment
  project_name  = var.project_name
  callback_urls = ["https://dev.${var.domain_name}"]
  logout_urls   = ["https://dev.${var.domain_name}"]
  tags          = var.tags
}

# MODULE: SNS
module "sns" {
  source = "../../modules/sns"

  environment  = var.environment
  project_name = var.project_name
  topics       = local.sns_topics
  alarm_email  = var.alarm_email
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
  frontend_domain       = "dev.${var.domain_name}"
  tags                  = var.tags
}

# MODULE: WAF
module "waf" {
  source = "../../modules/waf"

  environment          = var.environment
  project_name         = var.project_name
  enable_rate_limiting = false
  rate_limit           = 200
  tags                 = var.tags
}

# MODULE: Frontend
module "frontend" {
  source = "../../modules/frontend"

  environment         = var.environment
  project_name        = var.project_name
  domain_name         = var.domain_name
  subdomain           = "dev"
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

  # Service URLs pointing to ALB
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

  # Database endpoints
  rds_endpoint   = module.rds.address
  redis_endpoint = module.elasticache.endpoint

  # SNS Topic ARNs
  sns_topic_arns = {
    order    = module.sns.topic_arns["order_events"]
    shipping = module.sns.topic_arns["shipping_events"]
  }

  # DynamoDB table names
  dynamodb_table_names = {
    products = module.dynamodb.table_names["products"]
    cart     = module.dynamodb.table_names["cart"]
    shipping = module.dynamodb.table_names["shipping"]
  }

  # Cognito
  cognito_pool_id   = module.cognito.pool_id
  cognito_client_id = module.cognito.client_id

  # Custom parameters
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
      value       = "https://dev.${var.domain_name}"
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

module "ecr" {
  source = "../../modules/ecr"

  environment  = var.environment
  project_name = var.project_name
  services     = local.services
  tags         = var.tags
}
