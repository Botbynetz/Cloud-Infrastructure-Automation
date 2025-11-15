# Frequently Asked Questions (FAQ)

## Table of Contents
- [General Questions](#general-questions)
- [Installation & Setup](#installation--setup)
- [Terraform Questions](#terraform-questions)
- [Ansible Questions](#ansible-questions)
- [AWS Questions](#aws-questions)
- [Security Questions](#security-questions)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## General Questions

### What is this project?
This is a production-ready cloud infrastructure automation project that uses Terraform and Ansible to provision and configure AWS resources including VPC, EC2, S3, and monitoring.

### Who is this project for?
- DevOps engineers learning infrastructure as code
- Teams needing a reference architecture for AWS automation
- Developers wanting to understand cloud infrastructure provisioning
- Students learning Terraform and Ansible

### What AWS resources does this project create?
- **Networking**: VPC, Subnets (public/private), Internet Gateway, NAT Gateway, Route Tables
- **Compute**: EC2 instances with web server configuration
- **Storage**: S3 buckets for state and data
- **Database**: DynamoDB for state locking
- **Monitoring**: CloudWatch alarms and metrics
- **Security**: Security Groups, IAM roles, Key Pairs

### How much will this cost on AWS?
Estimated costs (per month):
- **Dev environment**: ~$20-30 (t3.micro instances)
- **Staging environment**: ~$40-60 (t3.small instances)
- **Production environment**: ~$100-150 (t3.medium instances, HA setup)

**Note**: Costs vary by region and usage. Always check AWS Pricing Calculator.

### Is this production-ready?
Yes, with proper configuration:
- ✅ Multi-environment support (dev/staging/prod)
- ✅ Remote state with locking
- ✅ Security best practices
- ✅ Monitoring and alerting
- ✅ Automated testing
- ✅ CI/CD pipeline

**However**, review and customize security settings for your specific use case.

---

## Installation & Setup

### What are the prerequisites?
**Required**:
- Terraform 1.6.0 or higher
- Ansible 2.15.0 or higher
- AWS CLI configured with credentials
- SSH key pair
- Git

**Optional**:
- Go 1.21+ (for Terratest)
- Docker (for containerized workflows)
- jq (for JSON parsing)

### How do I get started quickly?
1. Clone the repository
2. Follow [SETUP.md](../SETUP.md) for detailed instructions
3. Configure AWS credentials
4. Generate SSH keys
5. Initialize Terraform backend
6. Run deployment

**Quick start**: See [SETUP.md](../SETUP.md)

### Do I need an AWS account?
Yes, you need an AWS account with:
- IAM user with programmatic access
- Permissions to create VPC, EC2, S3, DynamoDB, CloudWatch resources
- Billing alerts enabled (recommended)

### Can I use this with other cloud providers?
Currently, this project is AWS-specific. However, the architecture can be adapted:
- Azure: Use Azure provider for Terraform
- GCP: Use Google provider for Terraform
- Multi-cloud: Requires significant refactoring

### How do I configure AWS credentials?
**Method 1: AWS CLI** (Recommended)
```bash
aws configure
```

**Method 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

**Method 3: .env file**
```bash
cp .env.example .env
# Edit .env with your credentials
source .env
```

---

## Terraform Questions

### Where is the Terraform state stored?
- **Backend**: S3 bucket with DynamoDB for locking
- **Location**: `s3://cloud-infra-terraform-state-<account-id>/terraform.tfstate`
- **Locking**: DynamoDB table `cloud-infra-terraform-locks`
- **Encryption**: AES-256 server-side encryption

### How do I initialize Terraform?
```bash
cd terraform
terraform init
```

This will:
- Download provider plugins
- Configure remote backend
- Initialize modules

### How do I switch between environments?
```bash
# Development
terraform workspace select dev
terraform plan -var-file="env/dev.tfvars"

# Staging
terraform workspace select staging
terraform plan -var-file="env/staging.tfvars"

# Production
terraform workspace select production
terraform plan -var-file="env/prod.tfvars"
```

### What if I want to destroy resources?
```bash
terraform destroy -var-file="env/dev.tfvars"
```

**⚠️ WARNING**: This will delete ALL resources. Use with caution!

### Can I customize the infrastructure?
Yes! Modify these files:
- `terraform/modules/`: Module configurations
- `terraform/env/*.tfvars`: Environment-specific values
- `terraform/variables.tf`: Variable definitions

### How do I add new resources?
1. Add resource in appropriate module (`terraform/modules/*/main.tf`)
2. Define variables in `variables.tf`
3. Add outputs in `outputs.tf`
4. Update documentation
5. Test with `terraform plan`
6. Apply with `terraform apply`

---

## Ansible Questions

### What does Ansible do in this project?
Ansible configures EC2 instances after Terraform creates them:
- Install web server (Nginx/Apache)
- Configure security settings
- Deploy application
- Setup monitoring agents

### How do I run Ansible playbooks?
```bash
cd ansible

# Run main playbook
ansible-playbook -i inventory/hosts playbooks/main.yml

# Run specific role
ansible-playbook -i inventory/hosts playbooks/main.yml --tags webserver
```

### How does Ansible know which instances to configure?
- **Dynamic inventory**: Uses AWS EC2 plugin
- **Configuration**: `ansible/inventory/aws_ec2.yml`
- **Filters**: Tags like `Environment=dev`, `Role=webserver`

### Can I use different Ansible roles?
Yes! Add new roles:
```bash
cd ansible/roles
ansible-galaxy init my-new-role
```

Then reference in `playbooks/main.yml`:
```yaml
- hosts: webservers
  roles:
    - my-new-role
```

### How do I test Ansible playbooks?
```bash
# Syntax check
ansible-playbook --syntax-check playbooks/main.yml

# Dry run
ansible-playbook -i inventory/hosts playbooks/main.yml --check

# Run on dev environment
ansible-playbook -i inventory/hosts playbooks/main.yml -l dev
```

---

## AWS Questions

### Which AWS region should I use?
- **Asia Pacific (Singapore)**: `ap-southeast-1` (default)
- **US East (N. Virginia)**: `us-east-1` (cheapest)
- **Europe (Frankfurt)**: `eu-central-1`

Choose based on:
- User location (latency)
- Compliance requirements
- Service availability
- Cost

### How do I change the AWS region?
1. Update `region` in `terraform/env/*.tfvars`
2. Update `AWS_DEFAULT_REGION` in `.env`
3. Re-run `terraform plan` and `terraform apply`

### What IAM permissions do I need?
Minimum required permissions:
- EC2: Full access
- VPC: Full access
- S3: Full access
- DynamoDB: Full access
- CloudWatch: Full access
- IAM: Limited (for roles/policies)

See `docs/iam-policy.json` for detailed policy.

### How do I access EC2 instances?
```bash
# Via SSH
ssh -i ~/.ssh/cloud-infra.pem ubuntu@<public-ip>

# Via AWS Systems Manager Session Manager (no SSH needed)
aws ssm start-session --target <instance-id>
```

### What if I hit AWS service limits?
- Check limits: `aws service-quotas list-service-quotas`
- Request increase: AWS Support or Service Quotas console
- Common limits: EC2 instances, VPC, Elastic IPs

---

## Security Questions

### Is this secure?
Yes, with security best practices:
- ✅ Private subnets for compute
- ✅ Security groups with minimal rules
- ✅ No hardcoded credentials
- ✅ Encrypted S3 state
- ✅ IAM roles instead of keys
- ✅ SSH key-based authentication

**However**, always review and customize security settings!

### How are secrets managed?
- **Never commit secrets**: Use `.gitignore`
- **Environment variables**: For local development
- **AWS Secrets Manager**: For production secrets
- **Terraform variables**: Marked as sensitive

### Should I commit `.tfvars` files?
- ❌ **NO** if they contain sensitive data (credentials, IPs)
- ✅ **YES** if they only contain resource names, sizes, etc.
- ✅ Current setup: Only placeholders (safe to commit)

### How do I rotate SSH keys?
1. Generate new key pair
2. Update `ssh_public_key` in `terraform/env/*.tfvars`
3. Run `terraform apply`
4. Update local SSH config
5. Delete old key from AWS console

### What about AWS credentials rotation?
1. Create new access key in IAM
2. Update local AWS credentials
3. Test new credentials
4. Deactivate old access key
5. Delete old access key after 24-48 hours

---

## Troubleshooting

### Terraform init fails
**Error**: "Backend initialization required"
**Solution**:
```bash
cd terraform
rm -rf .terraform
terraform init -reconfigure
```

### Terraform apply fails with state lock error
**Error**: "Error acquiring the state lock"
**Solution**:
```bash
# Remove lock (use carefully!)
terraform force-unlock <lock-id>
```

### Ansible can't connect to EC2 instances
**Possible causes**:
1. Security group doesn't allow SSH from your IP
2. SSH key path incorrect
3. Instance not fully initialized

**Solutions**:
```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Test SSH manually
ssh -i ~/.ssh/cloud-infra.pem -v ubuntu@<public-ip>

# Check Ansible inventory
ansible-inventory -i inventory/aws_ec2.yml --list
```

### Resources not destroyed completely
**Error**: Dependencies prevent deletion
**Solution**:
```bash
# Find remaining resources
terraform state list

# Remove from state (careful!)
terraform state rm <resource>

# Manual cleanup via AWS console
```

### High AWS costs
**Causes**:
- NAT Gateway ($30-50/month per AZ)
- Running instances 24/7
- Data transfer costs

**Solutions**:
- Use dev environment for testing
- Stop instances when not in use
- Use scheduled scaling
- Review AWS Cost Explorer

### SSH connection timeout
**Causes**:
- Security group not allowing your IP
- Instance in private subnet without bastion
- Network ACL blocking traffic

**Solutions**:
```bash
# Update security group
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s ifconfig.me)/32
```

---

## Best Practices

### Should I use workspaces or separate state files?
**Workspaces** (current approach):
- ✅ Single codebase
- ✅ Easy switching
- ❌ Shared state file

**Separate state files**:
- ✅ Complete isolation
- ✅ Different backends per environment
- ❌ More complex setup

**Recommendation**: Use workspaces for small projects, separate state for production.

### How often should I run terraform plan?
- Before every `terraform apply`
- After modifying `.tf` files
- When reviewing pull requests
- Daily in CI/CD pipeline

### Should I use modules?
**Yes!** Benefits:
- Code reusability
- Consistent configurations
- Easier testing
- Better organization

This project already uses modules in `terraform/modules/`.

### How do I handle sensitive outputs?
```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

View with: `terraform output -json`

### What's the recommended workflow?
1. Create feature branch
2. Make changes
3. Run `terraform fmt`
4. Run `terraform validate`
5. Run `terraform plan`
6. Commit changes
7. Open pull request
8. CI/CD runs tests
9. Review and merge
10. Deploy to dev → staging → prod

---

## Still Have Questions?

- 📖 Check [README.md](../README.md)
- 🛡️ Security: [SECURITY.md](../SECURITY.md)
- 🤝 Contributing: [CONTRIBUTING.md](../CONTRIBUTING.md)
- 💡 Best Practices: [BEST_PRACTICES.md](BEST_PRACTICES.md)
- 🐛 Report Issue: [GitHub Issues](../issues)
- 💬 Discussions: [GitHub Discussions](../discussions)

---

**Last Updated**: 2025-11-15  
**Version**: 1.0.0
