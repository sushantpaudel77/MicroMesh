# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = var.alarms

  alarm_name          = "${var.project_name}-${each.key}-${var.environment}"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.eval_periods
  metric_name         = each.value.metric
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = [var.alarm_topic_arn]
  ok_actions          = [var.alarm_topic_arn]

  dimensions = each.value.dimensions

  treat_missing_data = "notBreaching"

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: ECS CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          title   = "ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster-${var.environment}", { stat = "Average" }]
          ]
        }
      },
      # Widget 2: RDS Connections
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          title   = "RDS Database Connections"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project_name}-${var.environment}", { stat = "Average" }]
          ]
        }
      },
      # Widget 3: Lambda Invocations & Errors
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          title   = "Lambda - Invocations & Errors"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-shipping-processor-${var.environment}", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", ".", ".", { stat = "Sum", label = "Errors" }]
          ]
        }
      },
      # Widget 4: SQS Queue
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          title   = "SQS - Messages Visible"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${var.project_name}-order-shipping-${var.environment}", { stat = "Average" }]
          ]
        }
      },
      # Widget 5: DynamoDB Throttled Requests
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          title   = "DynamoDB - Throttled Requests"
          metrics = [
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", "${var.project_name}-${var.environment}-products", { stat = "Sum", label = "Products" }],
            [".", ".", ".", "${var.project_name}-${var.environment}-shipping", { stat = "Sum", label = "Shipping" }]
          ]
        }
      },
      # Widget 6: SNS Messages Published
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          title   = "SNS - Messages Published"
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", "${var.project_name}-order-events-${var.environment}", { stat = "Sum" }]
          ]
        }
      },
      # Widget 7: ALB Request Count
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          title   = "ALB - Request Count"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.project_name}-alb-${var.environment}", { stat = "Sum" }]
          ]
        }
      },
      # Widget 8: ElastiCache Metrics
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          title   = "ElastiCache - CPU"
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", "${var.project_name}-cache-${var.environment}", { stat = "Average" }]
          ]
        }
      },
      # Widget 9: Recent Errors (Log Table)
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          view   = "table"
          region = "us-east-1"
          title  = "Recent Errors (Last 1 Hour)"
          query  = "fields @timestamp, @logGroup, @message\n| filter @message like /ERROR|Error|Failed|Exception/\n| sort @timestamp desc\n| limit 30"
        }
      }
    ]
  })
}

# Composite Alarm - Critical System Health
resource "aws_cloudwatch_composite_alarm" "system_health" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name        = "${var.project_name}-system-health-${var.environment}"
  alarm_description = "Composite alarm for critical system failures"

  alarm_actions = [var.alarm_topic_arn]
  ok_actions    = [var.alarm_topic_arn]

  alarm_rule = join(" OR ", [
    for alarm in aws_cloudwatch_metric_alarm.main : "ALARM(${alarm.alarm_name})"
  ])

  tags = var.tags
}
