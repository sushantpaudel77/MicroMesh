# Target Groups (for_each on services)
resource "aws_lb_target_group" "main" {
  for_each = var.services

  name        = "${var.project_name}-${each.key}-tg-${var.environment}"
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = each.value.health_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-tg-${var.environment}"
  })
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-${var.environment}"
  })
}

# Listener (Default: product service)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main["product"].arn
  }
}

# Listener Rules 
resource "aws_lb_listener_rule" "main" {
  for_each = {
    for k, v in var.services : k => v if k != "product"
  }

  listener_arn = aws_lb_listener.main.arn
  priority     = each.value.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}
