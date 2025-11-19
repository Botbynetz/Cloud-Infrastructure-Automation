# Secrets Management Guide

## Overview

This guide covers secure secrets management using:
- **HashiCorp Vault** - Centralized secrets storage with dynamic credentials
- **AWS Secrets Manager** - Cloud-native secrets with automatic rotation
- **Mozilla SOPS** - File encryption for configuration files
- **AWS KMS** - Multi-cloud encryption key management

## Architecture

```
┌─────────────────┐
│  Developers     │
│  CI/CD Pipeline │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  HashiCorp      │◄────►│  AWS Secrets     │
│  Vault          │      │  Manager         │
└────────┬────────┘      └─────────┬────────┘
         │                         │
         │                         │
         ▼                         ▼
┌─────────────────────────────────────────┐
│           AWS KMS Encryption            │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │ Dev Keys │ │ Prod Keys│ │ DR Keys │ │
│  └──────────┘ └──────────┘ └─────────┘ │
└─────────────────────────────────────────┘
```

## 1. HashiCorp Vault Setup

### Installation

```bash
# Install Vault (Windows)
choco install vault

# Install Vault (Linux)
wget https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip
unzip vault_1.15.0_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Verify installation
vault version
```

### Initialize Vault

```bash
# Start Vault dev server (for testing only)
vault server -dev

# Export Vault address
$env:VAULT_ADDR="http://127.0.0.1:8200"

# Initialize production Vault
vault operator init -key-shares=5 -key-threshold=3

# Unseal Vault (requires 3 keys)
vault operator unseal <KEY1>
vault operator unseal <KEY2>
vault operator unseal <KEY3>

# Login
vault login <ROOT_TOKEN>
```

### Store Secrets in Vault

```bash
# AWS credentials
vault kv put cloud-infra/dev/aws `
  access_key="AKIA..." `
  secret_key="..." `
  region="ap-southeast-1"

# Database credentials
vault kv put cloud-infra/prod/database `
  host="prod-db.example.com" `
  port="5432" `
  username="dbadmin" `
  password="..." `
  database="cloudinfra"

# API keys
vault kv put cloud-infra/prod/api-keys `
  stripe_key="sk_live_..." `
  sendgrid_key="SG...." `
  slack_webhook="https://hooks.slack.com/..."
```

### Read Secrets from Vault

```bash
# Read entire secret
vault kv get cloud-infra/dev/aws

# Read specific field
vault kv get -field=access_key cloud-infra/dev/aws

# Read as JSON
vault kv get -format=json cloud-infra/dev/aws
```

### Use Vault in Terraform

```hcl
# Configure Vault provider
provider "vault" {
  address = "https://vault.example.com"
  token   = var.vault_token
}

# Read secret
data "vault_kv_secret_v2" "aws" {
  mount = "cloud-infra"
  name  = "dev/aws"
}

# Use secret
provider "aws" {
  access_key = data.vault_kv_secret_v2.aws.data["access_key"]
  secret_key = data.vault_kv_secret_v2.aws.data["secret_key"]
  region     = data.vault_kv_secret_v2.aws.data["region"]
}
```

## 2. SOPS Encryption

### Installation

```bash
# Install SOPS (Windows)
choco install sops

# Install SOPS (Linux)
wget https://github.com/mozilla/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
```

### Encrypt Files

```bash
# Encrypt Terraform variables
sops -e terraform/environments/prod.tfvars > terraform/environments/prod.tfvars.enc

# Encrypt Ansible secrets
sops -e ansible/group_vars/prod.yml > ansible/group_vars/prod.yml.enc

# Encrypt JSON files
sops -e config/secrets.json > config/secrets.json.enc
```

### Decrypt Files

```bash
# Decrypt to stdout
sops -d terraform/environments/prod.tfvars.enc

# Decrypt to file
sops -d terraform/environments/prod.tfvars.enc > terraform/environments/prod.tfvars

