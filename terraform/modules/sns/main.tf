resource "aws_sns_topic" "main" {
  for_each = var.topics
  name     = "${var.project_name}-${each.value}-${var.environment}"

  tags = var.tags
}

# Subscribe alarm email to alarm topic (only if key exists)
resource "aws_sns_topic_subscription" "alarms" {
  for_each  = contains(keys(var.topics), "alarms") ? { alarms = "alarms" } : {}
  topic_arn = aws_sns_topic.main[each.key].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}