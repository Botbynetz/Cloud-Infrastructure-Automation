# Zero Trust Security Architecture Module

## Overview

This module implements comprehensive **Zero Trust security controls** for AWS infrastructure, following the principle of "never trust, always verify". It provides network micro-segmentation, identity-based access control, just-in-time access provisioning, and automated secrets rotation.

## Features

### 🔒 **Network Micro-Segmentation**
- **5-tier security architecture** (Public, Web, App, Data, Admin)
- Explicit deny-all baseline with least-privilege rules
- Security group chaining (each tier only talks to adjacent tier)
- Complete network isolation for data tier

### 👤 **Identity-Based Access Control (IBAC)**
- AWS IAM Identity Center (SSO) integration
- 3 permission sets (Read-Only, Power User, Admin)
- Session duration controls (2-8 hours based on role)
- MFA enforcement for administrative access

### ⏱️ **Just-in-Time (JIT) Access**
- Temporary SSH/RDP access (15 minutes - 8 hours)
- Automated rule revocation after expiration
- Complete audit trail in DynamoDB
- Real-time SNS notifications for all access grants
- Cleanup runs every 5 minutes

### 🔑 **Automated Secrets Rotation**
- RDS password rotation every 30 days
- Zero-downtime rotation process
- SNS notifications on rotation events
- Lambda-based rotation automation

### 🌐 **VPC Endpoints (Private AWS Access)**
- S3 Gateway Endpoint
- DynamoDB Gateway Endpoint
- Secrets Manager Interface Endpoint
- SSM Interface Endpoints (for Session Manager)
- No internet gateway needed for AWS service access

### 📊 **Comprehensive Monitoring**
- CloudWatch dashboard for Zero Trust metrics
- Alarms for high JIT usage, errors, rotation failures
- Audit logs with 30-day retention
- DynamoDB query capabilities for compliance

## Usage

### Basic Configuration

```hcl
module "zero_trust" {
  source = "./modules/zero-trust"
  
  project_name = "cloud-infra"
  environment  = "production"
  
  # Network configuration
  vpc_id                   = module.vpc.vpc_id
  vpc_cidr                 = "10.0.0.0/16"
  private_subnet_ids       = module.vpc.private_subnet_ids
  private_route_table_ids  = module.vpc.private_route_table_ids
  
  # Micro-segmentation ports
  web_tier_port  = 8080
  app_tier_port  = 8081
  data_tier_port = 5432  # PostgreSQL
  
  # JIT access configuration
  jit_access_duration_minutes = 60  # 1 hour
  jit_allowed_ports           = [22, 3389]
  jit_notification_emails     = ["security@example.com"]
  
  # Secrets rotation
  enable_secrets_rotation              = true
  secrets_rotation_notification_emails = ["devops@example.com"]
  
  # Monitoring
  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  
  tags = local.common_tags
}
```

### Advanced Configuration with Identity Center

```hcl
module "zero_trust" {
  source = "./modules/zero-trust"
  
  # ... basic config ...
  
  # Enable AWS IAM Identity Center (SSO)
  enable_identity_center       = true
  identity_center_instance_arn = "arn:aws:sso:::instance/ssoins-1234567890abcdef"
  
  # Session duration controls
  read_only_session_duration  = "PT8H"   # 8 hours
  power_user_session_duration = "PT4H"   # 4 hours
  admin_session_duration      = "PT2H"   # 2 hours (stricter)
  
  # Tighter JIT access
  jit_access_duration_minutes = 30  # 30 minutes
  jit_usage_threshold         = 5   # Alert if > 5 requests in 5 min
}
```

## Architecture

### Network Micro-Segmentation Flow

```
Internet
   │
   └──> [Public Tier SG] (ALB/NLB only)
           Port 80/443 from 0.0.0.0/0
           │
           └──> [Web Tier SG] (App Servers)
                   Port 8080 from Public Tier only
                   │
                   └──> [App Tier SG] (Business Logic)
                           Port 8081 from Web Tier only
                           │
                           └──> [Data Tier SG] (Databases)
                                   Port 5432 from App Tier only
                                   ❌ NO EGRESS ALLOWED

[Admin Tier SG] (Bastion)
   ├─> JIT Rule 1: 203.0.113.1/32 → SSH (expires in 60 min)
   ├─> JIT Rule 2: 198.51.100.5/32 → RDP (expires in 30 min)
   └─> Automatic cleanup every 5 minutes
```

### JIT Access Workflow

```
1. User requests JIT access via API/Console
   ├─> Validates user identity
   ├─> Validates source IP
   └─> Validates port against allowed list

2. Lambda grants temporary access
   ├─> Adds security group rule (IP/32)
   ├─> Logs to DynamoDB (audit trail)
   └─> Sends SNS notification

3. User performs administrative tasks
   └─> Access valid for configured duration

4. Automated cleanup (every 5 minutes)
   ├─> Scans DynamoDB for expired rules
   ├─> Revokes security group rules
   ├─> Updates audit log (status=EXPIRED)
   └─> Sends notification if configured
```

