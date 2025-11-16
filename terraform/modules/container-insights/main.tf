# ==============================================================================
# CloudWatch Container Insights Module
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ==============================================================================
# Data Sources
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# ECS Container Insights Configuration
# ==============================================================================

resource "aws_ecs_cluster_capacity_providers" "main" {
  count = var.enable_ecs_insights && var.ecs_cluster_name != "" ? 1 : 0

  cluster_name = var.ecs_cluster_name

  capacity_providers = var.ecs_capacity_providers

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.ecs_capacity_providers[0]
  }
}

# ==============================================================================
# ECS Task Definition for Fluent Bit (Log Collection)
# ==============================================================================

resource "aws_ecs_task_definition" "fluent_bit" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-fluent-bit"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fluent_bit_cpu
  memory                   = var.fluent_bit_memory
  task_role_arn            = aws_iam_role.fluent_bit[0].arn
  execution_role_arn       = aws_iam_role.fluent_bit_execution[0].arn

  container_definitions = jsonencode([
    {
      name      = "fluent-bit"
      image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
          config-file-type        = "file"
          config-file-value       = "/fluent-bit/configs/parse-json.conf"
        }
      }

      environment = [
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "CLUSTER_NAME"
          value = var.ecs_cluster_name
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.fluent_bit[0].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "fluent-bit"
        }
      }

      memoryReservation = var.fluent_bit_memory
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-fluent-bit"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# ECS Service for Fluent Bit
# ==============================================================================

resource "aws_ecs_service" "fluent_bit" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit && var.ecs_subnet_ids != null ? 1 : 0

  name            = "${var.project_name}-${var.environment}-fluent-bit"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.fluent_bit[0].arn
  desired_count   = var.fluent_bit_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.ecs_subnet_ids
    security_groups  = var.ecs_security_group_ids
    assign_public_ip = false
  }

  enable_execute_command = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-fluent-bit"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Log Groups for Container Insights
# ==============================================================================