# Edit encrypted file in place
sops terraform/environments/prod.tfvars.enc
```

### SOPS Configuration

Configuration in `.sops.yaml`:

```yaml
creation_rules:
  # Development environment
  - path_regex: environments/dev\.tfvars$
    kms: 'arn:aws:kms:ap-southeast-1:ACCOUNT_ID:alias/cloud-infra-dev-terraform-state'
    encrypted_regex: '^(password|secret|token|key|credential)$'
  
  # Production environment (multi-cloud)
  - path_regex: environments/prod\.tfvars$
    kms: 'arn:aws:kms:ap-southeast-1:ACCOUNT_ID:alias/cloud-infra-prod-terraform-state'
    gcp_kms: 'projects/PROJECT_ID/locations/asia-southeast1/keyRings/prod-keyring/cryptoKeys/terraform-key'
    encrypted_regex: '^(password|secret|token|key|credential|private_key)$'
```

## 3. AWS Secrets Manager

### Create Secrets

```bash
# Create database credentials
aws secretsmanager create-secret `
  --name cloud-infra/prod/database `
  --description "Production database credentials" `
  --secret-string '{
    "username": "dbadmin",
    "password": "GENERATED_PASSWORD",
    "host": "prod-db.example.com",
    "port": 5432,
    "database": "cloudinfra"
  }' `
  --kms-key-id alias/cloud-infra-prod-secrets

# Create API keys
aws secretsmanager create-secret `
  --name cloud-infra/prod/api-keys `
  --secret-string '{
    "stripe_key": "sk_live_...",
    "sendgrid_key": "SG....",
    "slack_webhook": "https://hooks.slack.com/..."
  }' `
  --kms-key-id alias/cloud-infra-prod-secrets
```

### Retrieve Secrets

```bash
# Get secret value
aws secretsmanager get-secret-value `
  --secret-id cloud-infra/prod/database `
  --query SecretString `
  --output text

# Parse JSON secret
aws secretsmanager get-secret-value `
  --secret-id cloud-infra/prod/database `
  --query SecretString `
  --output text | ConvertFrom-Json
```

### Enable Automatic Rotation

```bash
# Enable rotation for RDS credentials
aws secretsmanager rotate-secret `
  --secret-id cloud-infra/prod/database `
  --rotation-lambda-arn arn:aws:lambda:ap-southeast-1:ACCOUNT_ID:function:cloud-infra-prod-rotate-rds `
  --rotation-rules AutomaticallyAfterDays=30
```

## 4. Secrets Rotation

### RDS Password Rotation

Automatic rotation every 30 days via Lambda:

```python
# Trigger manual rotation
aws lambda invoke `
  --function-name cloud-infra-prod-rotate-rds `
  --payload '{"SecretId": "cloud-infra/prod/database"}' `
  response.json

# Check rotation status
aws secretsmanager describe-secret `
  --secret-id cloud-infra/prod/database `
  --query 'RotationEnabled'
```

### API Key Rotation

Automatic rotation every 90 days:

```bash
# Trigger manual rotation
aws lambda invoke `
  --function-name cloud-infra-prod-rotate-api-keys `
  response.json

# View rotation history
aws secretsmanager list-secret-version-ids `
  --secret-id cloud-infra/prod/api-keys
```

## 5. IAM Least-Privilege Policies

### Developer Access

```bash
# Assume developer role
aws sts assume-role `
  --role-arn arn:aws:iam::ACCOUNT_ID:role/cloud-infra-dev-terraform-dev `
  --role-session-name developer-session
```

**Permissions:**
- ✅ Read all resources (ec2:Describe*, rds:Describe*)
- ✅ Create/modify dev resources (t2.micro, t3.micro only)
- ✅ Read dev secrets
- ❌ Modify production resources
- ❌ Delete critical resources

### Production Access (MFA Required)

