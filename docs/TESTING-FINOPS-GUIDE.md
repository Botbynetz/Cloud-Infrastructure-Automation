# Testing & FinOps Implementation Guide

## Overview

Comprehensive testing strategy with Terratest and cost management with Infracost for enterprise infrastructure.

## 🧪 STEP 5: Testing with Terratest

### Test Suite Overview

**File:** `test/terraform_comprehensive_test.go`
**Total Tests:** 15 comprehensive test cases
**Coverage:** Multi-environment, security, compliance, cost optimization

### Test Categories

#### 1. Multi-Environment Tests
```go
TestTerraformMultiEnvironment
- Tests: dev, staging, prod, dr
- Validates: Backend configuration, region assignment, basic plan
```

#### 2. Security Tests
```go
TestSecurityGroupRules
- Validates: No SSH from 0.0.0.0/0 (OPA policy)
- Checks: Security group configurations

TestS3BucketEncryption
- Validates: S3 encryption enabled
- Checks: Bucket not public, versioning enabled

TestRDSEncryption
- Validates: RDS storage encryption
- Checks: Not publicly accessible
```

#### 3. Infrastructure Tests
```go
TestVPCCreation
- Validates: VPC creation with proper CIDR
- Checks: Mandatory tags (FinOps)

TestEC2InstanceCreation
- Validates: Instance type, state
- Checks: All mandatory tags present
```

#### 4. Compliance Tests
```go
TestTaggingCompliance
- Validates: All 7 mandatory tags
- Environments: All (dev, staging, prod, dr)

TestComplianceGDPR
- Validates: EU region for GDPR workloads
- Checks: Encryption at rest
```

#### 5. Cost Optimization Tests
```go
TestCostOptimization
- Dev: t3.micro, t3.small allowed
- Staging: t3.medium, t3.large allowed
- Prod: t3.xlarge, m5.xlarge allowed
```

#### 6. High Availability Tests
```go
TestHighAvailability
- Production: Multi-AZ RDS required
- Validates: HA configuration

TestBackupConfiguration
- Production: 7+ days backup retention
- Validates: Backup policies
```

#### 7. Disaster Recovery Tests
```go
TestDisasterRecoveryConfiguration
- Region: us-west-2 for DR
- Validates: DR resources properly tagged
```

### Running Tests

#### Prerequisites
```bash
# Install Go 1.21+
go version

# Install dependencies
cd test
go mod download

# Set AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

#### Run All Tests
```bash
cd test
go test -v -timeout 60m
```

#### Run Specific Test
```bash
go test -v -run TestVPCCreation -timeout 30m
```

#### Run Short Tests Only (Skip Load Tests)
```bash
go test -v -short
```

#### Run Tests in Parallel
```bash
go test -v -parallel 4 -timeout 90m
```

#### Generate Test Report
```bash
go test -v -json > test-report.json
go test -v -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

### CI/CD Integration

The tests are integrated into `.github/workflows/terraform-cicd.yml`:

```yaml
test:
  name: Infrastructure Tests
  runs-on: ubuntu-latest
  needs: validate
  steps:
    - name: Setup Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Run Terratest
      run: |
        cd test
        go mod download
        go test -v -timeout 30m
```

### Test Best Practices

1. **Always Clean Up**
   ```go
   defer terraform.Destroy(t, terraformOptions)
   ```

2. **Use Unique IDs**
   ```go
   uniqueID := random.UniqueId()
   ```

3. **Test in Parallel**
   ```go
   t.Parallel()
   ```

4. **Set Timeouts**
   ```go
   go test -timeout 60m
   ```

5. **Use Short Flag for Quick Tests**
   ```go
   if testing.Short() {
       t.Skip("Skipping load test in short mode")
   }
   ```

## 💰 STEP 6: FinOps with Infracost

### Infracost Workflow

**File:** `.github/workflows/infracost-estimation.yml`
**Features:** Cost estimation, PR diff, optimization analysis, budget alerts

### Key Features

