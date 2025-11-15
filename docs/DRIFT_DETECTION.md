# Infrastructure Drift Detection Guide

Complete guide for detecting and managing infrastructure drift using driftctl, AWS Config, and Terraform state analysis.

## 🎯 Overview

Infrastructure drift occurs when actual cloud resources differ from their declared state in Terraform. This can happen due to:
- Manual changes via AWS Console
- Changes by other teams or tools
- Failed Terraform runs
- External automation scripts

## 🔍 Detection Methods

### 1. Terraform State Refresh

**Built-in Terraform capability**

```bash
# Check for drift
terraform plan -refresh-only

# Update state to match reality
terraform apply -refresh-only
```

**Automation with GitHub Actions:**

```yaml
name: Terraform Drift Detection

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:

jobs:
  drift-detection:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-1
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Detect Drift
        id: drift
        run: |
          terraform plan -detailed-exitcode -no-color > plan_output.txt
          echo "exit_code=$?" >> $GITHUB_OUTPUT
        working-directory: ./terraform
        continue-on-error: true
      
      - name: Report Drift
        if: steps.drift.outputs.exit_code == '2'
        run: |
          echo "⚠️ Infrastructure drift detected!" >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
          cat terraform/plan_output.txt >> $GITHUB_STEP_SUMMARY
          echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
      
      - name: No Drift
        if: steps.drift.outputs.exit_code == '0'
        run: echo "✅ No infrastructure drift detected" >> $GITHUB_STEP_SUMMARY
```

### 2. driftctl - Comprehensive Drift Detection

**What is driftctl?**

driftctl is a free, open-source CLI tool that:
- Compares Terraform state with actual AWS resources
- Detects unmanaged resources (not in Terraform)
- Provides detailed drift reports
- Supports multiple cloud providers

**Installation:**

```bash
# Linux/macOS
curl -L https://github.com/snyk/driftctl/releases/latest/download/driftctl_linux_amd64 -o driftctl
chmod +x driftctl
sudo mv driftctl /usr/local/bin/

# Windows (PowerShell)
Invoke-WebRequest -Uri "https://github.com/snyk/driftctl/releases/latest/download/driftctl_windows_amd64.exe" -OutFile "driftctl.exe"

# Via Homebrew
brew install driftctl
```

**Basic Usage:**

```bash
# Scan entire AWS account
driftctl scan

# Scan specific resources
driftctl scan --to "aws_instance.*"

# Output to JSON
driftctl scan --output json://drift-report.json

# Filter by Terraform state
driftctl scan --from tfstate://terraform.tfstate
```

**GitHub Actions Workflow:**

```yaml
name: driftctl Scan

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

permissions:
  contents: read
  issues: write

jobs:
  drift-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install driftctl
        run: |
          curl -L https://github.com/snyk/driftctl/releases/latest/download/driftctl_linux_amd64 -o driftctl
          chmod +x driftctl
          sudo mv driftctl /usr/local/bin/
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-1
      
      - name: Run driftctl scan
        id: scan
        run: |
          driftctl scan \
            --output json://drift-report.json \
            --output console://
        continue-on-error: true
        working-directory: ./terraform
      
      - name: Upload drift report
        uses: actions/upload-artifact@v4
        with:
          name: drift-report
          path: terraform/drift-report.json
          retention-days: 90
      
      - name: Parse drift report
        id: parse
        run: |
          TOTAL=$(jq '.summary.total_resources' terraform/drift-report.json)
          MANAGED=$(jq '.summary.total_managed' terraform/drift-report.json)
          UNMANAGED=$(jq '.summary.total_unmanaged' terraform/drift-report.json)
          DRIFT=$(jq '.summary.total_changed' terraform/drift-report.json)
          
          echo "total=$TOTAL" >> $GITHUB_OUTPUT
          echo "managed=$MANAGED" >> $GITHUB_OUTPUT
          echo "unmanaged=$UNMANAGED" >> $GITHUB_OUTPUT
          echo "drift=$DRIFT" >> $GITHUB_OUTPUT
      
      - name: Generate summary
        run: |
          echo "## 🔍 Drift Detection Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Metric | Count |" >> $GITHUB_STEP_SUMMARY
          echo "|--------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Total Resources | ${{ steps.parse.outputs.total }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Managed by Terraform | ${{ steps.parse.outputs.managed }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Unmanaged Resources | ${{ steps.parse.outputs.unmanaged }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Resources with Drift | ${{ steps.parse.outputs.drift }} |" >> $GITHUB_STEP_SUMMARY
      
      - name: Create issue if drift detected
        if: steps.parse.outputs.drift > 0 || steps.parse.outputs.unmanaged > 0
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '🚨 Infrastructure Drift Detected',
              body: `## Drift Detection Alert
              
              Automated scan detected infrastructure drift:
              
              - **Total Resources**: ${{ steps.parse.outputs.total }}
              - **Managed**: ${{ steps.parse.outputs.managed }}
              - **Unmanaged**: ${{ steps.parse.outputs.unmanaged }}
              - **Drifted**: ${{ steps.parse.outputs.drift }}
              
              📊 [View detailed report in Actions artifacts](${context.payload.repository.html_url}/actions/runs/${context.runId})
              
              ### Recommended Actions
              
              1. Review the drift report
              2. Determine if changes are intentional
              3. Either:
                 - Import unmanaged resources into Terraform
                 - Update Terraform to match desired state
                 - Revert manual changes
              
              ### Commands
              
              \`\`\`bash
              # Import unmanaged resource
              terraform import aws_instance.example i-1234567890abcdef0
              
              # Apply Terraform to fix drift
              terraform apply
              
              # Or update state if manual change is desired
              terraform apply -refresh-only
              \`\`\`
              `,
              labels: ['infrastructure', 'drift-detection', 'automated']
            });
