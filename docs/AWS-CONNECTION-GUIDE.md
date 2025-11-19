# =============================================================================
# AWS CONNECTION GUIDE - Enable Real Deployments
# =============================================================================
# This guide shows how to connect workflows to real AWS account
# STEP 3 Enhancement: Enable actual infrastructure deployment

## ⚠️ IMPORTANT: Security First!

**WARNING**: Connecting to real AWS will:
- Create actual resources (costs money!)
- Require AWS credentials (keep secure!)
- Deploy infrastructure (test in dev first!)

## 🎯 Prerequisites

1. **AWS Account**
   - Active AWS account with billing enabled
   - Admin access or sufficient IAM permissions
   - Credit card on file (AWS charges apply)

2. **AWS CLI Installed**
   ```bash
   # Check if installed
   aws --version
   
   # If not, install:
   # Windows: choco install awscli
   # Mac: brew install awscli
   # Linux: pip install awscli
   ```

3. **Terraform Installed**
   ```bash
   terraform --version
   ```

## 🔐 Method 1: AWS Access Keys (Simpler, Less Secure)

### Step 1: Create IAM User for Terraform

```bash
# 1. Go to AWS Console → IAM → Users → Create User
# 2. User name: terraform-automation
# 3. Attach policies:
#    - PowerUserAccess (for dev/testing)
#    - OR create custom policy (production)
# 4. Create access key → Download CSV
```

### Step 2: Configure GitHub Secrets

```bash
# Go to GitHub repo → Settings → Secrets and variables → Actions

# Add these secrets:
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
```

### Step 3: Update Workflow Files

Edit `.github/workflows/terraform-cicd.yml`:

```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_REGION: ${{ secrets.AWS_REGION }}

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      # Rest of your terraform commands...
```

## 🔐 Method 2: OIDC (Recommended, More Secure)

### Step 1: Create IAM Identity Provider

```bash
# AWS Console → IAM → Identity providers → Add provider
# Provider type: OpenID Connect
# Provider URL: https://token.actions.githubusercontent.com
# Audience: sts.amazonaws.com
```

### Step 2: Create IAM Role for GitHub Actions

```bash
# Create trust policy file: github-actions-trust-policy.json
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Botbynetz/Cloud-Infrastructure-Automation:*"
        }
      }
    }
  ]
}
```

```bash
# Create the role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Attach permissions
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### Step 3: Update Workflow with OIDC

Edit `.github/workflows/terraform-cicd.yml`:

```yaml
permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
          aws-region: us-east-1
      
      # Terraform commands...
```

## 📦 Method 3: Local Development

### Setup Local AWS Credentials

```bash
# Configure AWS CLI
aws configure

# It will ask for:
AWS Access Key ID: AKIAXXXXXXXXXXXXXXXX
AWS Secret Access Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Default region name: us-east-1
Default output format: json

# Verify connection
aws sts get-caller-identity
```

### Run Terraform Locally

```bash
cd terraform

# Initialize
terraform init -backend-config=backend/dev.conf

# Plan
terraform plan -var-file=variables-integrated-example.tf

# Apply (careful!)
terraform apply -var-file=variables-integrated-example.tf

# Destroy when done
terraform destroy -var-file=variables-integrated-example.tf
```

## 🛡️ Security Best Practices

### 1. **Least Privilege IAM Policy**

Instead of PowerUserAccess, use custom policy:

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
        "iam:*",
        "kms:*",
        "secretsmanager:*",
        "cloudwatch:*",
        "logs:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "ec2:DeleteVpc",
        "rds:DeleteDBInstance",
        "s3:DeleteBucket"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalTag/Environment": "dev"
        }
      }
    }
  ]
}
```

### 2. **Enable MFA**

```bash
# Require MFA for destructive operations
aws iam put-user-policy \
  --user-name terraform-automation \
  --policy-name RequireMFA \
  --policy-document file://mfa-policy.json
```

