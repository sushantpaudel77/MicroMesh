locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Availability Zones
  azs = ["us-east-1a", "us-east-1b"]

  # Subnet Configuration 
  subnets = {
    public_1 = { cidr = "10.10.0.0/24", az = "us-east-1a", type = "public", tier = "public" }
    public_2 = { cidr = "10.10.1.0/24", az = "us-east-1b", type = "public", tier = "public" }
    ecs_1    = { cidr = "10.10.10.0/24", az = "us-east-1a", type = "ecs", tier = "private" }
    ecs_2    = { cidr = "10.10.11.0/24", az = "us-east-1b", type = "ecs", tier = "private" }
    db_1     = { cidr = "10.10.20.0/24", az = "us-east-1a", type = "database", tier = "isolated" }
    db_2     = { cidr = "10.10.21.0/24", az = "us-east-1b", type = "database", tier = "isolated" }
  }

  # Security Groups 
  security_groups = {
    alb = {
      name        = "alb"
      description = "ALB Security Group"
      ingress = {
        http = { from = 80, to = 80, proto = "tcp", cidr = "0.0.0.0/0" }
      }
    }
    ecs = {
      name        = "ecs"
      description = "ECS Security Group"
      ingress = {
        for port in [8001, 8002, 8003, 8004, 8005] : "port_${port}" => {
          from = port, to = port, proto = "tcp", source_sg = "alb"
        }
      }
    }
    rds = {
      name        = "rds"
      description = "RDS Security Group"
      ingress = {
        postgres = { from = 5432, to = 5432, proto = "tcp", source_sg = "ecs" }
      }
    }
    vpclink = {
      name        = "vpclink"
      description = "VPC Link Security Group"
      ingress = {
        http = { from = 80, to = 80, proto = "tcp", cidr = "0.0.0.0/0" }
      }
    }
    endpoints = {
      name        = "endpoints"
      description = "Endpoints Security Group"
      ingress = {
        https = { from = 443, to = 443, proto = "tcp", cidr = var.vpc_cidr }
      }
    }
    elasticache = {
      name        = "elasticache"
      description = "ElastiCache Security Group"
      ingress = {
        redis = { from = 6379, to = 6379, proto = "tcp", source_sg = "ecs" }
      }
    }

  }

  # Services Configuration 
  services = {
    product = {
      name         = "product-service"
      port         = 8001
      health_path  = "/health"
      cpu          = 256
      memory       = 512
      desired      = 1
      alb_priority = 1
      path_pattern = "/products*"
    }
    cart = {
      name         = "cart-service"
      port         = 8002
      health_path  = "/health"
      cpu          = 256
      memory       = 512
      desired      = 1
      alb_priority = 2
      path_pattern = "/cart*"
    }
    user = {
      name         = "user-service"
      port         = 8003
      health_path  = "/health"
      cpu          = 256
      memory       = 512
      desired      = 1
      alb_priority = 3
      path_pattern = "/users*"
    }
    order = {
      name         = "order-service"
      port         = 8004
      health_path  = "/health"
      cpu          = 256
      memory       = 512
      desired      = 1
      alb_priority = 4
      path_pattern = "/orders*"
    }
    shipping = {
      name         = "shipping-service"
      port         = 8005
      health_path  = "/health"
      cpu          = 256
      memory       = 512
      desired      = 1
      alb_priority = 5
      path_pattern = "/shipments*"
    }
  }

  # DynamoDB Tables 
  dynamodb_tables = {
    products = {
      name          = "${local.name_prefix}-products"
      hash_key      = "product_id"
      hash_key_type = "S"
      billing_mode  = "PAY_PER_REQUEST"
      gsis          = {}
    }

    cart = {
      name          = "${local.name_prefix}-cart"
      hash_key      = "user_id"
      hash_key_type = "S"
      billing_mode  = "PAY_PER_REQUEST"
      gsis          = {}
    }

    shipping = {
      name          = "${local.name_prefix}-shipping"
      hash_key      = "shipment_id"
      hash_key_type = "S"
      billing_mode  = "PAY_PER_REQUEST"

      gsis = {
        order_id = {
          name           = "order_id-index"
          hash_key       = "order_id"
          attribute_type = "N"
        }

        tracking = {
          name           = "tracking_number-index"
          hash_key       = "tracking_number"
          attribute_type = "S"
        }

        user_id = {
          name           = "user_id-index"
          hash_key       = "user_id"
          attribute_type = "S"
        }
      }
    }
  }

  # SNS Topics
  sns_topics = {
    order_events    = "order-events"
    shipping_events = "shipping-events"
    alarms          = "alarms"
  }

  # Alarms 
  alarms = {
    lambda_errors = {
      name         = "Lambda Shipping Failures"
      description  = "Shipping Lambda function has errors"
      metric       = "Errors"
      namespace    = "AWS/Lambda"
      statistic    = "Sum"
      period       = 60
      threshold    = 1
      eval_periods = 1
      dimensions = {
        FunctionName = "${local.name_prefix}-shipping-processor"
      }
    }
    sqs_backlog = {
      name         = "SQS Message Backlog"
      description  = "Messages piling up in SQS queue"
      metric       = "ApproximateNumberOfMessagesVisible"
      namespace    = "AWS/SQS"
      statistic    = "Average"
      period       = 300
      threshold    = 10
      eval_periods = 2
      dimensions = {
        QueueName = "${local.name_prefix}-order-shipping"
      }
    }
    rds_cpu = {
      name         = "RDS High CPU"
      description  = "RDS CPU utilization is high"
      metric       = "CPUUtilization"
      namespace    = "AWS/RDS"
      statistic    = "Average"
      period       = 300
      threshold    = 80
      eval_periods = 2
      dimensions = {
        DBInstanceIdentifier = local.name_prefix
      }
    }
    api_gateway_errors = {
      name         = "API Gateway 5XX Errors"
      description  = "API Gateway returning server errors"
      metric       = "5xx"
      namespace    = "AWS/ApiGateway"
      statistic    = "Sum"
      period       = 300
      threshold    = 5
      eval_periods = 1
      dimensions = {
        ApiName = "${local.name_prefix}-api"
      }
    }
    alb_5xx = {
      name         = "ALB 5XX Errors"
      description  = "ALB returning server errors"
      metric       = "HTTPCode_Target_5XX_Count"
      namespace    = "AWS/ApplicationELB"
      statistic    = "Sum"
      period       = 300
      threshold    = 5
      eval_periods = 1
      dimensions = {
        LoadBalancer = "${local.name_prefix}-alb"
      }
    }
  }
}
