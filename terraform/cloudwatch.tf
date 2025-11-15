# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "syslog" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/ec2/${var.environment}/syslog"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name        = "${var.project_name}-syslog-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "nginx_access" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/ec2/${var.environment}/nginx-access"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name        = "${var.project_name}-nginx-access-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/ec2/${var.environment}/nginx-error"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name        = "${var.project_name}-nginx-error-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = module.ec2.instance_id
  }

  tags = {
    Name        = "${var.project_name}-high-cpu-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUsedPercent"
  namespace           = "CloudInfra/${var.environment}"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors memory utilization"
  alarm_actions       = []

  tags = {
    Name        = "${var.project_name}-high-memory-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_disk" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskUsedPercent"
  namespace           = "CloudInfra/${var.environment}"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors disk utilization"
  alarm_actions       = []

  tags = {
    Name        = "${var.project_name}-high-disk-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_health" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-instance-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors instance status checks"
  alarm_actions       = []

  dimensions = {
    InstanceId = module.ec2.instance_id
  }

  tags = {
    Name        = "${var.project_name}-instance-health-${var.environment}"
    Environment = var.environment
  }
}

# IAM Role for CloudWatch
resource "aws_iam_role" "cloudwatch" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.project_name}-cloudwatch-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cloudwatch-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.enable_monitoring ? 1 : 0
  role       = aws_iam_role.cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.project_name}-cloudwatch-profile-${var.environment}"
  role  = aws_iam_role.cloudwatch[0].name

  tags = {
    Name        = "${var.project_name}-cloudwatch-profile-${var.environment}"
    Environment = var.environment
  }
}
