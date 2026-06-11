locals {
  gateway_endpoints = {
    s3       = "s3"
    dynamodb = "dynamodb"
  }

  interface_endpoints = {
    ecr_api = "ecr.api"
    ecr_dkr = "ecr.dkr"
    logs    = "logs"
    sns     = "sns"
    sqs     = "sqs"
    ssm     = "ssm"
    secrets = "secretsmanager"
  }
}

resource "aws_vpc_endpoint" "gateway" {
  for_each        = local.gateway_endpoints
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [var.ecs_route_table_id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-ep-${var.environment}"
  })
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.ecs_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-ep-${var.environment}"
  })
}