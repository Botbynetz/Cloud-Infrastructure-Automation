# Disaster Recovery & Business Continuity Module

## Overview

This Terraform module implements enterprise-grade disaster recovery capabilities for AWS infrastructure, ensuring business continuity with automated failover, cross-region replication, and comprehensive backup strategies.

## Features

### 🔄 **Multi-Region Replication**
- **S3 Cross-Region Replication**: Automated replication of backups to secondary region with 15-minute SLA
- **RDS Snapshot Copy**: Daily automated copy of RDS snapshots to DR region
- **DynamoDB Global Tables**: Multi-region active-active replication
- **EBS Volume Snapshots**: Automated snapshot lifecycle management

### 📦 **Backup Strategy**
- **Multi-tier Retention**: 7/30/90/365 days lifecycle policies
- **Automated Scheduling**: Daily, weekly, and monthly backup jobs
- **Point-in-Time Recovery**: 35-day PITR for supported resources
- **Cross-Account Backups**: Optional backup to separate AWS account
- **Encryption**: All backups encrypted with KMS

### ⚡ **Automated Failover**
- **Route53 Health Checks**: Continuous health monitoring (30s intervals)
- **DNS Failover**: Automatic DNS failover to secondary region
- **Systems Manager Automation**: Pre-built runbooks for failover procedures
- **Health Check Configuration**: HTTP/HTTPS/TCP health checks with customizable thresholds

### 📊 **RTO/RPO Compliance**
- **RTO**: Recovery Time Objective monitoring (default: 1 hour)
- **RPO**: Recovery Point Objective tracking (default: 15 minutes)
- **Compliance Alarms**: CloudWatch alarms for RTO/RPO breaches
- **Performance Metrics**: Real-time replication lag monitoring

### 🧪 **DR Testing Automation**
- **Automated Testing**: Monthly DR test execution
- **Validation Procedures**: Automated backup integrity checks
- **Test Reports**: Automated DR test report generation
- **Non-Production Testing**: Isolated DR testing environment

### 📈 **Monitoring & Alerting**
- **CloudWatch Dashboard**: Dedicated DR monitoring dashboard
- **SNS Notifications**: Email/SMS alerts for DR events
- **Replication Lag Alarms**: Alert on excessive replication delays
- **Backup Failure Alarms**: Immediate notification of backup failures

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Primary Region (us-east-1)                │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │  Application │   │     RDS      │   │   S3 Backup  │        │
│  │    Servers   │   │   Database   │   │    Bucket    │        │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘        │
│         │                  │                  │                 │
│         │                  │                  │ Replication     │
│         ▼                  ▼                  ▼ (15 min SLA)    │
│  ┌──────────────────────────────────────────────────┐           │
│  │     Route53 Health Check (30s interval)         │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────┬───────────────────────────────────────┘
                          │ Failover
                          │ (Automatic on failure)
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Secondary Region (us-west-2)                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │  Standby     │   │  RDS Snapshot│   │  S3 Replica  │        │
│  │  Servers     │   │   Replica    │   │    Bucket    │        │
│  └──────────────┘   └──────────────┘   └──────────────┘        │
│                                                                  │
│  ┌───────────────────────────────────────────────────┐          │
│  │         DynamoDB Global Table (Active-Active)     │          │
│  └───────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  providers = {
    aws.primary   = aws.us-east-1
    aws.secondary = aws.us-west-2
  }
  
  project_name = "my-project"
  environment  = "production"
  
  # Backup configuration
  backup_retention_days   = 2555  # 7 years
  snapshot_retention_days = 35
  
  # Enable DR features
  enable_rds_dr           = true
  enable_route53_failover = true
  
  # Notification emails
  dr_notification_emails = [
    "oncall@example.com",
    "devops-team@example.com"
  ]
  
  tags = {
    Terraform   = "true"
    Environment = "production"
    Purpose     = "disaster-recovery"
  }
}
```

### Advanced Configuration with Custom RTO/RPO

```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  providers = {
    aws.primary   = aws.us-east-1
    aws.secondary = aws.eu-west-1
  }
  
  project_name = "enterprise-app"
  environment  = "production"
  
  # RTO/RPO Configuration
  rto_threshold_seconds      = 1800  # 30 minutes
  rpo_threshold_seconds      = 300   # 5 minutes
  replication_lag_threshold  = 600   # 10 minutes
  
  # Backup retention
  backup_retention_days      = 2555  # 7 years (compliance)
  snapshot_retention_days    = 90
  
  # Enable all features
  enable_rds_dr                 = true
  enable_route53_failover       = true
  enable_automated_dr_testing   = true
  enable_point_in_time_recovery = true
  enable_backup_vault           = true
  
  # Health check configuration
  primary_endpoint                = "api.example.com"
  secondary_endpoint              = "dr.example.com"
  health_check_type               = "HTTPS"
  health_check_path               = "/health"
  health_check_port               = 443
  health_check_interval           = 30
  health_check_failure_threshold  = 3
  
  # Encryption
  kms_key_id     = aws_kms_key.backup.id
  sns_kms_key_id = aws_kms_key.sns.id
  
  # Alerting
  alarm_actions = [
    aws_sns_topic.critical_alerts.arn
  ]
  
  dr_notification_emails = [
    "oncall@example.com",
    "sre-team@example.com",
    "cto@example.com"
  ]
  
  # Custom backup rules
  backup_rules = [
    {
      name              = "hourly-backup"
      schedule          = "cron(0 * * * ? *)"
      start_window      = 60
      completion_window = 120
      lifecycle = {
        cold_storage_after = 7
        delete_after       = 30
      }
    },
    {
      name              = "daily-backup"
      schedule          = "cron(0 2 * * ? *)"
      start_window      = 60
      completion_window = 180
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
    },
    {
      name              = "monthly-backup"
      schedule          = "cron(0 3 1 * ? *)"
      start_window      = 120
      completion_window = 300
      lifecycle = {
        cold_storage_after = 90
        delete_after       = 2555
      }
    }
  ]
  
  # DR testing schedule (monthly)
  dr_test_schedule = "cron(0 4 1 * ? *)"
  
  tags = {
    Terraform   = "true"
    Environment = "production"
    Compliance  = "SOC2-HIPAA"
    CriticalInfra = "true"
  }
}
```

### Cross-Account Backup Configuration

```hcl
module "disaster_recovery" {
  source = "./modules/disaster-recovery"
  
