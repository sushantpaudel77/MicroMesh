# Security groups
resource "aws_security_group" "main" {
  for_each    = var.security_groups
  name        = "${var.project_name}-${each.value.name}-sg-${var.environment}"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.value.name}-sg-${var.environment}"
  })
}

# Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = merge([
    for sg_key, sg_config in var.security_groups : {
      for rule_key, rule in sg_config.ingress : "${sg_key}_${rule_key}" => {
        sg_id       = aws_security_group.main[sg_key].id
        from_port   = rule.from
        to_port     = rule.to
        ip_protocol = rule.proto
        cidr_ipv4   = try(rule.cidr, null)
        ref_sg_id   = try(rule.source_sg, null) != null ? aws_security_group.main[rule.source_sg].id : null
      }
    }
  ]...)

  security_group_id            = each.value.sg_id
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.ref_sg_id
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each          = aws_security_group.main
  security_group_id = each.value.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}
