resource "aws_sns_topic" "main" {
  for_each = var.topics
  name     = "${var.project_name}-${each.value}-${var.environment}"

  tags = var.tags
}

# Email Subscription - For ORDER events & ALARMS
resource "aws_sns_topic_subscription" "email_order" {
  for_each = {
    for k, v in var.topics : k => v
    if v == "order-events"
  }

  topic_arn = aws_sns_topic.main[each.key].arn
  protocol  = "email"
  endpoint  = var.admin_email  
}

resource "aws_sns_topic_subscription" "email_alarms" {
  for_each = {
    for k, v in var.topics : k => v
    if v == "alarms"
  }

  topic_arn = aws_sns_topic.main[each.key].arn
  protocol  = "email"
  endpoint  = var.admin_email
}