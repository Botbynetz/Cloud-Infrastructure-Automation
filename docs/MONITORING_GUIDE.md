# Enhanced Monitoring & Observability Guide

## Overview

This guide provides comprehensive information about the monitoring and observability infrastructure implemented in Phase 5 of the Cloud Infrastructure Automation project. The implementation includes CloudWatch dashboards, centralized logging, advanced alerting, and application performance monitoring.

## Architecture

### Components

1. **CloudWatch Monitoring Module** (`terraform/modules/monitoring/`)
   - 4 specialized dashboards (Infrastructure, Application, Cost, Security)
   - 8 CloudWatch alarms with configurable thresholds
   - Log groups with KMS encryption
   - Metric filters for automated monitoring
   - CloudWatch Insights queries

2. **Centralized Logging Module** (`terraform/modules/centralized-logging/`)
   - S3 export for long-term log storage with lifecycle policies
   - Kinesis Data Streams for real-time log processing
   - Cross-account log aggregation
   - Automated daily log export via Lambda
   - CloudWatch Logs subscription filters

3. **Advanced Alerting Module** (`terraform/modules/alerting/`)
   - Multi-severity SNS topics (Critical, Warning, Info)
   - Email and SMS notifications
   - Slack integration via Lambda
   - PagerDuty integration for incident management
   - Alert aggregation to prevent fatigue
   - Step Functions for alert escalation

## Quick Start

### 1. Deploy Monitoring Infrastructure

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name = "my-project"
  environment  = "production"

  # Enable all monitoring features
  enable_dashboards = true
  enable_alarms     = true
  
  # Configure alarm thresholds
  cpu_alarm_threshold     = 80
  memory_alarm_threshold  = 80
  error_rate_threshold    = 10
  
  tags = local.common_tags
}
```

### 2. Set Up Centralized Logging

```hcl
module "centralized_logging" {
  source = "./modules/centralized-logging"

  project_name = "my-project"
  environment  = "production"

  # Reference log groups from monitoring module
  application_log_group_name    = module.monitoring.application_log_group_name
  infrastructure_log_group_name = module.monitoring.infrastructure_log_group_name
  security_log_group_name       = module.monitoring.security_log_group_name
  audit_log_group_name          = module.monitoring.audit_log_group_name

  # Enable S3 export
  enable_log_export = true
  s3_transition_days = 90
  s3_expiration_days = 2555  # 7 years

  # Enable Kinesis streaming for real-time processing
  enable_kinesis_streaming = true
  kinesis_shard_count      = 2

  tags = local.common_tags
}
```

### 3. Configure Advanced Alerting

```hcl
module "alerting" {
  source = "./modules/alerting"

  project_name = "my-project"
  environment  = "production"

  # Email notifications
  critical_email_endpoints = ["oncall@example.com", "devops@example.com"]
  warning_email_endpoints  = ["devops@example.com"]
  info_email_endpoints     = ["team@example.com"]

  # SMS for critical alerts
  enable_sms_notifications = true
  critical_sms_endpoints   = ["+1234567890"]

  # Slack integration
  enable_slack_notifications = true
  slack_webhook_url          = var.slack_webhook_url
  slack_channel              = "#production-alerts"

  # PagerDuty for incident management
  enable_pagerduty_notifications = true
  pagerduty_integration_key      = var.pagerduty_key

  # Alert aggregation
  enable_alert_aggregation   = true
  alert_aggregation_window   = 300  # 5 minutes

  # Escalation workflow
  enable_escalation    = true
  escalation_wait_time = 900  # 15 minutes

  tags = local.common_tags
}