#### 1. Cost Estimation (All Environments)
```yaml
Matrix Strategy:
- dev, staging, prod, dr
- Parallel execution
- JSON, Table, and HTML reports
```

**Cost Thresholds:**
- Dev: $500/month
- Staging: $2,000/month
- Production: $10,000/month
- DR: $10,000/month

#### 2. PR Cost Diff
- Compares base branch vs PR branch
- Shows cost increase/decrease
- Alerts on significant changes (>$1,000)
- Posts detailed comment on PR

#### 3. Cost Optimization Analysis
Provides recommendations:
- Right-sizing instances (30% savings)
- Reserved Instances (40% savings)
- Spot instances for staging (70% savings)
- S3 lifecycle policies
- Auto-shutdown for dev (70% savings)

**Estimated Total Savings:** $2,800-5,600/month (28-56% reduction)

#### 4. Monthly Cost Report
- Scheduled: 1st of each month at 9 AM UTC
- Creates GitHub issue with report
- Detailed breakdown per environment
- Year-over-year comparison
- 365-day artifact retention

#### 5. Budget Alerts
- 80% threshold warning
- 100% threshold critical alert
- Automatic GitHub issue creation
- Team notifications

### Setup Instructions

#### 1. Create Infracost Account
```bash
# Sign up at https://www.infracost.io
# Get API key from dashboard
```

#### 2. Add GitHub Secret
```bash
# Repository Settings → Secrets → Actions
INFRACOST_API_KEY=ico-xxxxxxxxxxxxx
```

#### 3. Configure AWS Pricing
```bash
# Infracost uses AWS Pricing API
# Ensure AWS credentials have pricing:GetProducts permission
```

#### 4. Test Locally
```bash
# Install Infracost CLI
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Set API key
export INFRACOST_API_KEY=ico-xxxxxxxxxxxxx

# Run cost estimate
cd terraform
infracost breakdown --path . --terraform-var-file=environments/dev.tfvars
```

### Cost Optimization Strategies

#### Quick Wins (5-10% savings)
1. **Right-Size Instances**
   - Review CloudWatch metrics
   - Use t3.micro for dev instead of t3.small
   - Downgrade underutilized instances

2. **Auto-Shutdown Dev Environment**
   - Evenings: 6 PM - 8 AM (14 hours)
   - Weekends: Friday 6 PM - Monday 8 AM (62 hours)
   - Total: 70% time savings = 70% cost savings

3. **S3 Lifecycle Policies**
   - Intelligent-Tiering for varying access
   - Move logs to Glacier after 90 days
   - Delete old snapshots

#### Medium-Term (20-40% savings)
1. **Reserved Instances**
   - Production: 1-year commitment
   - 40% savings vs on-demand
   - Review usage patterns quarterly

2. **Savings Plans**
   - Flexible across instance types
   - 30% savings
   - Better for variable workloads

3. **Spot Instances**
   - Staging environment for testing
   - 70% savings vs on-demand
   - Use with interruption handling

#### Long-Term (Additional 5-10% savings)
1. **Network Optimization**
   - VPC endpoints (no NAT Gateway)
   - Minimize cross-AZ transfer
   - CloudFront for static content

2. **Storage Optimization**
   - EBS gp3 instead of gp2 (20% cheaper)
   - Delete unused volumes
   - Enable EBS snapshot lifecycle

3. **Database Optimization**
   - Right-size RDS instances
   - Use Aurora Serverless for variable load
   - Read replicas only when needed

### Cost Monitoring Dashboard

#### Key Metrics
1. **Total Monthly Cost**
   - Track trend over time
   - Compare to budget

2. **Cost Per Environment**
   - Dev: Should be lowest
   - Prod: Highest but justified
   - DR: Standby costs

3. **Cost Per Service**
   - EC2: Compute costs
   - RDS: Database costs
   - S3: Storage costs
   - Data Transfer: Network costs

4. **Cost Efficiency**
   - Cost per customer
   - Cost per transaction
   - ROI metrics

