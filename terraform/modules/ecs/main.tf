# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# CloudWatch Log Groups (for_each on services)
resource "aws_cloudwatch_log_group" "main" {
  for_each          = var.services
  name              = "/ecs/${var.project_name}-${each.key}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = var.tags
}

# Task Definitions (for_each on services)
resource "aws_ecs_task_definition" "main" {
  for_each                 = var.services
  family                   = "${var.project_name}-${each.key}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = each.value.name
      image = "${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}/${each.value.name}:latest"
      portMappings = [{
        containerPort = each.value.port
        protocol      = "tcp"
      }]

      environment = [
        { name = "ENVIRONMENT", value = var.environment },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "REDIS_HOST", value = var.redis_host },
        { name = "REDIS_PORT", value = var.redis_port },
        { name = "PRODUCTS_TABLE", value = lookup(var.dynamodb_table_names, "products", "") },
        { name = "CARTS_TABLE", value = lookup(var.dynamodb_table_names, "cart", "") },
        { name = "SHIPPING_TABLE", value = lookup(var.dynamodb_table_names, "shipping", "") },
        { name = "DB_SECRET_ARN", value = var.db_secret_arn }
      ]

      # Secrets: Reference specific JSON keys
      secrets = each.value.name == "user-service" || each.value.name == "order-service" ? [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "DB_HOST"
          valueFrom = "${var.db_secret_arn}:host::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.db_secret_arn}:dbname::"
        }
      ] : []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main[each.key].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# ECS Services (for_each on services)
resource "aws_ecs_service" "main" {
  for_each = var.services

  name            = "${var.project_name}-${each.key}-svc-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main[each.key].arn
  desired_count   = each.value.desired
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_groups[each.key]
    container_name   = each.value.name
    container_port   = each.value.port
  }

  health_check_grace_period_seconds = 120

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags
}
