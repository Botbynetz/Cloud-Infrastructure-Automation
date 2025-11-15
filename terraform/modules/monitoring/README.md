# CloudWatch Monitoring Module

This Terraform module creates a comprehensive monitoring infrastructure using AWS CloudWatch. It provides dashboards, alarms, log aggregation, metric filters, and CloudWatch Insights queries for complete observability of your AWS infrastructure and applications.

## Features

### 📊 **CloudWatch Dashboards**
- **Infrastructure Dashboard**: EC2, EBS, ALB, and RDS metrics
- **Application Dashboard**: Request counts, response times, error rates, memory, and disk usage
- **Cost Dashboard**: Estimated charges and resource usage tracking
- **Security Dashboard**: Failed logins, unauthorized access, and security events

### 🚨 **CloudWatch Alarms**
- High CPU utilization (configurable threshold)
- High memory utilization (configurable threshold)
- Disk space utilization (85% threshold)
- High error rate (5xx errors)
- Slow response time
- Database CPU utilization (for RDS)
- Database connections (for RDS)
- Composite alarm for overall application health

### 📝 **Log Management**
- Four separate log groups: Application, Infrastructure, Security, Audit
- KMS encryption for all log groups (optional)
- Configurable retention periods
- Log metric filters for automated monitoring

### 🔍 **CloudWatch Insights Queries**
- Top Errors: Identify most common errors
- Slow Requests: Find requests exceeding 1 second
- Security Audit: Track denied or failed actions

### 📈 **Metric Filters**
- Error count tracking
- Warning count tracking
- Security events tracking

## Usage