# Connect monitoring alarms to alerting
resource "aws_cloudwatch_metric_alarm" "example" {
  # ... alarm configuration ...
  
  alarm_actions = [
    module.alerting.critical_topic_arn
  ]
  
  ok_actions = [
    module.alerting.info_topic_arn
  ]
}
```

## Dashboard Guide

### Infrastructure Dashboard

**Metrics Tracked:**
- EC2 CPU Utilization (0-100%)
- Network In/Out (bytes)
- EBS Read/Write Operations
- ALB Request Count & Response Time
- ALB 4XX/5XX Errors
- RDS CPU & Connection Count
- RDS Free Storage

**Access:** AWS Console → CloudWatch → Dashboards → `{project}-{env}-infrastructure`

### Application Dashboard

**Metrics Tracked:**
- Request Count (requests/minute)
- Response Time (average & p99)
- Error Rate (total, 4XX, 5XX)
- Memory Utilization
- Disk Utilization

**Access:** AWS Console → CloudWatch → Dashboards → `{project}-{env}-application`

### Cost Dashboard

**Metrics Tracked:**
- Estimated AWS Charges (6-hour periods)
- Resource Usage Count

**Access:** AWS Console → CloudWatch → Dashboards → `{project}-{env}-cost`

**Tip:** Use this dashboard to monitor spending trends and set up budget alerts.

### Security Dashboard

**Log Queries:**
- Failed Login Attempts (5-minute bins)
- Unauthorized Access (403 errors)
- Recent Security Events (last 100)

**Access:** AWS Console → CloudWatch → Dashboards → `{project}-{env}-security`

## Alarm Configuration

### Standard Alarms

| Alarm | Threshold | Evaluation | Action |
|-------|-----------|------------|--------|
| High CPU | 80% | 2 x 5 min | Critical |
| High Memory | 80% | 2 x 5 min | Critical |
| Disk Full | 85% | 1 x 5 min | Critical |
| High Error Rate | 10 errors/min | 2 x 1 min | Critical |
| Slow Response | 1000ms | 3 x 1 min | Warning |
| DB CPU High | 80% | 2 x 5 min | Warning |
| DB Connections | 80 | 2 x 5 min | Warning |

### Composite Alarm

**Application Health** = High CPU OR High Memory OR High Error Rate

This composite alarm triggers when any critical system metric exceeds thresholds, providing a single point of reference for overall application health.

### Tuning Recommendations

**Development:**
```hcl
cpu_alarm_threshold    = 95
memory_alarm_threshold = 95
enable_database_alarms = false
```

**Staging:**
```hcl
cpu_alarm_threshold    = 85
memory_alarm_threshold = 85
enable_database_alarms = true
```

**Production:**
```hcl
cpu_alarm_threshold    = 70
memory_alarm_threshold = 75
error_rate_threshold   = 5
response_time_threshold = 500
enable_database_alarms = true
```

## Centralized Logging

### Log Groups

1. **Application Logs** (`/aws/{project}/{env}/application`)
   - Application-level events
   - User actions
   - Business logic errors
   - Retention: 30 days (configurable)

2. **Infrastructure Logs** (`/aws/{project}/{env}/infrastructure`)
   - EC2 system logs
   - Container logs
   - Platform events
   - Retention: 30 days (configurable)

3. **Security Logs** (`/aws/{project}/{env}/security`)
   - Authentication attempts
   - Authorization failures
   - Security events
   - Retention: 365 days (default)

4. **Audit Logs** (`/aws/{project}/{env}/audit`)
   - API calls
   - Configuration changes
   - Compliance events
   - Retention: 365 days (minimum)

### S3 Log Export

Logs are automatically exported to S3 with the following lifecycle:

1. **Active Storage** (0-90 days): Standard S3
2. **Archive** (90-180 days): Glacier
3. **Deep Archive** (180-2555 days): Deep Archive
4. **Expiration** (2555+ days): Deleted (7 years retention for compliance)

**S3 Bucket:** `{project}-{env}-cloudwatch-logs-{account-id}`

### Kinesis Streaming

Real-time log streaming enables:
- Live log analysis
- Real-time alerting
- Integration with third-party tools
- Data lake ingestion

**Stream Name:** `{project}-{env}-logs`
**Retention:** 24 hours (configurable up to 365 days)

### CloudWatch Insights Queries

**Top Errors:**
```
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() as error_count by @message
| sort error_count desc
| limit 20
```

**Slow Requests:**
```
fields @timestamp, @message, duration
| filter duration > 1000
| sort duration desc
| limit 50
```

**Security Audit:**
```
fields @timestamp, @message, action, user
| filter @message like /DENIED/ or @message like /FAILED/
| sort @timestamp desc
| limit 100
```

## Advanced Alerting

### Severity Levels

**Critical:**
- System-impacting issues
- Service outages
- Security breaches
- Notifications: Email, SMS, Slack, PagerDuty
- Escalation: 15 minutes if unacknowledged

**Warning:**
- Performance degradation
- Resource constraints
- Unusual activity
- Notifications: Email, Slack
- No automatic escalation

**Info:**
- Informational events
- Successful deployments
- System changes
- Notifications: Email only

### Notification Channels

#### Email
- Automatic subscription via Terraform
- Requires manual confirmation
- Best for: Non-urgent alerts, team notifications

#### SMS
- Critical alerts only
- E.164 format phone numbers required
- Best for: On-call engineers, urgent issues

#### Slack
- Rich formatting with color-coded messages
- Direct links to CloudWatch console
- Best for: Team visibility, rapid response

#### PagerDuty
- Automatic incident creation
- Integration with on-call schedules
- Escalation policies
- Best for: Production incidents, on-call management

### Alert Aggregation

Prevents alert fatigue by:
- Deduplicating similar alerts within 5-minute window
- Counting repeated occurrences
- Sending summary notifications at thresholds (5, 10, 20+ occurrences)
- Storing alert state in DynamoDB

**Example:**
```
Alert: high-cpu-alarm triggers 8 times in 5 minutes
Result: 
  - First alert: Sent immediately
  - Alerts 2-4: Aggregated silently
  - Alert 5: Summary sent ("5 occurrences")
  - Alerts 6-9: Aggregated silently
  - Alert 10: Summary sent ("10 occurrences")
