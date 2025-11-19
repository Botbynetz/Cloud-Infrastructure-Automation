# Policy as Code Documentation

## Overview

This project uses **Open Policy Agent (OPA)** for automated policy enforcement across infrastructure deployments. Policies are written in **Rego** language and automatically validated on every pull request.

## Policy Categories

### 🔐 1. Security Policies (`policies/terraform.rego`)

**Enforced Rules:**

- ✅ **No public S3 buckets** - Blocks `public-read` ACLs
- ✅ **Encryption at rest** - Enforces encryption for S3, EBS, RDS
- ✅ **No dangerous security groups** - Blocks SSH/RDP from 0.0.0.0/0
- ✅ **HTTPS only** - Enforces HTTPS for ALB listeners
- ✅ **IMDSv2 required** - Enforces IMDSv2 for EC2 instances
- ✅ **VPC flow logs** - Required for production VPCs
- ✅ **No public RDS** - Blocks publicly accessible databases

**Example Violation:**
```
SECURITY VIOLATION: S3 bucket 'aws_s3_bucket.logs' has public-read ACL. Use private ACL only.
```

### 💰 2. Cost Control Policies (`policies/cost.rego`)

**Enforced Rules:**

- ✅ **Instance type limits** - Restricts expensive instances in dev/staging
  - Dev: t3.nano, t3.micro, t3.small
  - Staging: t3.micro, t3.small, t3.medium
  - Prod: Up to m5.8xlarge
- ✅ **No multi-AZ in dev** - Blocks RDS multi-AZ in non-production
- ✅ **EBS volume size limits** - Max 100GB in dev, 500GB in staging
- ✅ **Auto-shutdown enforcement** - Requires AutoShutdown tag for dev resources
- ✅ **Cost approval threshold** - Blocks deployments exceeding $500/month

**Example Violation:**
```
COST VIOLATION: Instance type 'm5.8xlarge' not allowed in dev environment. Allowed tiers: ["nano", "micro", "small"]
```

### ✅ 3. Compliance Policies (`policies/compliance.rego`)

**Enforced Rules:**

#### GDPR Compliance
- ✅ Encryption for personal data
- ✅ EU region data residency
- ✅ 30-day backup retention

#### HIPAA Compliance
- ✅ Encryption for PHI (Protected Health Information)
- ✅ Audit logging enabled
- ✅ No public access to PHI data

#### SOC2 Compliance
- ✅ Change tracking tags (LastModified, ModifiedBy)
- ✅ Backup policies defined
- ✅ Monitoring enabled

#### ISO27001 Compliance
- ✅ Network segregation (subnet groups)
- ✅ Secure AMI configuration
- ✅ 90-day log retention

#### PCI-DSS Compliance
- ✅ Encryption for cardholder data
- ✅ Network segmentation
- ✅ Audit logging

**Example Violation:**
```
GDPR VIOLATION: Database 'aws_db_instance.user_db' with personal data must have backup retention >= 30 days (current: 7)
```

### 📋 4. Mandatory Tags

All resources must have these tags:
- `Environment` (dev, staging, prod, dr)
- `Project`
- `Owner` (email)
- `CostCenter`
- `ManagedBy` (Terraform)

**Example Violation:**
```
COMPLIANCE VIOLATION: Resource 'aws_instance.web' missing mandatory tags: ["Owner", "CostCenter"]
```

## Installation

### 1. Install OPA

**Windows (PowerShell):**
```powershell
# Using Chocolatey
choco install opa

# Or download binary
Invoke-WebRequest -Uri https://openpolicyagent.org/downloads/latest/opa_windows_amd64.exe -OutFile opa.exe
Move-Item opa.exe C:\Windows\System32\
```

**Linux/macOS:**
```bash
# Using curl
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/
```

**Verify installation:**
```bash
opa version
# Output: Version: 0.58.0
```

### 2. Validate Policies

```bash
# Check syntax
opa check policies/*.rego

# Run tests
opa test policies/ -v

# Expected output:
# PASS: 20/20
```

## Usage

### Local Development

1. **Generate Terraform plan:**
```bash
cd terraform
terraform init -backend-config=backend/dev.conf
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
```

2. **Evaluate policies:**
```bash
# Security policies
opa eval --data policies/terraform.rego --input terraform/tfplan.json \
  --format pretty "data.terraform.deny"

# Cost policies
opa eval --data policies/cost.rego --input terraform/tfplan.json \
  --format pretty "data.terraform.cost.deny"

# Compliance policies
opa eval --data policies/compliance.rego --input terraform/tfplan.json \
  --format pretty "data.terraform.compliance.deny"
```

3. **Check if deployment is allowed:**
```bash
opa eval --data policies/terraform.rego --input terraform/tfplan.json \
  --format pretty "data.terraform.allow_deployment"

# Output: true (if no violations)
```

