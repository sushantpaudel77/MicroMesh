resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-order-shipping-${var.environment}"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600

  tags = var.tags
}

# Queue policy is a separate resource to avoid self-referencing
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = var.order_sns_arn
        }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "order_to_sqs" {
  topic_arn = var.order_sns_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn
}