#### Alerts Setup
```bash
# AWS Budgets
- Monthly budget per environment
- Alert at 80% and 100%
- Email notifications

# CloudWatch Alarms
- Cost anomaly detection
- Unusual spending patterns
- Daily cost alerts

# Infracost
- PR-level cost review
- Prevent cost surprises
- Automated in CI/CD
```

### Integration with Other Steps

#### STEP 1: Multi-Environment
- Cost estimates per environment
- Different budgets per env
- Auto-shutdown for dev

#### STEP 2: Secrets Management
- KMS costs included
- Vault infrastructure costs
- Secrets rotation Lambda costs

#### STEP 3: Policy-as-Code
- Cost policies enforced
- Instance type restrictions
- Storage limits per environment

#### STEP 4: CI/CD Pipeline
- Automated cost checks on PR
- Monthly reports automated
- Budget alerts integrated

#### STEP 5: Testing
- Test infrastructure costs
- Temporary resource costs
- Cleanup after tests

### Reporting

#### Weekly Report
- Cost trend analysis
- Top cost drivers
- Quick optimization wins

#### Monthly Report
- Comprehensive breakdown
- Year-over-year comparison
- Optimization progress
- Budget variance analysis

#### Quarterly Report
- Reserved Instance review
- Strategic cost planning
- FinOps maturity assessment
- ROI calculation

### Best Practices

1. **Tag Everything**
   - Use mandatory tags (STEP 1)
   - Enable cost allocation tags
   - Track costs by project/team

2. **Review Regularly**
   - Weekly: Quick check
   - Monthly: Detailed review
   - Quarterly: Strategic planning

3. **Automate Optimization**
   - Auto-shutdown for dev
   - Scheduled scaling
   - Automated cleanup

4. **Educate Team**
   - Cost awareness training
   - FinOps culture
   - Cost-conscious development

5. **Set Realistic Budgets**
   - Based on business needs
   - Allow for growth
   - Review quarterly

### Troubleshooting

#### Issue: Infracost API Key Invalid
```bash
Solution:
1. Check API key in GitHub Secrets
2. Verify key is active in Infracost dashboard
3. Regenerate key if needed
```

#### Issue: Cost Estimate Fails
```bash
Solution:
1. Check Terraform syntax
2. Verify all variables defined
3. Ensure AWS credentials valid
4. Check Infracost CLI version
```

#### Issue: Budget Alerts Not Firing
```bash
Solution:
1. Verify budget thresholds correct
2. Check workflow schedule
3. Ensure GitHub Actions enabled
4. Review workflow logs
```

## 📊 Success Metrics

### Testing (STEP 5)
- ✅ 15 comprehensive test cases
- ✅ Multi-environment coverage
- ✅ Security compliance validation
- ✅ Cost policy enforcement tests
- ✅ CI/CD integration

### FinOps (STEP 6)
- ✅ Automated cost estimation
- ✅ PR-level cost review
- ✅ Monthly cost reports
- ✅ Budget alerts
- ✅ Optimization recommendations
- ✅ 28-56% potential savings identified

## 📚 Resources

### Terratest
- [Official Documentation](https://terratest.gruntwork.io/)
- [AWS Module](https://pkg.go.dev/github.com/gruntwork-io/terratest/modules/aws)
- [Examples](https://github.com/gruntwork-io/terratest/tree/master/examples)

### Infracost
- [Official Documentation](https://www.infracost.io/docs/)
- [GitHub Actions](https://www.infracost.io/docs/integrations/github_actions/)
- [Cost Optimization Guide](https://www.infracost.io/docs/guides/cost_optimization/)

### AWS Cost Management
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Budgets](https://aws.amazon.com/aws-cost-management/aws-budgets/)
- [AWS Cost Anomaly Detection](https://aws.amazon.com/aws-cost-management/aws-cost-anomaly-detection/)

---

**Last Updated:** November 2025
**Maintained By:** DevOps Team
**License:** MIT