```

### Escalation Workflow

1. Critical alert triggered
2. Initial notification sent (Email, SMS, Slack, PagerDuty)
3. Wait for acknowledgment (15 minutes default)
4. If not acknowledged:
   - Send escalation notification
   - Notify backup on-call
   - Create high-priority PagerDuty incident
5. Continue until resolved

## Cost Optimization

### Log Retention Strategy

| Environment | Application | Security | Estimated Cost |
|-------------|-------------|----------|----------------|
| Development | 7 days | 30 days | $5-10/month |
| Staging | 30 days | 90 days | $15-25/month |
| Production | 90 days | 365 days | $50-100/month |

### Dashboard Optimization

- Use 5-minute periods for non-critical metrics
- Disable unused dashboards
- Combine related metrics into single widgets
- Consider using CloudWatch metric math for derived metrics

### Alerting Cost Reduction

- Use alert aggregation to reduce SNS message volume
- Limit SMS to critical alerts only
- Use email for info/warning alerts
- Set appropriate evaluation periods

### S3 Storage Optimization

- Enable S3 Intelligent-Tiering for unpredictable access patterns
- Use Glacier/Deep Archive for compliance logs
- Set appropriate expiration policies
- Compress logs before export

## Troubleshooting

### Alarms Not Triggering

**Check:**
1. Metric data is being published
2. Alarm state is enabled
3. Evaluation period hasn't elapsed
4. Threshold configuration is correct
5. SNS topic subscriptions are confirmed

**Fix:**
```bash
# Check alarm status
aws cloudwatch describe-alarms --alarm-names {alarm-name}

# Check metric data
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

### Logs Not Appearing

**Check:**
1. Log group exists
2. Application has correct IAM permissions
3. KMS key permissions (if encryption enabled)
4. Log retention hasn't expired
5. Application is logging to correct log group

**Fix:**
```bash
# Verify log group
aws logs describe-log-groups --log-group-name-prefix "/aws/{project}"

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn {role-arn} \
  --action-names logs:CreateLogStream logs:PutLogEvents
```

### Slack Notifications Not Working

**Check:**
1. Webhook URL is correct
2. Lambda function has internet access
3. Lambda execution role has permissions
4. SNS topic subscription is confirmed
5. Check Lambda CloudWatch Logs

**Fix:**
```bash
# Test Lambda manually
aws lambda invoke \
  --function-name {function-name} \
  --payload file://test-event.json \
  response.json

# Check Lambda logs
aws logs tail /aws/lambda/{function-name} --follow
```

