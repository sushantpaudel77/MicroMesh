resource "aws_lambda_function" "main" {
  filename         = "${path.module}/shipping-processor.zip"
  function_name    = "${var.project_name}-shipping-processor-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      SHIPPING_SERVICE_URL = "http://${var.alb_dns}"
    }
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.main.arn
  batch_size       = 10
}