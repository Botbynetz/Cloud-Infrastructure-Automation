# ==============================================================================
# CloudWatch Container Insights Module Outputs
# ==============================================================================

# ==============================================================================
# Log Group Outputs
# ==============================================================================

output "fluent_bit_log_group_name" {
  description = "Name of the Fluent Bit log group"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit ? aws_cloudwatch_log_group.fluent_bit[0].name : null
}

output "fluent_bit_log_group_arn" {
  description = "ARN of the Fluent Bit log group"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit ? aws_cloudwatch_log_group.fluent_bit[0].arn : null
}

output "ecs_insights_log_group_name" {
  description = "Name of the ECS Container Insights log group"
  value       = var.enable_ecs_insights ? aws_cloudwatch_log_group.container_insights[0].name : null
}

output "ecs_insights_log_group_arn" {
  description = "ARN of the ECS Container Insights log group"
  value       = var.enable_ecs_insights ? aws_cloudwatch_log_group.container_insights[0].arn : null
}

output "eks_insights_log_group_name" {
  description = "Name of the EKS Container Insights log group"
  value       = var.enable_eks_insights && var.eks_cluster_name != "" ? aws_cloudwatch_log_group.eks_insights[0].name : null
}

output "eks_insights_log_group_arn" {
  description = "ARN of the EKS Container Insights log group"
  value       = var.enable_eks_insights && var.eks_cluster_name != "" ? aws_cloudwatch_log_group.eks_insights[0].arn : null
}

output "eks_application_log_group_name" {
  description = "Name of the EKS application log group"
  value       = var.enable_eks_insights && var.eks_cluster_name != "" ? aws_cloudwatch_log_group.eks_application[0].name : null
}

output "eks_application_log_group_arn" {
  description = "ARN of the EKS application log group"
  value       = var.enable_eks_insights && var.eks_cluster_name != "" ? aws_cloudwatch_log_group.eks_application[0].arn : null
}

# ==============================================================================
# ECS Fluent Bit Outputs
# ==============================================================================

output "fluent_bit_task_definition_arn" {
  description = "ARN of the Fluent Bit task definition"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit ? aws_ecs_task_definition.fluent_bit[0].arn : null
}

output "fluent_bit_service_name" {
  description = "Name of the Fluent Bit ECS service"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit && var.ecs_subnet_ids != null ? aws_ecs_service.fluent_bit[0].name : null
}

output "fluent_bit_task_role_arn" {
  description = "ARN of the Fluent Bit task IAM role"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit ? aws_iam_role.fluent_bit[0].arn : null
}

output "fluent_bit_execution_role_arn" {
  description = "ARN of the Fluent Bit execution IAM role"
  value       = var.enable_ecs_insights && var.deploy_fluent_bit ? aws_iam_role.fluent_bit_execution[0].arn : null
}

# ==============================================================================
# Alarm Outputs
# ==============================================================================

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU utilization alarm"
  value       = var.enable_container_alarms ? aws_cloudwatch_metric_alarm.high_cpu_utilization[0].arn : null
}

output "high_memory_alarm_arn" {
  description = "ARN of the high memory utilization alarm"
  value       = var.enable_container_alarms ? aws_cloudwatch_metric_alarm.high_memory_utilization[0].arn : null
}

output "container_restart_alarm_arn" {
  description = "ARN of the container restart alarm"
  value       = var.enable_container_alarms ? aws_cloudwatch_metric_alarm.container_restart_count[0].arn : null
}

# ==============================================================================
# Dashboard Outputs
# ==============================================================================

output "dashboard_name" {
  description = "Name of the Container Insights CloudWatch dashboard"
  value       = var.enable_container_dashboard ? aws_cloudwatch_dashboard.container_insights[0].dashboard_name : null
}

output "dashboard_arn" {
  description = "ARN of the Container Insights CloudWatch dashboard"
  value       = var.enable_container_dashboard ? aws_cloudwatch_dashboard.container_insights[0].dashboard_arn : null
}

# ==============================================================================
# Query Definition Outputs
# ==============================================================================

output "top_cpu_tasks_query_id" {
  description = "ID of the top CPU tasks query definition"
  value       = var.enable_ecs_insights ? aws_cloudwatch_query_definition.top_cpu_tasks[0].query_definition_id : null
}

output "top_memory_tasks_query_id" {
  description = "ID of the top memory tasks query definition"
  value       = var.enable_ecs_insights ? aws_cloudwatch_query_definition.top_memory_tasks[0].query_definition_id : null
}

# ==============================================================================
# Console URLs
# ==============================================================================

output "console_urls" {
  description = "AWS Console URLs for Container Insights resources"
  value = {
    ecs_insights = var.enable_ecs_insights ? "https://console.aws.amazon.com/ecs/home?region=${data.aws_region.current.name}#/clusters/${var.ecs_cluster_name}/containerInsights" : null
    eks_insights = var.enable_eks_insights ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#container-insights:infrastructure/EKS:Cluster/${var.eks_cluster_name}" : null
    dashboard    = var.enable_container_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${var.enable_container_dashboard ? aws_cloudwatch_dashboard.container_insights[0].dashboard_name : ""}" : null
  }
}

# ==============================================================================
# Configuration Summary
# ==============================================================================

output "container_insights_summary" {
  description = "Summary of Container Insights configuration"
  value = {
    project_name = var.project_name
    environment  = var.environment
    ecs = {
      enabled           = var.enable_ecs_insights
      cluster_name      = var.ecs_cluster_name
      fluent_bit_deployed = var.deploy_fluent_bit
      fluent_bit_cpu    = var.fluent_bit_cpu
      fluent_bit_memory = var.fluent_bit_memory
    }
    eks = {
      enabled      = var.enable_eks_insights
      cluster_name = var.eks_cluster_name
    }
    logging = {
      retention_days = var.log_retention_days
      encryption_enabled = var.enable_log_encryption
    }
    alarms = {
      enabled               = var.enable_container_alarms
      cpu_threshold         = var.cpu_utilization_threshold
      memory_threshold      = var.memory_utilization_threshold
      restart_threshold     = var.container_restart_threshold
    }
    dashboard_enabled = var.enable_container_dashboard
  }
}