### PagerDuty Integration Issues

**Check:**
1. Integration key is correct
2. PagerDuty service is active
3. Lambda has internet access
4. Check PagerDuty service event log

**Test:**
```bash
# Test PagerDuty API
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H 'Content-Type: application/json' \
  -d '{
    "routing_key": "YOUR_INTEGRATION_KEY",
    "event_action": "trigger",
    "payload": {
      "summary": "Test alert",
      "source": "test",
      "severity": "info"
    }
  }'
```

## Best Practices

### Logging

1. **Use structured logging** (JSON format)
2. **Include correlation IDs** for request tracing
3. **Log at appropriate levels** (DEBUG, INFO, WARN, ERROR, FATAL)
4. **Avoid logging sensitive data** (passwords, tokens, PII)
5. **Use log sampling** for high-volume applications
6. **Include context** (user ID, session ID, action)

### Alerting

1. **Set realistic thresholds** based on historical data
2. **Use composite alarms** to reduce noise
3. **Configure different channels** by severity
4. **Test alert notifications** regularly
5. **Document runbooks** for each alarm
6. **Review and tune** alert thresholds quarterly

### Dashboard Design

1. **Group related metrics** together
2. **Use consistent time ranges** across widgets
3. **Include annotations** for deployments
4. **Add links** to related dashboards
5. **Keep dashboards focused** (one purpose per dashboard)
6. **Use meaningful names** and descriptions

### Cost Management

1. **Monitor CloudWatch costs** with AWS Cost Explorer
2. **Set budgets** for monitoring spend
3. **Review log retention** policies regularly
4. **Archive old logs** to S3
5. **Use metric filters** instead of storing all logs
6. **Disable unused** dashboards and alarms

## Security Considerations

### Log Encryption

- All log groups encrypted with KMS by default
- Separate KMS key for log encryption
- Automatic key rotation enabled (90 days)
- CloudWatch Logs service principal has KMS permissions

### SNS Encryption

- SNS topics encrypted with KMS (optional)
- Message encryption in transit (TLS)
- Topic access policies restrict publishers

### Lambda Security

- Minimal IAM permissions (least privilege)
- Secrets stored in environment variables
- VPC deployment for sensitive integrations
- CloudWatch Logs for Lambda audit trail

### S3 Bucket Security

- Block all public access enabled
- Bucket encryption enabled (KMS or SSE-S3)
- Versioning enabled for log preservation
- Bucket policy restricts CloudWatch Logs only

## Monitoring the Monitors

### CloudWatch Alarms for Monitoring Infrastructure

1. **Lambda Function Errors**
   - Alert on: Lambda invocation errors > 5
   - Action: Critical notification

2. **Kinesis Stream Throttling**
   - Alert on: WriteProvisionedThroughputExceeded > 0
   - Action: Warning notification

3. **S3 Export Failures**
   - Alert on: Export task failures
   - Action: Critical notification

4. **DynamoDB Throttling**
   - Alert on: Read/Write capacity exceeded
   - Action: Warning notification

### Health Checks

Run regular health checks:
```bash
# Check Lambda function health
aws lambda get-function --function-name {function-name}

# Check Kinesis stream status
aws kinesis describe-stream --stream-name {stream-name}

# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic --topic-arn {topic-arn}

# Verify log groups exist
aws logs describe-log-groups --log-group-name-prefix "/aws/{project}"
```

## Version History

### v1.5.0 (2024-01-16)
- Initial release of Enhanced Monitoring & Observability
- CloudWatch dashboards (4 specialized dashboards)
- Centralized logging with S3 export and Kinesis streaming
- Advanced alerting with Slack, PagerDuty, and SMS
- Alert aggregation and escalation workflows
- Comprehensive documentation

## Support

For issues, questions, or contributions:
- **GitHub:** https://github.com/Botbynetz/Cloud-Infrastructure-Automation
- **Documentation:** https://botbynetz.github.io
- **Email:** support@example.com

## References

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [PagerDuty Events API](https://developer.pagerduty.com/docs/events-api-v2/overview/)