### CI/CD Integration

Policies are automatically enforced via GitHub Actions (`.github/workflows/opa-policy-check.yml`):

**Triggered on:**
- Pull requests to `main` branch
- Push to `main` branch
- Changes to `terraform/**` or `policies/**`

**Workflow Steps:**
1. ✅ Install OPA
2. ✅ Validate policy syntax
3. ✅ Run policy tests
4. ✅ Generate Terraform plan
5. ✅ Evaluate policies (security, cost, compliance)
6. ✅ Post PR comment with results
7. ❌ Block merge if violations detected

**Example PR Comment:**
```
## OPA Policy Check Results ✅ PASSED

### Summary
| Category | Violations |
|----------|------------|
| 🔐 Security | 0 |
| 💰 Cost Control | 0 |
| ✅ Compliance | 0 |
| **Total** | **0** |

✅ All policies passed. Ready to merge!
```

## Policy Customization

### Adding New Policies

1. **Create policy rule in `policies/terraform.rego`:**
```rego
# Deny t2 instances in production
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    
    env := resource.change.after.tags.Environment
    env == "prod"
    
    startswith(resource.change.after.instance_type, "t2.")
    
    msg := sprintf("POLICY VIOLATION: Instance '%s' uses t2 type in production. Use t3 or larger", 
                   [resource.address])
}
```

2. **Add test in `policies/terraform_test.rego`:**
```rego
test_deny_t2_in_production {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_instance.web",
            "type": "aws_instance",
            "change": {
                "after": {
                    "instance_type": "t2.micro",
                    "tags": {"Environment": "prod"}
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "t2 type in production")
}
```

3. **Test locally:**
```bash
opa test policies/terraform_test.rego -v
```

### Policy Severity Levels

- **DENY** - Blocks deployment (violations must be fixed)
- **WARN** - Allows deployment but shows warning

**Example:**
```rego
# DENY - blocks deployment
deny[msg] { ... }

# WARN - allows but warns
warn[msg] { ... }
```

## Policy Examples

### Example 1: Allow Specific CIDR Only

```rego
# Only allow SSH from company VPN
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    rule := resource.change.after
    
    rule.from_port <= 22
    rule.to_port >= 22
    not rule.cidr_blocks[_] == "10.0.0.0/8"  # Company VPN
    
    msg := "SSH must only be allowed from company VPN (10.0.0.0/8)"
}
```

### Example 2: Enforce Specific Tag Values

```rego
# CostCenter must match approved list
approved_cost_centers := ["CC-DEV-001", "CC-PROD-001", "CC-DR-001"]

deny[msg] {
    resource := input.resource_changes[_]
    cost_center := resource.change.after.tags.CostCenter
    
    not cost_center == approved_cost_centers[_]
    
    msg := sprintf("Invalid CostCenter '%s'. Approved: %v", 
                   [cost_center, approved_cost_centers])
}
```

### Example 3: Environment-Specific Rules

```rego
# Production must have Critical=true tag
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    
    env := resource.change.after.tags.Environment
    env == "prod"
    
    not resource.change.after.tags.Critical == "true"
    
    msg := "Production databases must have Critical=true tag"
}
```

## Troubleshooting

### Policy Syntax Error

```bash
# Validate syntax
opa check policies/terraform.rego

# Error example:
# 1 error occurred: policies/terraform.rego:10: rego_parse_error: unexpected eof token
```

**Fix:** Check for missing brackets, quotes, or syntax errors at line 10.

### Test Failures

```bash
opa test policies/ -v

# FAIL: test_deny_public_s3_bucket (0.00s)
#   Expected violation but got none
```

**Fix:** Review test input data and policy logic. Ensure test data matches policy conditions.

### GitHub Actions Failure

**Error:** `OPA not found`

**Fix:** Workflow uses `open-policy-agent/setup-opa@v2` action. Ensure it's not blocked by firewall.

**Error:** `terraform plan failed`

**Fix:** Ensure Terraform files are valid. Run `terraform validate` locally first.

## Best Practices

1. **Write tests first** - TDD approach ensures policies work as expected
2. **Use descriptive messages** - Include resource address and violation reason
3. **Categorize violations** - Use prefixes: `SECURITY VIOLATION`, `COST VIOLATION`, etc.
4. **Document policies** - Add comments explaining business rules
5. **Version control policies** - Track changes via Git
6. **Regular reviews** - Update policies as requirements change
7. **Test locally** - Always test before pushing

## References

- [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/)
- [Rego Language Reference](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [OPA Terraform Guide](https://www.openpolicyagent.org/docs/latest/terraform/)
- [Policy Testing](https://www.openpolicyagent.org/docs/latest/policy-testing/)
