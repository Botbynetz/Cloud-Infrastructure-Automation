# CI/CD Pipeline Documentation

## Overview

Enterprise-grade CI/CD pipeline for multi-cloud Terraform infrastructure with comprehensive security, policy enforcement, and automated workflows.

## 🚀 Features

### Core Capabilities
- ✅ **Multi-Environment Deployment** (Dev, Staging, Prod, DR)
- ✅ **Policy-as-Code Enforcement** (OPA integration)
- ✅ **Security Scanning** (tfsec, Checkov)
- ✅ **Drift Detection** (Scheduled and on-demand)
- ✅ **Rollback Mechanisms** (State-based recovery)
- ✅ **Cost Control** (Automated policy checks)
- ✅ **Compliance** (GDPR, HIPAA, SOC2, ISO27001, PCI-DSS)
- ✅ **OIDC Authentication** (AWS, GCP, Azure)
- ✅ **Automated Approvals** (Environment-specific gates)

## 📋 Workflows

### 1. Main CI/CD Pipeline
**File:** `.github/workflows/terraform-cicd.yml`

**Triggers:**
- Pull requests to `main` or `develop`
- Push to `main` or `develop`
- Manual workflow dispatch

**Stages:**
```
┌─────────────┐
│  Validate   │ → Format check, validate, security scan
└──────┬──────┘
       │
┌──────▼──────┐
│    Test     │ → Terratest execution
└──────┬──────┘
       │
┌──────▼──────┐
│  Plan (All) │ → Generate plans for all environments
└──────┬──────┘
       │
┌──────▼──────┐
│  Apply Dev  │ → Auto-deploy on push to develop
└──────┬──────┘
       │
┌──────▼──────┐
│Apply Staging│ → Manual approval required
└──────┬──────┘
       │
┌──────▼──────┐
│ Apply Prod  │ → Manual approval + MFA required
└─────────────┘
```

**Environment Variables:**
```yaml
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
```

**Required Secrets:**
- `AWS_ROLE_ARN_DEV`
- `AWS_ROLE_ARN_STAGING`
- `AWS_ROLE_ARN_PROD`
- `TF_STATE_BUCKET_DEV`
- `TF_STATE_BUCKET_STAGING`
- `TF_STATE_BUCKET_PROD`

### 2. Policy Enforcement Pipeline
**File:** `.github/workflows/terraform-policy-check.yml`

**Triggers:**
- Pull requests affecting `terraform/` or `policies/`
- Push to `main`
- Manual workflow dispatch

**Policy Checks:**

#### Security Policies
```rego
# terraform.rego - 15+ rules
- No public S3 buckets
- Encryption enforcement
- Security group restrictions
- HTTPS-only enforcement
- IMDSv2 requirement
- VPC flow logs
- No public RDS
```

#### Cost Policies
```rego
# cost.rego - Instance/storage limits
Dev:      t3.micro/t3.small, 100GB EBS max
Staging:  t3.medium/t3.large, 500GB EBS max
Prod:     t3.xlarge/m5.xlarge, 2TB EBS max
DR:       Same as production
```

#### Compliance Policies
```rego
# compliance.rego - 5 frameworks
- GDPR:    Data encryption, EU regions, 30-day retention
- HIPAA:   PHI encryption, audit logs, access control
- SOC2:    Change tracking, backups, monitoring
- ISO27001: Network segregation, 90-day logs
- PCI-DSS: Payment data encryption, secure storage
```

**Job Matrix:**
```yaml
environment: [dev, staging, prod, dr]
framework: [gdpr, hipaa, soc2, iso27001, pci_dss]
```

### 3. Drift Detection
**File:** `.github/workflows/terraform-drift-detection.yml`

**Schedule:**
- **Production & DR:** Daily at 2 AM UTC (`0 2 * * *`)
- **Staging & Dev:** Weekly on Mondays at 3 AM UTC (`0 3 * * 1`)

**Process:**
```bash
1. Run terraform plan -detailed-exitcode
2. Check exit code:
   - 0 = No drift ✅
   - 2 = Drift detected ⚠️
3. Create GitHub issue if drift found
4. Upload drift report (90-day retention)
```

**Drift Response:**
```markdown
Issue Created:
- Title: "🚨 Infrastructure Drift Detected - {environment}"
- Labels: drift-detection, {environment}, infrastructure
- Priority: High (prod/dr), Medium (staging/dev)
- Includes: Drift report, remediation steps, prevention tips
```

### 4. Rollback Mechanism
**File:** `.github/workflows/terraform-rollback.yml`

**Trigger:** Manual workflow dispatch only

**Rollback Types:**

#### A. Previous State
Rolls back to the immediately previous state version.
```bash
# Workflow steps:
1. List S3 state versions
2. Get previous version ID
3. Download previous state
4. Push as current state
5. Apply changes
```

