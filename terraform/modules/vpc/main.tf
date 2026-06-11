# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-${var.environment}"
  })
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw-${var.environment}"
  })
}

# Subnets
resource "aws_subnet" "main" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  map_public_ip_on_launch = each.value.tier == "public"

  tags = merge(var.tags, {
    Name = "${var.project_name}-subnet-${each.key}-${var.environment}"
    Tier = each.value.tier
    Type = each.value.type
  })
}

# NAT Gateways
locals {
  public_subnet_keys = [for k, v in var.subnets : k if v.tier == "public"]
  nat_subnet_keys    = var.nat_single_az ? [local.public_subnet_keys[0]] : local.public_subnet_keys
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_subnet_keys)
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${each.key}-${var.environment}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each      = aws_eip.nat
  allocation_id = each.value.id
  subnet_id     = aws_subnet.main[each.key].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-${each.key}-${var.environment}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
locals {
  tiers = distinct([for k, v in var.subnets : v.tier])

  route_tables = {
    for tier in local.tiers : tier => {
      subnets = [for k, v in var.subnets : k if v.tier == tier]
      routes = tier == "public" ? {
        igw = { cidr = "0.0.0.0/0", type = "igw" }
        } : tier == "private" ? {
        nat = { cidr = "0.0.0.0/0", type = "nat" }
      } : {}
    }
  }
}

# Its output (route_tables) eg:

/* public = {
  subnets = ["public_1", "public_2"]
  routes = {
    igw = {
      cidr = "0.0.0.0/0"
      type = "igw"
    }
  }
} */

resource "aws_route_table" "main" {
  for_each = local.route_tables
  vpc_id   = aws_vpc.main.id

  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block     = route.value.cidr
      gateway_id     = route.value.type == "igw" ? aws_internet_gateway.main.id : null
      nat_gateway_id = route.value.type == "nat" ? aws_nat_gateway.main[local.nat_subnet_keys[0]].id : null
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-rt-${each.key}-${var.environment}"
  })
}

# Route Table association 
resource "aws_route_table_association" "main" {
  for_each = merge([
    for tier, config in local.route_tables : {
      for subnet_key in config.subnets : "${tier}_${subnet_key}" => {
        rt_key     = tier
        subnet_key = subnet_key
      }
    }
  ]...)

  subnet_id      = aws_subnet.main[each.value.subnet_key].id
  route_table_id = aws_route_table.main[each.value.rt_key].id
}

























