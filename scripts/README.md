# Cost Optimization Tools

PowerShell scripts for calculating, monitoring, and optimizing cloud costs across AWS, Azure, and GCP.

## Scripts

### 1. cost-calculator.ps1

Calculate and compare estimated costs across cloud providers.

#### Usage

```powershell
# Compare all providers for production environment
.\cost-calculator.ps1 -Provider all -Environment production

# Calculate AWS costs for dev environment
.\cost-calculator.ps1 -Provider aws -Environment dev

# Get detailed breakdown
.\cost-calculator.ps1 -Provider azure -Environment staging -OutputFormat detailed

# Export to JSON
.\cost-calculator.ps1 -Provider all -Environment production -OutputFormat json

# Export to CSV
.\cost-calculator.ps1 -Provider all -Environment production -OutputFormat csv
```

#### Parameters

- `-Provider`: Target cloud provider (`aws`, `azure`, `gcp`, `all`)
- `-Environment`: Environment profile (`dev`, `staging`, `production`)
- `-OutputFormat`: Output format (`table`, `detailed`, `json`, `csv`, `all`)

#### Environment Profiles

**Dev:**
- 1x micro instance
- 10GB storage
- No database
- No load balancer

**Staging:**
- 2x small instances
- 100GB storage
- Small database
- Load balancer
- 100GB data transfer

**Production:**
- 3x medium instances
- 1TB storage
- Medium database
- Load balancer
- 500GB data transfer

#### Example Output

```
╔══════════════════════════════════════════════════════════════╗
║       Multi-Cloud Cost Comparison - production Environment   ║
╚══════════════════════════════════════════════════════════════╝

Provider Monthly Cost Annual Cost  Compute Storage Database
-------- ------------ -----------  ------- ------- --------
AWS      $183.36      $2,200.32   $91.11  $23.00  $99.28
AZURE    $192.28      $2,307.36   $89.79  $18.40  $116.80
GCP      $149.89      $1,798.68   $72.81  $20.00  $75.08

💰 Cost Savings:
   Cheapest: GCP at $149.89/month
   Potential savings: $42.39/month (22.0%) vs most expensive
   Annual savings: $508.68
```

---

### 2. cost-monitoring.ps1

Real-time cost monitoring dashboard with budget alerts.

#### Usage

```powershell
# Monitor costs with $100 budget
.\cost-monitoring.ps1 -BudgetThreshold 100

# Monitor with custom budget and alert email
.\cost-monitoring.ps1 -BudgetThreshold 500 -AlertEmail "billing@company.com"

# Generate cost report
.\cost-monitoring.ps1 -BudgetThreshold 100 -GenerateReport
```

#### Parameters

- `-BudgetThreshold`: Monthly budget limit in USD (default: 100)
- `-AlertEmail`: Email for cost alerts (default: "admin@example.com")
- `-GenerateReport`: Export detailed JSON report

#### Prerequisites

**AWS:**
```powershell
# Install AWS CLI
choco install awscli

# Configure credentials
aws configure
```

**Azure:**
```powershell
# Install Azure CLI
choco install azure-cli

# Login
az login
```

**GCP:**
```powershell
# Install gcloud
# Download from: https://cloud.google.com/sdk/docs/install

# Configure BigQuery billing export
# https://cloud.google.com/billing/docs/how-to/export-data-bigquery

# Login
gcloud auth login
```

#### Example Output

```
💰 Multi-Cloud Cost Monitoring Dashboard

╔══════════════════════════════════════════════════════════════╗
║            Multi-Cloud Cost Monitoring Dashboard            ║
╚══════════════════════════════════════════════════════════════╝

Budget Overview:
  Total Budget:  $500
  Total Spend:   $423.53
  Remaining:     $76.47
  Usage:         84.7%

  [████████████████████████████████████████████░░░░░░░░░] 84.7%

Provider Breakdown:
  AWS        :  $183.36  ( 43.3%)
    └─ EC2                        :  $91.11
    └─ RDS                        :  $49.64
    └─ ELB                        :  $16.20
  AZURE      :  $192.28  ( 45.4%)
    └─ Virtual Machines           :  $89.79
    └─ SQL Database               :  $58.40
    └─ Load Balancer              :  $18.25
  GCP        :   $47.89  ( 11.3%)
    └─ Compute Engine             :  $24.27
    └─ Cloud Storage              :  $20.00

⚠️ WARNING ALERT: AWS
Cloud Provider: AWS
Current Spend: $183.36
Budget: $500
Usage: 36.7%

Status: Budget usage high
```

#### Alert Levels

- **WARNING** (80%): Yellow alert, monitor closely
- **CRITICAL** (90%): Red alert, take action
- **EMERGENCY** (100%): Budget exceeded

---

## Cost Optimization Strategies

### 1. Right-Sizing Instances