#### B. Specific Version
Rolls back to a user-specified state version.
```bash
# Required input:
- state_version: "VersionId from S3"

# Workflow:
1. Download specific state version
2. Push as current state
3. Apply changes
```

#### C. Manual Revert
Git-based code revert (manual instructions provided).
```bash
# Steps:
1. git log --oneline
2. git revert <commit-hash>
3. git push origin main
4. CI/CD auto-deploys
```

**Safety Features:**
- ✅ Confirmation required: Type "ROLLBACK"
- ✅ Pre-rollback state backup (90-day retention)
- ✅ Post-rollback validation
- ✅ GitHub issue tracking
- ✅ Manual approval gates

### 5. Infrastructure Destroy
**File:** `.github/workflows/terraform-destroy.yml`

**Trigger:** Manual workflow dispatch only

**Safety Mechanisms:**

#### Double Confirmation
```yaml
Input 1: Type exact environment name (dev/staging/prod/dr)
Input 2: Type "DESTROY"
Input 3: Provide destruction reason
```

#### Production Protection
```bash
Production/DR destroy:
- 30-second mandatory wait
- Additional approval gate
- Critical priority issue created
```

#### Backup Strategy
```bash
Pre-destroy backups (365-day retention):
1. Terraform state (JSON)
2. All outputs (JSON)
3. Resource list (TXT)
4. Detailed state (JSON)
5. Copy to backup S3 bucket
```

**Workflow Stages:**
```
1. Validate Request     → Double confirmation check
2. Backup State         → Create comprehensive backups
3. Generate Plan        → Show resources to be destroyed
4. Execute Destroy      → Final approval + 10-sec wait
5. Verify Destroy       → Confirm all resources removed
6. Cleanup & Notify     → Update tracking issue
```

## 🔧 Setup & Configuration

### 1. GitHub Repository Settings

#### Enable GitHub Environments
```bash
Settings → Environments → Create:

1. dev
   - No protection rules
   - Auto-deploy on develop branch

2. staging
   - Required reviewers: 1+
   - Allow administrators to bypass

3. production
   - Required reviewers: 2+
   - Deployment branches: main only
   - Wait timer: 5 minutes

4. dr
   - Required reviewers: 2+
   - Same as production

5. {environment}-destroy
   - Required reviewers: 2+ (managers only)
   - Additional safeguards

6. {environment}-destroy-final
   - Required reviewers: 1+ (senior engineers)
```

### 2. AWS OIDC Configuration

#### Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Roles
```hcl
# terraform/modules/github-oidc/main.tf

resource "aws_iam_role" "github_actions" {
  for_each = toset(["dev", "staging", "prod", "dr"])
  
  name = "github-actions-${each.key}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:YourOrg/YourRepo:*"
        }
      }
    }]
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "terraform" {
  for_each = aws_iam_role.github_actions
  
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
```

### 3. Required GitHub Secrets

```bash
# AWS OIDC Role ARNs
AWS_ROLE_ARN_DEV      = arn:aws:iam::ACCOUNT:role/github-actions-dev
AWS_ROLE_ARN_STAGING  = arn:aws:iam::ACCOUNT:role/github-actions-staging
AWS_ROLE_ARN_PROD     = arn:aws:iam::ACCOUNT:role/github-actions-prod
AWS_ROLE_ARN_DR       = arn:aws:iam::ACCOUNT:role/github-actions-dr

# S3 Backend Buckets
TF_STATE_BUCKET_DEV      = terraform-state-dev-bucket
TF_STATE_BUCKET_STAGING  = terraform-state-staging-bucket
TF_STATE_BUCKET_PROD     = terraform-state-prod-bucket
TF_STATE_BUCKET_DR       = terraform-state-dr-bucket

# Backup (Optional)
BACKUP_BUCKET = terraform-backups-bucket

# Notifications (Optional)
SLACK_WEBHOOK_URL = https://hooks.slack.com/...
```

### 4. S3 State Bucket Configuration

```hcl
# Create with versioning enabled
resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(["dev", "staging", "prod", "dr"])
  
  bucket = "terraform-state-${each.key}-bucket"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    enabled = true
    
    noncurrent_version_expiration {
      days = 90
    }
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

## 🔒 Security Best Practices

### 1. Least Privilege IAM Policies
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "rds:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-southeast-1"
        }
      }
    }
  ]
}
```

### 2. Branch Protection Rules
```yaml
main:
  - Require pull request reviews (2+)
  - Require status checks to pass
  - Require branches to be up to date
  - Include administrators
  - Restrict who can push

develop:
  - Require pull request reviews (1+)
  - Require status checks to pass
```

### 3. Secrets Management
```bash
# Never commit secrets
# Use GitHub Secrets for sensitive data
# Use AWS Secrets Manager for runtime secrets
# Rotate secrets regularly (90 days)
```

## 📊 Monitoring & Alerts

