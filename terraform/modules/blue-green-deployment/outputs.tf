# ==============================================================================
# Blue-Green Deployment Module - Outputs
# ==============================================================================

# ------------------------------------------------------------------------------
# Load Balancer Outputs
# ------------------------------------------------------------------------------

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# ------------------------------------------------------------------------------
# Target Group Outputs
# ------------------------------------------------------------------------------

output "blue_target_group_id" {
  description = "ID of the blue target group"
  value       = aws_lb_target_group.blue.id
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "Name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_id" {
  description = "ID of the green target group"
  value       = aws_lb_target_group.green.id
}

output "green_target_group_arn" {
  description = "ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  description = "Name of the green target group"
  value       = aws_lb_target_group.green.name
}

# ------------------------------------------------------------------------------
# Active/Inactive Environment Outputs
# ------------------------------------------------------------------------------

output "active_target_group_arn" {
  description = "ARN of the currently active target group"
  value       = local.active_target_group
}

output "inactive_target_group_arn" {
  description = "ARN of the currently inactive target group"
  value       = local.inactive_target_group
}

output "active_environment" {
  description = "Currently active environment (blue or green)"
  value       = var.active_environment
}

# ------------------------------------------------------------------------------
# Listener Outputs
# ------------------------------------------------------------------------------

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.enable_https ? aws_lb_listener.http[0].arn : aws_lb_listener.http_only[0].arn
}

output "test_listener_arn" {
  description = "ARN of the test traffic listener"
  value       = aws_lb_listener.test.arn
}

# ------------------------------------------------------------------------------
# Monitoring Outputs
# ------------------------------------------------------------------------------

output "blue_unhealthy_hosts_alarm_id" {
  description = "ID of the blue unhealthy hosts CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.blue_unhealthy_hosts.id
}

output "green_unhealthy_hosts_alarm_id" {
  description = "ID of the green unhealthy hosts CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.green_unhealthy_hosts.id
}

output "high_response_time_alarm_id" {
  description = "ID of the high response time CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.high_response_time.id
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.enable_cloudwatch_dashboard ? aws_cloudwatch_dashboard.deployment[0].dashboard_name : null
}

# ------------------------------------------------------------------------------
# Deployment Information
# ------------------------------------------------------------------------------

output "deployment_info" {
  description = "Comprehensive deployment information"
  value = {
    application_name     = var.application_name
    active_environment   = var.active_environment
    alb_dns_name        = aws_lb.main.dns_name
    blue_target_group   = aws_lb_target_group.blue.name
    green_target_group  = aws_lb_target_group.green.name
    test_traffic_port   = var.test_traffic_port
    canary_enabled      = var.enable_canary_deployment
    health_check_path   = var.health_check_path
  }
}

# ------------------------------------------------------------------------------
# Switching Commands (Documentation)
# ------------------------------------------------------------------------------

output "switch_commands" {
  description = "Commands to switch between blue and green environments"
  value = {
    to_green = "Update active_environment variable to 'green' and apply"
    to_blue  = "Update active_environment variable to 'blue' and apply"
    canary_10_percent = "Set canary_weight_active=90, canary_weight_inactive=10, enable_canary_deployment=true"
    canary_50_percent = "Set canary_weight_active=50, canary_weight_inactive=50, enable_canary_deployment=true"
    full_cutover = "Set enable_canary_deployment=false and update active_environment"
  }
}

# ------------------------------------------------------------------------------
# Test URLs
# ------------------------------------------------------------------------------

output "test_urls" {
  description = "URLs for testing both environments"
  value = {
    production_url = var.enable_https ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
    test_url      = "http://${aws_lb.main.dns_name}:${var.test_traffic_port}"
    health_check  = var.enable_https ? "https://${aws_lb.main.dns_name}${var.health_check_path}" : "http://${aws_lb.main.dns_name}${var.health_check_path}"
  }
}