```powershell
# Analyze actual usage and downsize
.\cost-calculator.ps1 -Environment dev

# Compare costs before/after
.\cost-calculator.ps1 -Provider aws -Environment production
.\cost-calculator.ps1 -Provider aws -Environment staging
```

**Potential Savings:** 30-50%

### 2. Reserved Instances / Committed Use

Purchase commitments for predictable workloads:

- **AWS Reserved Instances:** 30-72% discount
- **Azure Reserved VM Instances:** 40-72% discount
- **GCP Committed Use Discounts:** 37-70% discount

### 3. Auto-Scaling

Enable auto-scaling to match demand:

```hcl
ha_config = {
  enable_auto_scaling = true
  min_instances       = 1
  max_instances       = 5
}
```

**Potential Savings:** 20-40% during off-peak

### 4. Storage Lifecycle Policies

Automatically move data to cheaper storage tiers:

```hcl
# AWS S3 Lifecycle
# 30 days: Standard → Infrequent Access (50% savings)
# 90 days: IA → Glacier (80% savings)
# 365 days: Glacier → Deep Archive (95% savings)
```

### 5. Spot/Preemptible Instances

Use for non-critical workloads:

- **AWS Spot:** 70-90% discount
- **Azure Spot:** 60-90% discount
- **GCP Preemptible:** 60-91% discount

### 6. Multi-Cloud Cost Arbitrage

Deploy workloads to cheapest provider:

```powershell
# Compare providers
.\cost-calculator.ps1 -Provider all -Environment production

# Deploy to most cost-effective
terraform apply -var="cloud_provider=gcp"
```

---

## Cost Monitoring Best Practices

### 1. Set Up Budget Alerts

Configure in each cloud console:

**AWS:**
```bash
aws budgets create-budget \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

**Azure:**
```bash
az consumption budget create \
  --budget-name monthly-budget \
  --amount 500 \
  --time-grain Monthly
```

**GCP:**
```bash
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Monthly Budget" \
  --budget-amount=500
```

### 2. Enable Cost Allocation Tags

Tag all resources for cost tracking:

```hcl
common_tags = {
  Project     = "cloud-infra"
  Environment = "production"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

### 3. Regular Cost Reviews

Schedule weekly/monthly reviews:

```powershell
# Weekly check
.\cost-monitoring.ps1 -BudgetThreshold 500 -GenerateReport

# Monthly analysis
.\cost-calculator.ps1 -Provider all -Environment production -OutputFormat detailed
```

### 4. Implement Resource Cleanup

Delete unused resources:

```powershell
# Find unused resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped"
az vm list --query "[?powerState=='VM deallocated']"
gcloud compute instances list --filter="status=TERMINATED"
```

### 5. Use Cost Anomaly Detection

Enable in cloud consoles:

- **AWS Cost Anomaly Detection**
- **Azure Cost Management Anomaly Detection**
- **GCP Recommender**

---

## Automation

### Scheduled Monitoring

**Windows Task Scheduler:**

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\scripts\cost-monitoring.ps1 -BudgetThreshold 500 -GenerateReport"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName "Cloud Cost Monitoring" -Action $action -Trigger $trigger
```

**Linux Cron:**

```bash
# Daily at 9am
0 9 * * * /usr/bin/pwsh /opt/scripts/cost-monitoring.ps1 -BudgetThreshold 500
```

### Integration with CI/CD

Add to GitHub Actions:

```yaml
name: Cost Monitoring

on:
  schedule:
    - cron: '0 9 * * *'  # Daily at 9am UTC

jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Cost Monitoring
        run: |
          pwsh scripts/cost-monitoring.ps1 \
            -BudgetThreshold 500 \
            -GenerateReport
      
      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: cost-report
          path: cost-monitoring-report-*.json
```

---

## Troubleshooting

### Issue: "AWS CLI not found"

```powershell
# Install AWS CLI
choco install awscli -y

# Or download from
https://aws.amazon.com/cli/
```

### Issue: "Not logged in to Azure"

```powershell
# Login to Azure
az login

# Select subscription
az account set --subscription "Your Subscription"
```

### Issue: "No GCP project selected"

```powershell
# List projects
gcloud projects list

# Set project
gcloud config set project PROJECT_ID
```

### Issue: "Permission denied"

Ensure proper IAM roles:

- **AWS:** Cost Explorer access
- **Azure:** Reader role on subscription
- **GCP:** Billing Account Viewer

---

## Additional Resources

### Cost Management Tools

- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [Azure Cost Management](https://azure.microsoft.com/en-us/services/cost-management/)
- [GCP Cloud Billing](https://cloud.google.com/billing/docs)

### Third-Party Tools

- [CloudHealth](https://www.cloudhealthtech.com/)
- [Cloudability](https://www.cloudability.com/)
- [Infracost](https://www.infracost.io/)

### Calculators

- [AWS Pricing Calculator](https://calculator.aws/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)

---

## Support

For issues or feature requests, open an issue on GitHub:
https://github.com/Botbynetz/Cloud-Infrastructure-Automation/issues