### GitHub Actions Status
```bash
# Monitor workflow runs
https://github.com/YourOrg/YourRepo/actions

# Set up status badges
![CI/CD](https://github.com/YourOrg/YourRepo/workflows/Terraform%20CI/CD%20Pipeline/badge.svg)
```

### Drift Detection Alerts
```yaml
# Issues created automatically when drift detected
# Weekly summary emails
# Slack notifications (if configured)
```

### Cost Monitoring
```bash
# Policy violations reported in PR comments
# Monthly cost estimates
# Budget alerts via AWS Budgets
```

## 🚨 Troubleshooting

### Common Issues

#### 1. OIDC Authentication Failed
```bash
Error: Error assuming role

Solution:
1. Verify OIDC provider trust policy
2. Check GitHub repository name in trust policy
3. Ensure role has correct permissions
4. Verify AWS region settings
```

#### 2. State Lock Timeout
```bash
Error: Error locking state

Solution:
1. Check DynamoDB table for locks
2. Force unlock if needed:
   terraform force-unlock <lock-id>
3. Verify DynamoDB permissions
```

#### 3. Policy Violations Blocking PR
```bash
Error: OPA policy violations detected

Solution:
1. Review policy violation details in PR comment
2. Fix Terraform code to comply
3. Request policy exception if needed (update policies)
4. Re-push changes to trigger new checks
```

#### 4. Drift Not Detected
```bash
Issue: Manual changes not showing as drift

Solution:
1. Check drift detection schedule
2. Manually trigger: Actions → Drift Detection → Run workflow
3. Verify AWS credentials
4. Check Terraform state integrity
```

## 📖 Usage Examples

### Example 1: Standard Deployment
```bash
# 1. Create feature branch
git checkout -b feature/add-new-ec2

# 2. Make Terraform changes
vim terraform/main.tf

# 3. Commit and push
git add .
git commit -m "feat: add new EC2 instance"
git push origin feature/add-new-ec2

# 4. Create PR
# → Validation runs automatically
# → Security scans execute
# → Policy checks run
# → Plans generated for all environments

# 5. Review PR comments
# → Check validation results
# → Review security findings
# → Verify policy compliance
# → Review Terraform plans

# 6. Merge PR
# → Auto-deploys to dev
# → Waits for staging approval
# → Waits for prod approval (after staging)
```

### Example 2: Emergency Rollback
```bash
# 1. Go to Actions → Terraform Rollback
# 2. Click "Run workflow"
# 3. Select:
#    - Environment: prod
#    - Type: previous_state
#    - Confirmation: ROLLBACK
# 4. Approve rollback in environment protection
# 5. Monitor workflow execution
# 6. Verify post-rollback state
```

### Example 3: Drift Remediation
```bash
# When drift detected:

# 1. Review drift detection issue
# 2. Check drift report artifact
# 3. Identify source of drift

# Option A: Update Terraform to match reality
vim terraform/main.tf
git commit -m "fix: update Terraform to match current state"
git push

# Option B: Revert manual changes
cd terraform
terraform apply -var-file=environments/prod.tfvars

# 4. Close drift issue after remediation
```

### Example 4: Controlled Destroy
```bash
# 1. Go to Actions → Infrastructure Destroy
# 2. Click "Run workflow"
# 3. Enter:
#    - Environment: dev
#    - Confirmation 1: dev
#    - Confirmation 2: DESTROY
#    - Reason: "Temporary environment no longer needed"
# 4. Approve destroy in environment protection
# 5. Wait for backup creation
# 6. Approve final destroy execution
# 7. Verify complete destruction
```

## 🔄 Maintenance

### Weekly Tasks
- [ ] Review open drift detection issues
- [ ] Check policy violation trends
- [ ] Review failed workflow runs
- [ ] Update dependencies if needed

### Monthly Tasks
- [ ] Review IAM role permissions
- [ ] Rotate AWS credentials
- [ ] Audit GitHub Actions logs
- [ ] Review cost estimates
- [ ] Update Terraform version if needed

### Quarterly Tasks
- [ ] Security audit of workflows
- [ ] Review and update policies
- [ ] Test disaster recovery procedures
- [ ] Review retention policies for artifacts
- [ ] Update documentation

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [AWS OIDC with GitHub](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/)
- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)

## 🤝 Support

For issues or questions:
1. Check this documentation
2. Review existing GitHub Issues
3. Create new issue with:
   - Environment details
   - Error messages
   - Workflow run link
   - Steps to reproduce

## 📝 Change Log

### Version 1.0.0 (Current)
- ✅ Multi-environment CI/CD pipeline
- ✅ Policy-as-Code enforcement
- ✅ Drift detection automation
- ✅ Rollback mechanisms
- ✅ Controlled destroy workflows
- ✅ OIDC authentication
- ✅ Comprehensive security scanning

---

**Last Updated:** 2024
**Maintained By:** DevOps Team
**License:** MIT
