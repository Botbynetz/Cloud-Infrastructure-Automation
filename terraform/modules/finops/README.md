# FinOps & Advanced Cost Management Module 💰

Enterprise-grade cost optimization and financial operations for AWS infrastructure with ML-powered anomaly detection.

## Overview

This module implements comprehensive FinOps practices to optimize AWS costs, detect anomalies, eliminate waste, and provide actionable insights for cost management.

### Key Features

✅ **Cost and Usage Tracking**
- AWS Cost and Usage Reports (CUR) with Parquet format
- Hourly granularity for detailed analysis
- 7-year retention for compliance
- Athena integration for SQL queries

✅ **ML-Powered Anomaly Detection**
- Service-level cost monitoring
- Multi-account cost tracking (optional)
- Configurable alert thresholds
- Daily or immediate notifications

✅ **Automated Rightsizing**
- EC2 instance utilization analysis (14-day lookback)
- Over/under-utilized instance detection
- Cost Explorer rightsizing recommendations
- Weekly automated analysis

✅ **Waste Elimination**
- Unattached EBS volumes detection
- Unused Elastic IPs identification
- Old snapshots (>1 year) cleanup
- Idle RDS instances detection
- Unused load balancers tracking

✅ **Budget Management**
- Monthly budget limits with multi-threshold alerts (80%, 90%, 100%)
- Forecasted cost tracking
- Email notifications via SNS

✅ **Savings Opportunities**
- Reserved Instance recommendations
- Savings Plans recommendations
- Automated optimization suggestions

## Usage

### Basic Configuration