resource "aws_cloudwatch_log_group" "fluent_bit" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  name              = "/aws/ecs/containerinsights/${var.ecs_cluster_name}/fluent-bit"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-fluent-bit-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "container_insights" {
  count = var.enable_ecs_insights ? 1 : 0

  name              = "/aws/ecs/containerinsights/${var.ecs_cluster_name}/performance"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-container-insights"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# IAM Roles for Fluent Bit
# ==============================================================================

resource "aws_iam_role" "fluent_bit" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  name = "${var.project_name}-${var.environment}-fluent-bit-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-fluent-bit-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "fluent_bit" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  name = "${var.project_name}-${var.environment}-fluent-bit-policy"
  role = aws_iam_role.fluent_bit[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/containerinsights/${var.ecs_cluster_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeContainerInstances",
          "ecs:ListTasks"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "fluent_bit_execution" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  name = "${var.project_name}-${var.environment}-fluent-bit-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-fluent-bit-exec"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "fluent_bit_execution" {
  count = var.enable_ecs_insights && var.deploy_fluent_bit ? 1 : 0

  role       = aws_iam_role.fluent_bit_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==============================================================================
# EKS Container Insights Configuration
# ==============================================================================

# Note: EKS Container Insights is typically enabled via the EKS cluster configuration
# This section provides the necessary IAM policies and CloudWatch configuration

resource "aws_iam_role_policy_attachment" "eks_container_insights" {
  count = var.enable_eks_insights && var.eks_cluster_role_name != "" ? 1 : 0

  role       = var.eks_cluster_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_log_group" "eks_insights" {
  count = var.enable_eks_insights && var.eks_cluster_name != "" ? 1 : 0

  name              = "/aws/containerinsights/${var.eks_cluster_name}/performance"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-eks-insights"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "eks_application" {
  count = var.enable_eks_insights && var.eks_cluster_name != "" ? 1 : 0

  name              = "/aws/containerinsights/${var.eks_cluster_name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.enable_log_encryption ? var.kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-eks-app-logs"
      Environment = var.environment
    }
  )
}

# ==============================================================================
# CloudWatch Alarms for Container Insights
# ==============================================================================

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  count = var.enable_container_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-container-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CpuUtilized"
  namespace           = var.enable_ecs_insights ? "ECS/ContainerInsights" : "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "Container CPU utilization is above threshold"
  alarm_actions       = var.alarm_actions

  dimensions = var.enable_ecs_insights ? {
    ClusterName = var.ecs_cluster_name
  } : {
    ClusterName = var.eks_cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-container-cpu-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "high_memory_utilization" {
  count = var.enable_container_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-container-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilized"
  namespace           = var.enable_ecs_insights ? "ECS/ContainerInsights" : "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold
  alarm_description   = "Container memory utilization is above threshold"
  alarm_actions       = var.alarm_actions

  dimensions = var.enable_ecs_insights ? {
    ClusterName = var.ecs_cluster_name
  } : {
    ClusterName = var.eks_cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-container-memory-alarm"
      Environment = var.environment
      Severity    = "warning"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "container_restart_count" {
  count = var.enable_container_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-container-restarts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ContainerRestartCount"
  namespace           = var.enable_ecs_insights ? "ECS/ContainerInsights" : "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = var.container_restart_threshold
  alarm_description   = "Container restart count exceeded threshold"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = var.enable_ecs_insights ? {
    ClusterName = var.ecs_cluster_name
  } : {
    ClusterName = var.eks_cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-container-restart-alarm"
      Environment = var.environment
      Severity    = "critical"
    }
  )
}

# ==============================================================================
# CloudWatch Dashboard for Container Insights
# ==============================================================================

resource "aws_cloudwatch_dashboard" "container_insights" {
  count = var.enable_container_dashboard ? 1 : 0

  dashboard_name = "${var.project_name}-${var.environment}-container-insights"

  dashboard_body = jsonencode({
    widgets = concat(
      var.enable_ecs_insights ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["ECS/ContainerInsights", "CpuUtilized", { "stat" : "Average" }],
              ["...", { "stat" : "Maximum" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "ECS CPU Utilization"
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ECS/ContainerInsights", "MemoryUtilized", { "stat" : "Average" }],
              ["...", { "stat" : "Maximum" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "ECS Memory Utilization"
            yAxis = {
              left = { min = 0 }
            }
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ECS/ContainerInsights", "TaskCount", { "stat" : "Average" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "ECS Task Count"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ECS/ContainerInsights", "NetworkRxBytes", { "stat" : "Sum" }],
              [".", "NetworkTxBytes", { "stat" : "Sum" }]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "ECS Network Traffic"
          }
        }
      ] : [],
      var.enable_eks_insights ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["ContainerInsights", "node_cpu_utilization", { "stat" : "Average" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "EKS Node CPU Utilization"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ContainerInsights", "node_memory_utilization", { "stat" : "Average" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "EKS Node Memory Utilization"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ContainerInsights", "pod_cpu_utilization", { "stat" : "Average" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "EKS Pod CPU Utilization"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              ["ContainerInsights", "pod_memory_utilization", { "stat" : "Average" }]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "EKS Pod Memory Utilization"
          }
        }
      ] : []
    )
  })
}

# ==============================================================================
# CloudWatch Insights Queries
# ==============================================================================

resource "aws_cloudwatch_query_definition" "top_cpu_tasks" {
  count = var.enable_ecs_insights ? 1 : 0

  name = "${var.project_name}-${var.environment}-top-cpu-tasks"

  log_group_names = [
    aws_cloudwatch_log_group.container_insights[0].name
  ]

  query_string = <<-EOT
    fields @timestamp, TaskDefinitionFamily, CpuUtilized
    | filter Type = "Task"
    | sort CpuUtilized desc
    | limit 20
  EOT
}

resource "aws_cloudwatch_query_definition" "top_memory_tasks" {
  count = var.enable_ecs_insights ? 1 : 0

  name = "${var.project_name}-${var.environment}-top-memory-tasks"

  log_group_names = [
    aws_cloudwatch_log_group.container_insights[0].name
  ]

  query_string = <<-EOT
    fields @timestamp, TaskDefinitionFamily, MemoryUtilized
    | filter Type = "Task"
    | sort MemoryUtilized desc
    | limit 20
  EOT
}
