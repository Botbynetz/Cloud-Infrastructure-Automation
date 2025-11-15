# ==============================================================================
# Blue-Green Deployment Module
# ==============================================================================
# This module implements zero-downtime deployments using ALB target group switching
# Supports blue-green, rolling, and canary deployment strategies

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# Local Variables
# ==============================================================================

locals {
  common_tags = merge(
    var.tags,
    {
      Module     = "blue-green-deployment"
      ManagedBy  = "terraform"
      DeployedAt = timestamp()
    }
  )

  blue_name  = "${var.application_name}-blue"
  green_name = "${var.application_name}-green"

  # Determine active and inactive target groups
  active_target_group   = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  inactive_target_group = var.active_environment == "blue" ? aws_lb_target_group.green.arn : aws_lb_target_group.blue.arn
}

# ==============================================================================
# Application Load Balancer
# ==============================================================================

resource "aws_lb" "main" {
  name               = "${var.application_name}-alb"
  internal           = var.internal_alb
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.alb_subnets

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = var.enable_access_logs
    prefix  = var.application_name
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.application_name}-alb"
    }
  )
}

# ==============================================================================
# Target Groups - Blue Environment
# ==============================================================================

resource "aws_lb_target_group" "blue" {
  name        = local.blue_name
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = "HTTP"
  }

  deregistration_delay = var.deregistration_delay

  stickiness {
    enabled         = var.enable_stickiness
    type            = "lb_cookie"
    cookie_duration = var.stickiness_duration
  }

  tags = merge(
    local.common_tags,
    {
      Name        = local.blue_name
      Environment = "blue"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Target Groups - Green Environment
# ==============================================================================

resource "aws_lb_target_group" "green" {
  name        = local.green_name
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    protocol            = "HTTP"
  }

  deregistration_delay = var.deregistration_delay

  stickiness {
    enabled         = var.enable_stickiness
    type            = "lb_cookie"
    cookie_duration = var.stickiness_duration
  }

  tags = merge(
    local.common_tags,
    {
      Name        = local.green_name
      Environment = "green"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# ALB Listener - HTTP (Redirect to HTTPS)
# ==============================================================================

resource "aws_lb_listener" "http" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

# ==============================================================================
# ALB Listener - HTTPS (Production Traffic)
# ==============================================================================

resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = local.active_target_group
  }

  tags = local.common_tags
}

# ==============================================================================
# ALB Listener - HTTP Only (If HTTPS disabled)
# ==============================================================================

resource "aws_lb_listener" "http_only" {
  count             = var.enable_https ? 0 : 1
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.active_target_group
  }

  tags = local.common_tags
}

# ==============================================================================
# ALB Listener - Test Traffic (For Green Testing)
# ==============================================================================

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.test_traffic_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.inactive_target_group
  }

  tags = merge(
    local.common_tags,
    {
      Purpose = "test-traffic"
    }
  )
}

# ==============================================================================
# Weighted Target Groups (For Canary Deployments)
# ==============================================================================

resource "aws_lb_listener_rule" "canary" {
  count        = var.enable_canary_deployment ? 1 : 0
  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http_only[0].arn
  priority     = 100

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = var.active_environment == "blue" ? var.canary_weight_active : var.canary_weight_inactive
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = var.active_environment == "green" ? var.canary_weight_active : var.canary_weight_inactive
      }

      stickiness {
        enabled  = var.enable_stickiness
        duration = var.stickiness_duration
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ==============================================================================
# Auto Scaling Target Attachments - Blue
# ==============================================================================

resource "aws_autoscaling_attachment" "blue" {
  count                  = var.enable_autoscaling ? 1 : 0
  autoscaling_group_name = var.blue_autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.blue.arn
}

# ==============================================================================
# Auto Scaling Target Attachments - Green
# ==============================================================================

resource "aws_autoscaling_attachment" "green" {
  count                  = var.enable_autoscaling ? 1 : 0
  autoscaling_group_name = var.green_autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.green.arn
}

# ==============================================================================
# CloudWatch Alarms - Blue Target Group
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "blue_unhealthy_hosts" {
  alarm_name          = "${local.blue_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.unhealthy_host_alarm_threshold
  alarm_description   = "Alert when blue target group has unhealthy hosts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = merge(
    local.common_tags,
    {
      Environment = "blue"
    }
  )
}

# ==============================================================================
# CloudWatch Alarms - Green Target Group
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "green_unhealthy_hosts" {
  alarm_name          = "${local.green_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.unhealthy_host_alarm_threshold
  alarm_description   = "Alert when green target group has unhealthy hosts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.green.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = merge(
    local.common_tags,
    {
      Environment = "green"
    }
  )
}

# ==============================================================================
# CloudWatch Alarms - High Response Time
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.application_name}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.response_time_threshold
  alarm_description   = "Alert when target response time is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = local.common_tags
}

# ==============================================================================
# CloudWatch Dashboard
# ==============================================================================

resource "aws_cloudwatch_dashboard" "deployment" {
  count          = var.enable_cloudwatch_dashboard ? 1 : 0
  dashboard_name = "${var.application_name}-blue-green-deployment"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average", label = "Blue Healthy" }],
            ["...", { stat = "Average", label = "Green Healthy" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Blue Unhealthy" }],
            ["...", { stat = "Average", label = "Green Unhealthy" }]
          ]
          period = 60
          region = data.aws_region.current.name
          title  = "Target Health Status"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum" }],
            [".", "TargetResponseTime", { stat = "Average", yAxis = "right" }]
          ]
          period = 60
          region = data.aws_region.current.name
          title  = "Request Count & Response Time"
        }
      }
    ]
  })
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_region" "current" {}
