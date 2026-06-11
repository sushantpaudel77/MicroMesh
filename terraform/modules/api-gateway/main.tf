resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-vpclink-${var.environment}"
  subnet_ids         = var.subnet_ids
  security_group_ids = [var.security_group_id]

  tags = var.tags
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = ["https://${var.frontend_domain}"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["*"]
    allow_credentials = true
    max_age           = 300
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "main" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = var.alb_listener_arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.main.id
}

resource "aws_apigatewayv2_authorizer" "main" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-${var.environment}"

  jwt_configuration {
    audience = [var.cognito_client_id]
    # var.cognito_user_pool_id is passed directly — no ARN parsing needed
    issuer = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# Add data sources for region
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_apigatewayv2_route" "public_get_products" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /products"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# OPTIONS preflight route — NO auth, so browsers can complete CORS handshake
resource "aws_apigatewayv2_route" "options_preflight" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "OPTIONS /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.main.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "authenticated" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.main.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.main.id
}

# Create CloudWatch log group first
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      protocol       = "$context.protocol"
    })
  }

  depends_on = [aws_cloudwatch_log_group.api]
}