  providers = {
    aws.primary   = aws.prod-account
    aws.secondary = aws.dr-account
  }
  
  project_name = "secure-app"
  environment  = "production"
  
  # Cross-account backup
  enable_cross_account_backup = true
  backup_account_id           = "123456789012"
  
  # Standard DR configuration
  enable_rds_dr           = true
  enable_route53_failover = true
  
  backup_retention_days   = 2555
  
  tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version | Alias |
|------|---------|-------|
| aws | ~> 5.0 | primary |
| aws | ~> 5.0 | secondary |

## Resources Created

### S3 Buckets
- Primary backup bucket with versioning & encryption
- Secondary backup bucket (DR region)
- Cross-region replication configuration
- Lifecycle policies for cost optimization

### Lambda Functions
- RDS snapshot copy automation
- Backup validation
- DR testing automation

### CloudWatch
- DR monitoring dashboard
- Replication lag alarms
- Backup failure alarms
- RTO/RPO breach alarms

### DynamoDB
- Global table for DR state tracking
- Point-in-time recovery enabled
- Multi-region replication

### Route53
- Health checks for primary region
- Health checks for secondary region
- Automatic DNS failover configuration

### Systems Manager
- Failover automation document
- DR testing procedure document
- Backup validation runbook

### SNS
- DR notification topic
- Email subscriptions for alerts
- Encrypted with KMS

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | yes |
| environment | Environment (dev/staging/prod) | string | - | yes |
| backup_retention_days | Backup retention period | number | 2555 | no |
| snapshot_retention_days | RDS snapshot retention | number | 35 | no |
| enable_rds_dr | Enable RDS DR automation | bool | true | no |
| enable_route53_failover | Enable Route53 failover | bool | true | no |
| rto_threshold_seconds | RTO threshold | number | 3600 | no |
| rpo_threshold_seconds | RPO threshold | number | 900 | no |
| dr_notification_emails | Email addresses for DR alerts | list(string) | [] | no |
| health_check_interval | Health check interval (10 or 30) | number | 30 | no |
| primary_endpoint | Primary region endpoint | string | "" | no |
| secondary_endpoint | Secondary region endpoint | string | "" | no |

See [variables.tf](./variables.tf) for complete list of inputs.

## Outputs

| Name | Description |
|------|-------------|
| backup_bucket_primary_arn | Primary backup bucket ARN |
| backup_bucket_secondary_arn | Secondary backup bucket ARN |
| dr_notifications_topic_arn | DR notifications SNS topic ARN |
| failover_procedure_name | Failover automation document name |
| dr_dashboard_name | CloudWatch dashboard name |
| dr_configuration | DR configuration summary |

See [outputs.tf](./outputs.tf) for complete list of outputs.

## Best Practices

### 1. **Regular DR Testing**
```bash
# Execute DR test (non-destructive)
aws ssm start-automation-execution \
  --document-name "${PROJECT_NAME}-${ENVIRONMENT}-dr-test" \
  --region us-east-1
```

### 2. **Monitor Replication Lag**
- Set alerts for replication lag > 15 minutes
- Investigate if lag consistently exceeds threshold
- Consider increasing bandwidth or reducing backup frequency

### 3. **Validate Backups**
```bash
# Validate latest RDS snapshot
aws rds describe-db-snapshots \
  --db-instance-identifier your-db \
  --snapshot-type automated \
  --query 'DBSnapshots[0]' \
  --region us-west-2
```

### 4. **Review DR Metrics**
```bash
# View DR dashboard
aws cloudwatch get-dashboard \
  --dashboard-name "${PROJECT_NAME}-${ENVIRONMENT}-dr-monitoring"
```

### 5. **Quarterly DR Drills**
- Schedule quarterly failover tests
- Document lessons learned
- Update runbooks based on findings
- Train team on DR procedures

## RTO/RPO Guidelines

### RTO (Recovery Time Objective)

| Tier | RTO | Configuration |
|------|-----|---------------|
| **Critical** | < 1 hour | Active-Active, Route53 failover |
| **High** | 1-4 hours | Warm standby, automated failover |
| **Medium** | 4-24 hours | Cold standby, manual failover |
| **Low** | 24-72 hours | Backup restore only |

### RPO (Recovery Point Objective)

| Tier | RPO | Backup Frequency |
|------|-----|------------------|
| **Critical** | < 15 min | Continuous replication |
| **High** | 15 min - 1 hour | Hourly snapshots |
| **Medium** | 1-24 hours | Daily backups |
| **Low** | 24-168 hours | Weekly backups |

## Cost Estimation

### Monthly Costs (Production Environment)

| Resource | Estimated Cost |
|----------|----------------|
| S3 Cross-Region Replication | $50-150 |
| S3 Storage (Tiered) | $100-300 |
| Lambda Executions | $5-20 |
| RDS Snapshot Storage | $50-200 |
| DynamoDB Global Table | $30-100 |
| Route53 Health Checks | $1 per check |
| CloudWatch Alarms | $10-30 |
| Data Transfer | $50-200 |
| **Total** | **$300-1,000/month** |

### Cost Optimization Tips
1. Use S3 Lifecycle policies to transition to cheaper storage
2. Delete old snapshots beyond retention period
3. Use S3 Intelligent-Tiering for unpredictable access patterns
4. Monitor and optimize data transfer costs

## Compliance & Standards

This module helps achieve compliance with:

- ✅ **SOC 2 Type II**: Backup & recovery controls
- ✅ **HIPAA**: 7-year retention, encryption at rest
- ✅ **PCI-DSS**: Backup integrity, monitoring
- ✅ **ISO 27001**: Business continuity planning
- ✅ **NIST 800-53**: CP-9 (System Backup), CP-10 (System Recovery)

## Troubleshooting

### Replication Lag High
```bash
# Check replication metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name ReplicationLatency \
  --dimensions Name=SourceBucket,Value=your-bucket \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Snapshot Copy Failed
```bash
# Check Lambda logs
aws logs tail /aws/lambda/${PROJECT_NAME}-${ENVIRONMENT}-rds-snapshot-copy \
  --follow \
  --format short
```

### Health Check Failing
```bash
# Get health check status
aws route53 get-health-check-status \
  --health-check-id your-health-check-id
```

## Examples

See [examples/](../../examples/disaster-recovery/) directory for complete implementation examples:

- `basic/` - Basic DR setup
- `advanced/` - Full enterprise DR with all features
- `cross-account/` - Cross-account backup configuration
- `multi-region/` - Multi-region active-active setup

## License

This module is part of the Cloud Infrastructure Automation project.

## Support

For issues or questions:
- GitHub: https://github.com/Botbynetz/Cloud-Infrastructure-Automation
- Documentation: See [DR_GUIDE.md](../../../docs/DR_GUIDE.md)