## Compliance

This module helps meet requirements for:

- ✅ **SOC 2 Type II**: CC6.1 (Logical access), CC6.2 (Least privilege)
- ✅ **ISO 27001**: A.9 (Access control), A.10 (Cryptography)
- ✅ **NIST 800-53**: AC-3 (Access enforcement), AC-6 (Least privilege)
- ✅ **PCI-DSS**: Req 7 (Restrict access), Req 8 (Identify users)
- ✅ **HIPAA**: 164.308(a)(4) (Access controls)

## Cost Estimation

| Resource | Monthly Cost |
|----------|--------------|
| Lambda (JIT + Rotation) | $2-5 |
| DynamoDB (JIT audit log) | $1-3 |
| VPC Endpoints (6 endpoints) | $40-60 |
| SNS notifications | $0.50 |
| CloudWatch Logs | $2-5 |
| **Total** | **$45-75/month** |

## Security Best Practices

1. **Always use JIT access**
   ```bash
   # Never add permanent SSH rules
   # Always request temporary access via Lambda
   aws lambda invoke \
     --function-name jit-access \
     --payload '{"user_email":"admin@example.com","user_ip":"203.0.113.1","port":22,"reason":"Deploy hotfix"}' \
     response.json
   ```

2. **Monitor JIT access patterns**
   ```bash
   # Query recent access grants
   aws dynamodb query \
     --table-name jit-access-log \
     --index-name user-index \
     --key-condition-expression "user_email = :email" \
     --expression-attribute-values '{":email":{"S":"admin@example.com"}}'
   ```

3. **Regular secrets rotation**
   - Rotation runs automatically every 30 days
   - Manual rotation: Invoke Lambda directly
   - Always test application connectivity after rotation

4. **Use VPC endpoints**
   - Eliminates internet gateway dependency
   - Reduces data transfer costs
   - Improves security posture

## Troubleshooting

### JIT Access Not Working

**Problem**: Unable to SSH/RDP after JIT grant

**Solutions**:
1. Check security group rules:
   ```bash
   aws ec2 describe-security-group-rules \
     --filters Name=group-id,Values=sg-xxxxx | jq '.SecurityGroupRules[] | select(.Description | contains("JIT"))'
   ```

2. Verify source IP matches:
   ```bash
   curl https://ifconfig.me
   ```

3. Check DynamoDB for access record:
   ```bash
   aws dynamodb get-item \
     --table-name jit-access-log \
     --key '{"access_id":{"S":"xxx-xxx-xxx"}}'
   ```

### Secrets Rotation Failed

**Problem**: RDS password rotation Lambda errors

**Solutions**:
1. Check Lambda logs:
   ```bash
   aws logs tail /aws/lambda/rds-password-rotation --follow
   ```

2. Verify IAM permissions:
   - `secretsmanager:PutSecretValue`
   - `rds:ModifyDBInstance`

3. Test rotation manually:
   ```bash
   aws lambda invoke \
     --function-name rds-password-rotation \
     response.json
   ```

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `project_name` | string | - | yes | Project name |
| `environment` | string | - | yes | Environment (dev/staging/prod) |
| `vpc_id` | string | - | yes | VPC ID |
| `jit_access_duration_minutes` | number | 60 | no | JIT access duration (15-480) |
| `enable_secrets_rotation` | bool | true | no | Enable automated secrets rotation |

[Full input documentation in variables.tf]

## Outputs

| Name | Description |
|------|-------------|
| `public_tier_sg_id` | Security group for public tier (load balancers) |
| `web_tier_sg_id` | Security group for web tier |
| `app_tier_sg_id` | Security group for app tier |
| `data_tier_sg_id` | Security group for data tier (isolated) |
| `jit_access_lambda_arn` | JIT access Lambda function ARN |
| `cloudwatch_dashboard_url` | Zero Trust monitoring dashboard |

## Examples

### Request JIT SSH Access

```python
import boto3
import json

lambda_client = boto3.client('lambda')

response = lambda_client.invoke(
    FunctionName='cloud-infra-prod-jit-access',
    InvocationType='RequestResponse',
    Payload=json.dumps({
        'action': 'grant',
        'user_email': 'admin@example.com',
        'user_ip': '203.0.113.1',
        'port': 22,
        'reason': 'Emergency database maintenance'
    })
)

result = json.loads(response['Payload'].read())
print(f"Access granted. Expires: {result['body']['expires_at']}")
```

### Revoke JIT Access Early

```python
response = lambda_client.invoke(
    FunctionName='cloud-infra-prod-jit-access',
    Payload=json.dumps({
        'action': 'revoke',
        'access_id': 'abc-123-def-456'
    })
)
```

## References

- [AWS Zero Trust Architecture](https://aws.amazon.com/security/zero-trust/)
- [NIST Zero Trust Architecture (SP 800-207)](https://csrc.nist.gov/publications/detail/sp/800-207/final)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

---

**Version**: 1.0.0  
**Last Updated**: November 16, 2025  
**Maintained By**: Security Team