### Basic Example

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "my-project"
  environment  = "production"

  tags = {
    Project     = "my-project"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Example with Custom Configuration

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "my-project"
  environment  = "production"

  # Log configuration
  log_retention_days          = 90
  security_log_retention_days = 365
  enable_log_encryption       = true

  # Alarm configuration
  enable_alarms            = true
  cpu_alarm_threshold      = 85
  memory_alarm_threshold   = 85
  error_rate_threshold     = 20
  response_time_threshold  = 2000

  # Database monitoring
  enable_database_alarms         = true
  database_connections_threshold = 90

  # SNS notifications
  enable_sns_notifications = true
  notification_emails      = ["devops@example.com", "oncall@example.com"]
  notification_phone_numbers = ["+1234567890"]
  slack_webhook_url        = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

  # X-Ray tracing
  enable_xray_tracing = true
  xray_sampling_rate  = 0.1

  # Cost monitoring
  enable_cost_monitoring   = true
  cost_budget_threshold    = 500
  cost_alert_thresholds    = [50, 80, 100]

  # Security monitoring
  enable_security_monitoring          = true
  security_alert_on_failed_logins     = 5
  security_alert_on_unauthorized_access = true

  tags = {
    Project     = "my-project"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Integration with Existing Infrastructure

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  # Use SNS topic from another module
  alarm_actions = [module.alerting.sns_topic_arn]

  # Enable database monitoring if RDS is deployed
  enable_database_alarms = var.deploy_database

  tags = local.common_tags
}

# Output dashboard URLs for easy access
output "monitoring_dashboards" {
  value = module.monitoring.dashboard_urls
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_name` | Project name for resource naming | `string` | - |
| `environment` | Environment name (dev, staging, production) | `string` | - |

### Optional Variables

#### Log Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `log_retention_days` | Number of days to retain logs | `number` | `30` |
| `security_log_retention_days` | Number of days to retain security logs | `number` | `365` |
| `enable_log_encryption` | Enable KMS encryption for CloudWatch Logs | `bool` | `true` |

#### Alarm Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_alarms` | Enable CloudWatch alarms | `bool` | `true` |
| `alarm_actions` | List of ARNs to notify when alarm triggers | `list(string)` | `[]` |
| `cpu_alarm_threshold` | CPU utilization threshold (percentage) | `number` | `80` |
| `memory_alarm_threshold` | Memory utilization threshold (percentage) | `number` | `80` |
| `error_rate_threshold` | Error rate threshold (errors per minute) | `number` | `10` |
| `response_time_threshold` | Response time threshold in milliseconds | `number` | `1000` |
| `enable_database_alarms` | Enable database-specific alarms | `bool` | `false` |
| `database_connections_threshold` | Maximum database connections threshold | `number` | `80` |

#### Dashboard Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_dashboards` | Enable CloudWatch dashboards | `bool` | `true` |
| `dashboard_widgets` | Custom dashboard widgets configuration | `any` | `{}` |

#### SNS Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_sns_notifications` | Enable SNS notifications for alarms | `bool` | `true` |
| `notification_emails` | List of email addresses for notifications | `list(string)` | `[]` |
| `notification_phone_numbers` | List of phone numbers for SMS notifications | `list(string)` | `[]` |
| `slack_webhook_url` | Slack webhook URL for notifications | `string` | `""` |

#### X-Ray Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_xray_tracing` | Enable AWS X-Ray distributed tracing | `bool` | `false` |
| `xray_sampling_rate` | X-Ray sampling rate (0.0 to 1.0) | `number` | `0.05` |

#### Cost Monitoring

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_cost_monitoring` | Enable cost monitoring dashboard | `bool` | `true` |
| `cost_budget_threshold` | Monthly cost budget threshold in USD | `number` | `100` |
| `cost_alert_thresholds` | Cost alert thresholds (% of budget) | `list(number)` | `[50, 80, 100]` |

#### Security Monitoring

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_security_monitoring` | Enable security monitoring dashboard | `bool` | `true` |
| `security_alert_on_failed_logins` | Failed login attempts before alerting | `number` | `5` |
| `security_alert_on_unauthorized_access` | Alert on unauthorized access | `bool` | `true` |

#### Common Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Common tags to apply to all resources | `map(string)` | `{}` |

## Outputs

### Log Groups

| Name | Description |
|------|-------------|
| `application_log_group_name` | Application log group name |
| `application_log_group_arn` | Application log group ARN |
| `infrastructure_log_group_name` | Infrastructure log group name |
| `infrastructure_log_group_arn` | Infrastructure log group ARN |
| `security_log_group_name` | Security log group name |
| `security_log_group_arn` | Security log group ARN |
| `audit_log_group_name` | Audit log group name |
| `audit_log_group_arn` | Audit log group ARN |

### KMS Keys

| Name | Description |
|------|-------------|
| `kms_key_id` | KMS key ID for log encryption |
| `kms_key_arn` | KMS key ARN for log encryption |
| `kms_key_alias` | KMS key alias for log encryption |

### Dashboards

| Name | Description |
|------|-------------|
| `infrastructure_dashboard_name` | Infrastructure dashboard name |
| `infrastructure_dashboard_arn` | Infrastructure dashboard ARN |
| `application_dashboard_name` | Application dashboard name |
| `application_dashboard_arn` | Application dashboard ARN |
| `cost_dashboard_name` | Cost monitoring dashboard name |
| `cost_dashboard_arn` | Cost monitoring dashboard ARN |
| `security_dashboard_name` | Security monitoring dashboard name |
| `security_dashboard_arn` | Security monitoring dashboard ARN |
| `dashboard_urls` | Map of dashboard URLs for easy access |

### Alarms

| Name | Description |
|------|-------------|
| `high_cpu_alarm_arn` | High CPU alarm ARN |
| `high_memory_alarm_arn` | High memory alarm ARN |
| `disk_full_alarm_arn` | Disk full alarm ARN |
| `high_error_rate_alarm_arn` | High error rate alarm ARN |
| `slow_response_time_alarm_arn` | Slow response time alarm ARN |
| `database_cpu_alarm_arn` | Database CPU alarm ARN |
| `database_connections_alarm_arn` | Database connections alarm ARN |
| `composite_alarm_arn` | Composite application health alarm ARN |

### Metric Filters

| Name | Description |
|------|-------------|
| `error_count_filter_name` | Error count metric filter name |
| `warning_count_filter_name` | Warning count metric filter name |
| `security_events_filter_name` | Security events metric filter name |

### Query Definitions

| Name | Description |
|------|-------------|
| `top_errors_query_id` | Top errors query definition ID |
| `slow_requests_query_id` | Slow requests query definition ID |
| `security_audit_query_id` | Security audit query definition ID |

### Summary

| Name | Description |
|------|-------------|
| `monitoring_summary` | Complete summary of monitoring configuration |

## CloudWatch Alarms

### Alarm Thresholds

| Alarm | Default Threshold | Evaluation Periods | Period |
|-------|-------------------|-------------------|---------|
| High CPU | 80% | 2 | 5 minutes |
| High Memory | 80% | 2 | 5 minutes |
| Disk Full | 85% | 1 | 5 minutes |
| High Error Rate | 10 errors/min | 2 | 1 minute |
| Slow Response | 1000ms | 3 | 1 minute |
| Database CPU | 80% | 2 | 5 minutes |
| Database Connections | 80 connections | 2 | 5 minutes |

### Tuning Recommendations

1. **Development Environment**: Increase thresholds or disable non-critical alarms
   ```hcl
   cpu_alarm_threshold = 90
   memory_alarm_threshold = 90
   enable_database_alarms = false
   ```

2. **Production Environment**: Use stricter thresholds and enable all monitoring
   ```hcl
   cpu_alarm_threshold = 70
   memory_alarm_threshold = 75
   error_rate_threshold = 5
   response_time_threshold = 500
   enable_database_alarms = true
   ```

3. **Cost-Sensitive Projects**: Reduce log retention and disable optional features
   ```hcl
   log_retention_days = 7
   security_log_retention_days = 30
   enable_xray_tracing = false
   ```

## CloudWatch Insights Queries

### Top Errors Query
Finds the 20 most common errors in your application logs:
```
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() as error_count by @message
| sort error_count desc
| limit 20
```

### Slow Requests Query
Identifies the 50 slowest requests (over 1 second):
```
fields @timestamp, @message, duration
| filter duration > 1000
| sort duration desc
| limit 50
```

### Security Audit Query
Tracks security-related events (denied or failed actions):
```
fields @timestamp, @message, action, user
| filter @message like /DENIED/ or @message like /FAILED/
| sort @timestamp desc
| limit 100
```

## Cost Optimization

### Log Retention Strategy
- **Development**: 7 days for application logs, 30 days for security
- **Staging**: 30 days for application logs, 90 days for security
- **Production**: 90 days for application logs, 365 days for security

### Alarm Configuration
- Enable only critical alarms in development
- Use composite alarms to reduce redundant notifications
- Configure SNS subscriptions only for production environments

### Dashboard Optimization
- Disable cost dashboard if AWS Cost Explorer is sufficient
- Use longer metric periods (5 minutes vs 1 minute) for non-critical metrics
- Remove unused custom widgets

## Troubleshooting

### Alarms Not Triggering

1. **Check Metric Data**:
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-01T23:59:59Z \
     --period 300 \
     --statistics Average
   ```

2. **Verify Alarm Configuration**:
   ```bash
   aws cloudwatch describe-alarms --alarm-names high-cpu-alarm
   ```

### Missing Log Data

1. **Check Log Group Permissions**:
   - Ensure the application has `logs:CreateLogStream` and `logs:PutLogEvents` permissions

2. **Verify KMS Key Policy**:
   - If encryption is enabled, ensure CloudWatch Logs has permission to use the KMS key

3. **Check Log Group Retention**:
   ```bash
   aws logs describe-log-groups --log-group-name-prefix "/aws/my-project"
   ```

### Dashboard Not Showing Data

1. **Verify Resource IDs**:
   - Ensure the EC2 instances, ALBs, and RDS instances exist and match the expected naming pattern

2. **Check Metrics Availability**:
   - Some metrics may take 5-15 minutes to appear
   - Custom metrics require proper configuration in your application

3. **Review Dashboard JSON**:
   - Use AWS Console to validate dashboard configuration
   - Check for typos in metric names or namespaces

## Best Practices

### Logging
- Use structured logging (JSON format) for easier parsing
- Include correlation IDs for request tracing
- Log at appropriate levels (DEBUG, INFO, WARN, ERROR)
- Avoid logging sensitive information (passwords, tokens, PII)

### Alerting
- Set alarm thresholds based on historical data
- Use composite alarms to reduce alert fatigue
- Configure different notification channels by severity
- Test alarm notifications regularly

### Cost Management
- Review log retention policies quarterly
- Archive old logs to S3 for long-term storage
- Use metric filters instead of storing all raw logs
- Monitor CloudWatch costs with AWS Cost Explorer

### Security
- Enable log encryption for sensitive data
- Use separate log groups for different security levels
- Implement log aggregation for centralized monitoring
- Enable CloudTrail for API audit logging

## Examples

### Example 1: Basic Monitoring Setup
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "web-app"
  environment  = "production"
}
```

### Example 2: High-Security Environment
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "secure-app"
  environment  = "production"

  # Extended retention for compliance
  log_retention_days          = 90
  security_log_retention_days = 2555  # 7 years

  # Mandatory encryption
  enable_log_encryption = true

  # Enhanced security monitoring
  enable_security_monitoring          = true
  security_alert_on_failed_logins     = 3
  security_alert_on_unauthorized_access = true

  # Multiple notification channels
  notification_emails = [
    "security@example.com",
    "compliance@example.com"
  ]
}
```

### Example 3: Development Environment
```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "dev-app"
  environment  = "dev"

  # Minimal retention to save costs
  log_retention_days          = 7
  security_log_retention_days = 14

  # Relaxed thresholds
  cpu_alarm_threshold    = 95
  memory_alarm_threshold = 95
  error_rate_threshold   = 50

  # Disable optional features
  enable_database_alarms = false
  enable_xray_tracing    = false
  enable_cost_monitoring = false
}
```

## License

This module is part of the Cloud Infrastructure Automation project.

## Support

For issues, questions, or contributions, please visit:
- GitHub: https://github.com/Botbynetz/Cloud-Infrastructure-Automation
- Documentation: https://botbynetz.github.io

## Version

Current Version: 1.5.0

## Changelog

### v1.5.0 (2024-01-16)
- Initial release of monitoring module
- CloudWatch dashboards for infrastructure, application, cost, and security
- Comprehensive alarm configuration
- Log aggregation with KMS encryption
- CloudWatch Insights query definitions
- Metric filters for automated monitoring