\`\`\`hcl
module "finops" {
  source = "./modules/finops"
  
  project_name = "cloud-infra"
  environment  = "production"
  aws_region   = "us-east-1"
  
  # Notification emails
  finops_notification_emails = [
    "finops-team@example.com",
    "cloud-admin@example.com"
  ]
  
  # Budget configuration
  monthly_budget_limit = 10000  # USD
  
  # Anomaly detection
  anomaly_threshold_amount     = 100   # USD
  anomaly_alert_frequency      = "DAILY"
  
  tags = {
    CostCenter = "Engineering"
    Owner      = "FinOps Team"
  }
}
\`\`\`

### Advanced Configuration with Auto-Optimization

\`\`\`hcl
module "finops" {
  source = "./modules/finops"
  
  project_name = "cloud-infra"
  environment  = "production"
  
  # Multi-account tracking
  enable_multi_account_tracking = true
  
  # Cost data retention
  cost_data_retention_days = 2555  # 7 years
  
  # Anomaly detection
  anomaly_threshold_amount      = 200
  anomaly_threshold_percentage  = 20    # 20% change threshold
  anomaly_alert_frequency       = "IMMEDIATE"
  
  # Rightsizing configuration
  rightsizing_cpu_threshold_low  = 20   # Under-utilized below 20%
  rightsizing_cpu_threshold_high = 80   # Over-utilized above 80%
  auto_apply_rightsizing         = false
  rightsizing_dry_run            = true
  
  # Waste elimination
  waste_threshold_usd       = 5
  unused_resource_days      = 30
  auto_delete_waste         = false  # CAUTION: Set to true to auto-delete
  waste_cleanup_dry_run     = true
  
  # Budget
  monthly_budget_limit = 15000
  
  # Notifications
  finops_notification_emails = [
    "finops-team@example.com"
  ]
  
  tags = {
    Environment = "production"
    CostCenter  = "Engineering"
    Compliance  = "FinOps-Framework"
  }
}
\`\`\`

## Architecture

\`\`\`
┌─────────────────────────────────────────────────────────────────┐
│                     FinOps Architecture                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐      ┌─────────────────┐                    │
│  │ AWS Services │─────▶│ Cost & Usage    │                    │
│  │ (EC2, RDS,   │      │ Reports (CUR)   │                    │
│  │  S3, etc.)   │      │ Parquet Format  │                    │
│  └──────────────┘      └────────┬────────┘                    │
│                                  │                              │
│                                  ▼                              │
│                        ┌──────────────────┐                    │
│                        │   S3 Bucket      │                    │
│                        │  (Cost Reports)  │                    │
│                        └────────┬─────────┘                    │
│                                  │                              │
│                    ┌─────────────┼─────────────┐              │
│                    │             │             │              │
│                    ▼             ▼             ▼              │
│          ┌──────────────┐ ┌────────────┐ ┌─────────────┐    │
│          │ Cost Analyzer│ │  Athena    │ │   Glue      │    │
│          │   Lambda     │ │  Queries   │ │  Catalog    │    │
│          │  (Daily)     │ │            │ │             │    │
│          └──────┬───────┘ └────────────┘ └─────────────┘    │
│                 │                                             │
│      ┌──────────┼──────────────────────────┐                │
│      │          │                           │                │
│      ▼          ▼                           ▼                │
│ ┌─────────┐ ┌──────────────┐    ┌─────────────────┐        │
│ │ Anomaly │ │  Rightsizing │    │ Waste Detection │        │
│ │Detection│ │    Advisor   │    │     Lambda      │        │
│ │         │ │   (Weekly)   │    │    (Daily)      │        │
│ └────┬────┘ └──────┬───────┘    └────────┬────────┘        │
│      │             │                      │                  │
│      └─────────────┼──────────────────────┘                  │
│                    │                                          │
│                    ▼                                          │
│          ┌──────────────────┐                                │
│          │   SNS Topic      │                                │
│          │  (Notifications) │                                │
│          └────────┬─────────┘                                │
│                   │                                           │
│                   ▼                                           │
│          ┌──────────────────┐                                │
│          │  Email Alerts    │                                │
│          │  (FinOps Team)   │                                │
│          └──────────────────┘                                │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         CloudWatch Dashboard                         │   │
│  │  - Cost Metrics    - Anomalies                       │   │
│  │  - Savings Opportunities    - Waste Resources        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
\`\`\`

## Automation Schedule

| Function | Schedule | Purpose |
|----------|----------|---------|
| **Cost Analyzer** | Daily at 8 AM UTC | Comprehensive cost analysis, anomaly detection |
| **Rightsizing Advisor** | Weekly on Monday 7 AM UTC | EC2 instance optimization recommendations |
| **Waste Elimination** | Daily at 6 AM UTC | Detect and optionally clean up unused resources |

## Cost Savings Potential

| Optimization Area | Typical Savings | Implementation |
|------------------|-----------------|----------------|
| **Rightsizing** | 10-25% on EC2 | Automated recommendations |
| **Waste Elimination** | 5-15% overall | Automated detection + cleanup |
| **Reserved Instances** | 30-60% on committed usage | Purchase recommendations |
| **Savings Plans** | 20-40% on compute | Flexible commitment recommendations |
| **Storage Optimization** | 10-30% on storage | Lifecycle policies, tiering |
| **TOTAL POTENTIAL** | **15-30% overall cost reduction** | Combined approach |

## Monthly Cost Estimate

| Component | Cost Range | Notes |
|-----------|------------|-------|
| S3 Storage (CUR) | $10-30 | Depends on data volume |
| Lambda Executions | $5-15 | 3 functions, daily/weekly runs |
| Glue Data Catalog | $1-5 | Table storage |
| CloudWatch Logs | $2-8 | 30-day retention |
| SNS Notifications | $1-2 | Email subscriptions |
| **Total** | **$19-60/month** | Actual varies by usage |

**ROI**: Typical 15-30% cost reduction means module pays for itself many times over.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name for resource naming | `string` | - | yes |
| `environment` | Environment name (dev, staging, production) | `string` | - | yes |
| `aws_region` | AWS region for FinOps resources | `string` | `"us-east-1"` | no |
| `finops_notification_emails` | Email addresses for FinOps alerts | `list(string)` | `[]` | yes |
| `monthly_budget_limit` | Monthly budget limit in USD (0 to disable) | `number` | `5000` | no |
| `anomaly_threshold_amount` | Min cost impact (USD) to trigger alert | `number` | `100` | no |
| `rightsizing_cpu_threshold_low` | CPU % for under-utilization | `number` | `20` | no |
| `rightsizing_cpu_threshold_high` | CPU % for over-utilization | `number` | `80` | no |
| `auto_apply_rightsizing` | Auto-apply recommendations (CAUTION) | `bool` | `false` | no |
| `waste_threshold_usd` | Min monthly cost to consider as waste | `number` | `5` | no |
| `auto_delete_waste` | Auto-delete waste resources (CAUTION) | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cost_reports_bucket_id` | S3 bucket ID for Cost and Usage Reports |
| `cost_analyzer_lambda_arn` | ARN of cost analyzer Lambda function |
| `rightsizing_advisor_lambda_arn` | ARN of rightsizing advisor Lambda |
| `waste_elimination_lambda_arn` | ARN of waste elimination Lambda |
| `finops_alerts_topic_arn` | SNS topic ARN for FinOps alerts |
| `finops_dashboard_name` | CloudWatch dashboard name |
| `finops_summary` | Comprehensive configuration summary |