```

### 3. AWS Config - Continuous Compliance

**What is AWS Config?**

AWS Config:
- Continuously monitors and records AWS resource configurations
- Evaluates configurations against compliance rules
- Tracks configuration changes over time
- Provides remediation actions

**Setup with Terraform:**

```hcl
# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "infrastructure-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
    
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "infrastructure-config-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket
  
  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  
  depends_on = [aws_config_delivery_channel.main]
}

# S3 Bucket for Config
resource "aws_s3_bucket" "config" {
  bucket = "my-aws-config-logs"

  tags = {
    Name      = "AWS Config Logs"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for Config
resource "aws_iam_role" "config" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Compliance Rules
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "Environment"
    tag2Key = "ManagedBy"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
```

**Common Compliance Rules:**

```hcl
# EBS encryption check
resource "aws_config_config_rule" "ebs_encryption" {
  name = "ebs-encryption-by-default"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }
}

# RDS encryption check
resource "aws_config_config_rule" "rds_encryption" {
  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}

# S3 public access check
resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# IAM password policy
resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  
  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols            = true
    RequireNumbers            = true
    MinimumPasswordLength     = 14
    PasswordReusePrevention   = 24
    MaxPasswordAge            = 90
  })
}
```

## 📊 Drift Report Analysis

### Understanding Drift Types

**1. Configuration Drift**
- Resource exists but properties changed
- Example: EC2 instance type changed from t3.micro to t3.small

**2. Unmanaged Resources**
- Resources exist in AWS but not in Terraform
- Created manually or by other tools

**3. Missing Resources**
- Resources in Terraform but deleted in AWS
- Usually results in Terraform errors

### Remediation Strategies

**Option 1: Import to Terraform**
```bash
# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0

# Update Terraform code to match
# Then run
terraform plan  # Should show no changes
```

**Option 2: Update Terraform**
```hcl
# Update resource definition to match reality
resource "aws_instance" "web" {
  instance_type = "t3.small"  # Changed from t3.micro
  # ... other attributes
}
```

**Option 3: Revert Manual Changes**
```bash
# Apply Terraform to restore desired state
terraform apply -auto-approve
```

## 🔔 Alerting and Notifications

### Slack Notifications

```yaml
- name: Send Slack notification
  if: steps.parse.outputs.drift > 0
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "🚨 Infrastructure Drift Detected",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Infrastructure Drift Alert*\n\nDrifted Resources: ${{ steps.parse.outputs.drift }}\nUnmanaged Resources: ${{ steps.parse.outputs.unmanaged }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Email Notifications (SNS)

```hcl
resource "aws_sns_topic" "drift_alerts" {
  name = "infrastructure-drift-alerts"
}

resource "aws_sns_topic_subscription" "drift_email" {
  topic_arn = aws_sns_topic.drift_alerts.arn
  protocol  = "email"
  endpoint  = "devops@company.com"
}

# CloudWatch Event Rule for Config compliance changes
resource "aws_cloudwatch_event_rule" "compliance_change" {
  name        = "config-compliance-change"
  description = "Trigger on AWS Config compliance state changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.compliance_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.drift_alerts.arn
}
```

## 📈 Best Practices

### 1. Regular Scanning
- Run drift detection daily
- Increase frequency for production (every 6 hours)
- Immediate scan after deployments

### 2. Team Workflow
```
1. Drift detected → GitHub Issue created
2. Team reviews drift report
3. Decide on remediation approach
4. Apply fixes via Terraform
5. Close issue with documentation
```

### 3. Prevention
- Restrict AWS Console access
- Use SCPs to prevent manual changes
- Enable CloudTrail for audit logging
- Implement branch protection rules

### 4. Documentation
- Document intentional manual changes
- Keep runbook for common drift scenarios
- Track drift trends over time

## 🛠️ Troubleshooting

### False Positives

**Problem**: Resources always show as drifted

**Solution**:
```hcl
# Use lifecycle to ignore certain attributes
resource "aws_instance" "web" {
  instance_type = "t3.micro"
  
  lifecycle {
    ignore_changes = [
      tags["LastModified"],
      user_data  # Ignore if changed by automation
    ]
  }
}
```

### State Lock Issues

**Problem**: Cannot run drift detection due to state lock

**Solution**:
```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>

# Or wait for lock to expire
# Check DynamoDB for lock table
```

## 📚 Additional Resources

- [driftctl Documentation](https://docs.driftctl.com/)
- [AWS Config Rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [Terraform Import](https://www.terraform.io/docs/cli/import/index.html)
- [Infrastructure Drift Best Practices](https://www.hashicorp.com/blog/detecting-and-managing-drift-with-terraform)

---

**Repository**: [Cloud-Infrastructure-Automation](https://github.com/Botbynetz/Cloud-Infrastructure-Automation)