### 3. **Use Separate AWS Accounts**

- **Dev Account**: Testing & experiments
- **Staging Account**: Pre-production validation
- **Prod Account**: Production workloads
- **DR Account**: Disaster recovery

### 4. **Rotate Credentials Regularly**

```bash
# Rotate access keys every 90 days
aws iam create-access-key --user-name terraform-automation
aws iam delete-access-key --user-name terraform-automation --access-key-id OLD_KEY
```

## 💰 Cost Management

### Set Up Budget Alerts

```bash
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

### Enable Cost Explorer

```bash
# AWS Console → Cost Management → Cost Explorer
# Enable Cost Explorer (free)
# Set up cost allocation tags
```

### Tag Resources for Cost Tracking

```hcl
# In your terraform
default_tags {
  tags = {
    Environment = "dev"
    Project     = "cloud-infrastructure-automation"
    CostCenter  = "engineering"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
  }
}
```

## 🧪 Testing Workflow

### Phase 1: Validate Locally (Cost: $0)

```bash
terraform init
terraform validate
terraform plan
```

### Phase 2: Deploy to Dev Account (Cost: ~$50/month)

```bash
terraform workspace select dev
terraform apply -var="environment=dev"

# Test for 1 day
# Destroy after testing
terraform destroy
```

### Phase 3: Deploy to Staging (Cost: ~$200/month)

```bash
terraform workspace select staging
terraform apply -var="environment=staging"

# Run load tests
# Validate observability
# Keep for 1 week
```

### Phase 4: Deploy to Production (Cost: ~$500/month)

```bash
terraform workspace select prod
terraform apply -var="environment=prod"

# Full monitoring
# Disaster recovery active
# Regular backups
```

## 📊 Monitoring Deployment

### Check Terraform State

```bash
# View state
terraform show

# List resources
terraform state list

# Get specific output
terraform output grafana_endpoint
```

### Verify AWS Resources

```bash
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=cloud-infrastructure-automation"

# Check S3 buckets
aws s3 ls | grep cloud-infrastructure

# Check RDS
aws rds describe-db-instances

# Check costs (today)
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-11-20 \
  --granularity DAILY \
  --metrics BlendedCost
```

## 🚨 Troubleshooting

### Issue: "Access Denied"

```bash
# Check credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam get-user-policy --user-name terraform-automation --policy-name TerraformPolicy
```

### Issue: "Resource Already Exists"

```bash
# Import existing resource
terraform import aws_vpc.main vpc-xxxxx

# Or remove from state
terraform state rm aws_vpc.main
```

### Issue: "State Lock Failed"

```bash
# Force unlock (careful!)
terraform force-unlock LOCK_ID

# Check DynamoDB table
aws dynamodb scan --table-name cloud-infra-terraform-locks
```

## 🔄 Workflow Integration Checklist

- [ ] AWS credentials configured in GitHub Secrets
- [ ] S3 bucket created for Terraform state
- [ ] DynamoDB table created for state locking
- [ ] KMS key created for encryption
- [ ] Budget alerts configured
- [ ] CloudWatch alarms set up
- [ ] SNS topics for notifications
- [ ] Slack/PagerDuty webhooks configured
- [ ] Tested in dev environment
- [ ] Validated with OPA policies
- [ ] Cost estimation with Infracost
- [ ] Monitoring with Prometheus/Grafana

## 📚 Additional Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions + AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## ✅ Success Criteria

After connection, you should see:
1. ✅ Workflows running successfully
2. ✅ Resources created in AWS
3. ✅ Terraform state stored in S3
4. ✅ Prometheus metrics flowing
5. ✅ Grafana dashboards populated
6. ✅ Cost tracking in FinOps module
7. ✅ Alerts triggering correctly
8. ✅ Documentation auto-updating

---

**Remember**: Start small (dev), test thoroughly, then scale to production! 🚀