## Security Best Practices

1. **Least Privilege IAM**: Lambda functions have minimal required permissions
2. **Encryption**: All data encrypted at rest (KMS) and in transit
3. **Audit Trail**: All actions logged to CloudWatch with 30-day retention
4. **SNS Encryption**: Notifications encrypted with KMS
5. **Dry Run Mode**: Test changes before applying (default: enabled)

## Compliance

| Framework | Controls Met |
|-----------|--------------|
| **FinOps Framework** | Cost visibility, optimization, operational excellence |
| **AWS Well-Architected** | Cost Optimization pillar |
| **SOC 2** | Financial monitoring and controls |
| **ISO 27001** | Asset management and cost control |

## Troubleshooting

### Cost Analyzer Errors

**Symptom**: Lambda function errors in CloudWatch Logs

**Solution**:
\`\`\`bash
# Check Lambda logs
aws logs tail /aws/lambda/{project}-{env}-cost-analyzer --follow

# Verify IAM permissions
aws iam get-role-policy --role-name {project}-{env}-cost-analyzer-lambda --policy-name cost-analyzer-policy

# Test Cost Explorer API access
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-01-31 --granularity MONTHLY --metrics UnblendedCost
\`\`\`

### Rightsizing Not Finding Instances

**Symptom**: No recommendations generated

**Solution**:
1. Verify EC2 instances are running: `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"`
2. Check CloudWatch has CPU metrics (requires 14 days of data)
3. Adjust CPU thresholds in module variables

### Waste Detection Missing Resources

**Symptom**: Known waste resources not detected

**Solution**:
1. Check `unused_resource_days` threshold (default: 30 days)
2. Verify resource tags and ownership
3. Review Lambda function logs for API errors

## Manual Invocation

\`\`\`bash
# Invoke cost analyzer manually
aws lambda invoke \\
  --function-name {project}-{env}-cost-analyzer \\
  --payload '{}' \\
  response.json

# Invoke rightsizing advisor
aws lambda invoke \\
  --function-name {project}-{env}-rightsizing-advisor \\
  --payload '{}' \\
  response.json

# Invoke waste elimination
aws lambda invoke \\
  --function-name {project}-{env}-waste-elimination \\
  --payload '{}' \\
  response.json
\`\`\`

## Example: Querying Cost Data with Athena

\`\`\`sql
-- Top 10 services by cost (last 30 days)
SELECT 
  line_item_product_code AS service,
  SUM(line_item_unblended_cost) AS total_cost
FROM {database}.{table}
WHERE line_item_usage_start_date >= DATE_ADD('day', -30, CURRENT_DATE)
GROUP BY line_item_product_code
ORDER BY total_cost DESC
LIMIT 10;

-- Daily cost trend
SELECT 
  DATE(line_item_usage_start_date) AS date,
  SUM(line_item_unblended_cost) AS daily_cost
FROM {database}.{table}
WHERE line_item_usage_start_date >= DATE_ADD('day', -90, CURRENT_DATE)
GROUP BY DATE(line_item_usage_start_date)
ORDER BY date;
\`\`\`

## References

- [AWS Cost Explorer API](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_Operations_AWS_Cost_Explorer_Service.html)
- [AWS Cost and Usage Reports](https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html)
- [FinOps Foundation](https://www.finops.org/)
- [AWS Well-Architected - Cost Optimization](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

---

**Module Version**: 1.8.0  
**Last Updated**: November 2025  
**Maintainer**: Cloud Infrastructure Team
