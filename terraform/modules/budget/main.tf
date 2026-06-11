# AWS Budget - Monthly Cost Budget
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_amount
  limit_unit        = "USD"
  time_period_start = "${var.time_period_start}_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.warning_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = var.sns_topic_arns
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.critical_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = var.sns_topic_arns
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.forecast_threshold
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = var.sns_topic_arns
  }

  tags = var.tags
}

# Optional: Cost Anomaly Detection
resource "aws_ce_anomaly_monitor" "cost" {
  count = var.enable_anomaly_detection ? 1 : 0

  name              = "${var.project_name}-${var.environment}-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "cost" {
  count = var.enable_anomaly_detection ? 1 : 0

  name      = "${var.project_name}-${var.environment}-cost-subscription"
  frequency = "IMMEDIATE"

  monitor_arn_list = [aws_ce_anomaly_monitor.cost[0].arn]

  subscriber {
    type    = "EMAIL"
    address = var.notification_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["10.0"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