```bash
# Assume production role with MFA
aws sts assume-role `
  --role-arn arn:aws:iam::ACCOUNT_ID:role/cloud-infra-prod-terraform-prod `
  --role-session-name prod-session `
  --serial-number arn:aws:iam::ACCOUNT_ID:mfa/USER `
  --token-code 123456
```

**Permissions:**
- ✅ Full production access (with MFA)
- ✅ Read/write production secrets
- ❌ Delete resources tagged as Critical=true

### CI/CD Access

```bash
# GitHub Actions uses OIDC
# No static credentials required
```

**Permissions:**
- ✅ Read all resources
- ✅ Read secrets
- ✅ Write Terraform state
- ❌ Create/delete resources
- ❌ Manual apply required

## 6. Emergency Access

### Break Glass Procedure

In case of emergency:

```bash
# 1. Use root account credentials (stored in physical vault)
aws configure --profile root

# 2. Retrieve Vault unseal keys
aws secretsmanager get-secret-value `
  --secret-id vault/unseal-keys `
  --profile root

# 3. Unseal Vault
vault operator unseal <KEY1>
vault operator unseal <KEY2>
vault operator unseal <KEY3>

# 4. Reset root token
vault operator generate-root

# 5. Access secrets
vault login <NEW_ROOT_TOKEN>
vault kv get cloud-infra/prod/database
```

### Audit Trail

```bash
# Check who accessed secrets
aws cloudtrail lookup-events `
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=cloud-infra/prod/database `
  --max-results 100

# View Vault audit logs
vault audit enable file file_path=/var/log/vault_audit.log
vault audit list
```

## 7. Best Practices

### ✅ DO

- **Rotate secrets regularly** - 30 days for RDS, 90 days for API keys
- **Use dynamic credentials** - Short-lived credentials from Vault
- **Encrypt at rest** - All secrets encrypted with KMS
- **Enable MFA** - Required for production access
- **Audit access** - CloudTrail + Vault audit logs
- **Use SOPS for files** - Encrypt tfvars, ansible vars
- **Separate KMS keys per environment** - Dev/staging/prod/dr isolation

### ❌ DON'T

- **Never commit plaintext secrets** - Use `.gitignore` for `.tfvars`, `.env` files
- **Never hardcode credentials** - Use Vault/Secrets Manager
- **Never share credentials** - Each user/service has own credentials
- **Never disable encryption** - All state files must use KMS
- **Never use root credentials** - Use IAM roles with least privilege

## 8. Troubleshooting

### Vault Sealed

```bash
# Check status
vault status

# Unseal (requires 3 keys)
vault operator unseal <KEY>
```

### SOPS Decryption Fails

```bash
# Check KMS key access
aws kms describe-key --key-id alias/cloud-infra-prod-terraform-state

# Verify IAM permissions
aws sts get-caller-identity
```

### Secrets Manager Access Denied

```bash
# Check IAM policy
aws iam get-role-policy `
  --role-name cloud-infra-prod-terraform-prod `
  --policy-name cloud-infra-prod-policy

# Verify KMS key policy
aws kms get-key-policy `
  --key-id alias/cloud-infra-prod-secrets `
  --policy-name default
```

### Rotation Failure

```bash
# Check Lambda logs
aws logs tail /aws/lambda/cloud-infra-prod-rotate-rds --follow

# Test Lambda manually
aws lambda invoke `
  --function-name cloud-infra-prod-rotate-rds `
  --payload '{"test": true}' `
  response.json
```

## 9. Compliance

### GDPR / HIPAA / SOC2 / ISO27001

- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS)
- ✅ Access audit logs (CloudTrail)
- ✅ Automatic rotation
- ✅ Least privilege access
- ✅ MFA for sensitive operations
- ✅ Secrets versioning (rollback capability)

## 10. References

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Mozilla SOPS](https://github.com/mozilla/sops)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [AWS KMS](https://docs.aws.amazon.com/kms/)
- [Terraform Vault Provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
