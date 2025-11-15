# Best Practices Guide

This document outlines best practices for managing cloud infrastructure using Terraform and Ansible in this project.

## Table of Contents
- [Terraform Best Practices](#terraform-best-practices)
- [Ansible Best Practices](#ansible-best-practices)
- [AWS Best Practices](#aws-best-practices)
- [Security Best Practices](#security-best-practices)
- [CI/CD Best Practices](#cicd-best-practices)
- [Git Workflow Best Practices](#git-workflow-best-practices)
- [Testing Best Practices](#testing-best-practices)
- [Documentation Best Practices](#documentation-best-practices)

---

## Terraform Best Practices

### 1. Code Organization

#### Use Consistent Directory Structure
```
terraform/
├── modules/          # Reusable modules
│   ├── vpc/
│   ├── ec2/
│   └── s3/
├── env/             # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── main.tf          # Main configuration
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── backend.tf       # Backend configuration
```

#### Module Design
```hcl
# ✅ GOOD: Small, focused modules
module "vpc" {
  source = "./modules/vpc"
  # ...
}

# ❌ BAD: Monolithic modules doing everything
```

### 2. State Management

#### Remote State with Locking
```hcl
# ✅ GOOD: S3 backend with DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### State Best Practices
- ✅ Always use remote state for team projects
- ✅ Enable state encryption
- ✅ Enable state versioning (S3 versioning)
- ✅ Use state locking to prevent concurrent modifications
- ❌ Never commit state files to Git
- ❌ Never manually edit state files

### 3. Variable Management

#### Variable Definitions
```hcl
# ✅ GOOD: Descriptive variables with validation
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Instance type must be t3 family."
  }
}

# ❌ BAD: No description or validation
variable "instance_type" {
  default = "t3.micro"
}
```

#### Sensitive Variables
```hcl
# ✅ GOOD: Mark sensitive variables
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}
```

### 4. Resource Naming

#### Naming Convention
```hcl
# ✅ GOOD: Descriptive names with environment
resource "aws_instance" "web_server_dev" {
  # ...
  tags = {
    Name        = "cloud-infra-web-server-dev"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ❌ BAD: Generic names
resource "aws_instance" "server1" {
  tags = {
    Name = "server"
  }
}
```

#### Tagging Strategy
Always include these tags:
- `Name`: Human-readable name
- `Environment`: dev/staging/prod
- `ManagedBy`: terraform
- `Project`: cloud-infra
- `Owner`: team/person responsible
- `CostCenter`: for billing

### 5. Code Quality

#### Formatting and Validation
```bash
# Always format before committing
terraform fmt -recursive

# Validate configuration
terraform validate

# Check for security issues (using tfsec)
tfsec .
```

#### Use Data Sources
```hcl
# ✅ GOOD: Use data sources for existing resources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ❌ BAD: Hardcode AMI IDs (changes per region)
```

### 6. Terraform Workflow

#### Development Workflow
```bash
# 1. Format code
terraform fmt

# 2. Initialize (if new/changed modules)
terraform init

# 3. Validate syntax
terraform validate

# 4. Plan changes
terraform plan -var-file="env/dev.tfvars" -out=tfplan

# 5. Review plan carefully
# 6. Apply if plan looks good
terraform apply tfplan

# 7. Verify changes
terraform show
```

#### Using Workspaces
```bash
# Create workspace
terraform workspace new dev

# Switch workspace
terraform workspace select dev

# List workspaces
terraform workspace list

# Current workspace
terraform workspace show
```

---

## Ansible Best Practices

### 1. Playbook Organization

#### Directory Structure
```
ansible/
├── inventory/           # Inventory files
│   ├── hosts
│   └── aws_ec2.yml     # Dynamic inventory
├── playbooks/          # Playbooks
│   ├── main.yml
│   ├── webserver.yml
│   └── monitoring.yml
├── roles/              # Roles
│   ├── common/
│   ├── webserver/
│   └── monitoring/
├── group_vars/         # Group variables
├── host_vars/          # Host variables
└── ansible.cfg         # Ansible configuration
```

#### Playbook Structure
```yaml
# ✅ GOOD: Well-structured playbook
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars_files:
    - vars/main.yml
  
  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
  
  roles:
    - common
    - webserver
  
  post_tasks:
    - name: Verify service is running
      service:
        name: nginx
        state: started
```

### 2. Idempotency

```yaml
# ✅ GOOD: Idempotent tasks
- name: Ensure nginx is installed
  apt:
    name: nginx
    state: present

# ❌ BAD: Not idempotent
- name: Install nginx
  shell: apt-get install nginx
```

### 3. Variable Management

#### Variable Precedence
1. Extra vars (`-e` on command line)
2. Task vars
3. Block vars
4. Role vars
5. Play vars
6. Host vars
7. Group vars
8. Default vars (in roles)

#### Best Practices
```yaml
# ✅ GOOD: Use descriptive variable names
webserver_port: 80
webserver_document_root: /var/www/html

# ❌ BAD: Generic names
port: 80
root: /var/www
```

### 4. Error Handling

```yaml
# ✅ GOOD: Proper error handling
- name: Download application
  get_url:
    url: "{{ app_url }}"
    dest: /tmp/app.tar.gz
  register: download_result
  failed_when: download_result.status_code != 200
  retries: 3
  delay: 5

# Handle failure
- name: Clean up on failure
  file:
    path: /tmp/app.tar.gz
    state: absent
  when: download_result is failed
```

### 5. Security

```yaml
# ✅ GOOD: Use vault for secrets
- name: Set database password
  mysql_user:
    name: appuser
    password: "{{ db_password }}"  # From vault
    state: present
  no_log: true

# Encrypt with ansible-vault
ansible-vault encrypt vars/secrets.yml
```

### 6. Performance

#### Use Handlers
```yaml
# ✅ GOOD: Use handlers for service restarts
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: restart nginx

handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

#### Parallelism
```yaml
# Increase parallel execution
ansible-playbook -i inventory playbook.yml -f 10
```

---

## AWS Best Practices

### 1. Multi-Account Strategy

#### Account Structure
- **Management Account**: Billing and organization
- **Dev Account**: Development and testing
- **Staging Account**: Pre-production
- **Prod Account**: Production workloads

### 2. Network Architecture

#### VPC Design
```
Production VPC (10.0.0.0/16)
├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
│   └── NAT Gateway, Load Balancers
├── Private Subnets (10.0.11.0/24, 10.0.12.0/24)
│   └── Application Servers
└── Database Subnets (10.0.21.0/24, 10.0.22.0/24)
    └── RDS, ElastiCache
```

#### Best Practices
- ✅ Use at least 2 Availability Zones
- ✅ Separate public and private subnets
- ✅ Use NAT Gateway for private subnet internet access
- ✅ Implement Network ACLs as additional security layer
- ✅ Enable VPC Flow Logs

### 3. Security Groups

```hcl
# ✅ GOOD: Specific rules with descriptions
resource "aws_security_group" "web" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  
  ingress {
    description = "HTTP from Load Balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ❌ BAD: Open to world
ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### 4. IAM Policies

#### Least Privilege Principle
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

#### Use IAM Roles
- ✅ Use IAM roles for EC2 instances (not access keys)
- ✅ Enable MFA for human users
- ✅ Rotate credentials regularly
- ✅ Use AWS SSO for team access

### 5. Cost Optimization

#### Strategies
- ✅ Use Reserved Instances for stable workloads
- ✅ Use Spot Instances for fault-tolerant workloads
- ✅ Enable Auto Scaling
- ✅ Right-size instances based on metrics
- ✅ Use S3 lifecycle policies
- ✅ Delete unused EBS volumes and snapshots
- ✅ Review AWS Cost Explorer monthly

#### Tagging for Cost Allocation
```hcl
tags = {
  CostCenter  = "engineering"
  Project     = "cloud-infra"
  Environment = "prod"
}
```

### 6. Monitoring & Logging

#### CloudWatch
```hcl
# ✅ GOOD: Comprehensive alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "web-server-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

#### Enable Logging
- ✅ CloudTrail for API audit logs
- ✅ VPC Flow Logs for network traffic
- ✅ S3 access logs
- ✅ CloudWatch Logs for applications
- ✅ Set up log retention policies

---

## Security Best Practices

### 1. Secrets Management

#### Never Hardcode Secrets
```hcl
# ❌ BAD: Hardcoded secrets
resource "aws_db_instance" "main" {
  password = "MyPassword123!"
}

# ✅ GOOD: Use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_pass" {
  secret_id = "db-password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_pass.secret_string
}
```

### 2. Encryption

#### Encrypt Everything
- ✅ EBS volumes: Enable encryption
- ✅ S3 buckets: Enable default encryption
- ✅ RDS: Enable encryption at rest
- ✅ Data in transit: Use TLS/SSL

```hcl
# ✅ GOOD: Encrypted S3 bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-encrypted-bucket"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

### 3. Access Control

#### Principle of Least Privilege
- ✅ Grant minimum required permissions
- ✅ Use IAM roles instead of access keys
- ✅ Implement MFA for sensitive operations
- ✅ Regularly audit IAM policies
- ✅ Use AWS Organizations SCPs

### 4. Network Security

#### Defense in Depth
- ✅ Security Groups (stateful firewall)
- ✅ Network ACLs (stateless firewall)
- ✅ AWS WAF for web applications
- ✅ AWS Shield for DDoS protection
- ✅ VPC endpoints for AWS services (no internet routing)

### 5. Compliance & Auditing

#### Enable Auditing
```bash
# Enable CloudTrail
aws cloudtrail create-trail --name my-trail \
  --s3-bucket-name my-trail-bucket \
  --is-multi-region-trail

# Enable Config
aws configservice put-configuration-recorder \
  --configuration-recorder name=default \
  --recording-group allSupported=true

# Enable GuardDuty
aws guardduty create-detector --enable
```

---

## CI/CD Best Practices

### 1. Pipeline Stages

#### Complete Pipeline
```yaml
stages:
  - lint          # Code formatting, syntax check
  - validate      # Terraform validate
  - security      # Security scanning (tfsec, checkov)
  - test          # Unit tests, integration tests
  - plan          # Terraform plan
  - deploy        # Terraform apply (manual approval for prod)
  - verify        # Post-deployment tests
```

### 2. Environment Promotion

#### Deployment Flow
```
Feature Branch → Dev → Staging → Production
                 ↓       ↓         ↓
              Auto   Auto    Manual Approval
```

### 3. Automated Testing

```bash
# Run tests in CI/CD
terraform fmt -check
terraform validate
tfsec .
terratest tests/
ansible-playbook --syntax-check playbooks/*.yml
```

### 4. Deployment Safety

#### Use Approval Gates
```yaml
# GitHub Actions example
jobs:
  deploy-prod:
    environment:
      name: production
      url: https://prod.example.com
    needs: deploy-staging
    # Manual approval required
```

#### Rollback Strategy
- ✅ Keep previous Terraform state
- ✅ Tag infrastructure versions
- ✅ Test rollback procedures
- ✅ Have runbook for emergency rollback

---

## Git Workflow Best Practices

### 1. Branching Strategy

#### GitFlow
```
main (production)
├── develop
│   ├── feature/vpc-enhancement
│   ├── feature/monitoring-setup
│   └── feature/auto-scaling
├── release/v1.1.0
└── hotfix/critical-security-fix
```

### 2. Commit Messages

#### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Examples
```bash
# ✅ GOOD
feat(vpc): add NAT gateway for private subnets

- Added NAT gateway in each AZ
- Updated route tables for private subnets
- Added CloudWatch alarms for NAT gateway

Closes #123

# ❌ BAD
fix stuff
```

### 3. Pull Requests

#### PR Checklist
- [ ] Code formatted (`terraform fmt`)
- [ ] Code validated (`terraform validate`)
- [ ] Tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Security scan passed
- [ ] Peer reviewed

---

## Testing Best Practices

### 1. Testing Pyramid

```
        E2E Tests (few)
     Integration Tests (some)
   Unit Tests (many)
Static Analysis (always)
```

### 2. Terraform Testing

#### Static Analysis
```bash
# Format check
terraform fmt -check

# Validation
terraform validate

# Security scanning
tfsec .
checkov -d .

# Cost estimation
infracost breakdown --path .
```

#### Unit Tests (Terratest)
```go
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_cidr": "10.0.0.0/16",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

### 3. Ansible Testing

```bash
# Syntax check
ansible-playbook --syntax-check playbooks/main.yml

# Dry run
ansible-playbook --check playbooks/main.yml

# Molecule testing (advanced)
molecule test
```

---

## Documentation Best Practices

### 1. Code Documentation

#### Terraform Comments
```hcl
# Create VPC for production environment
# CIDR block allows for 65,536 IP addresses
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for RDS
  
  tags = {
    Name = "production-vpc"
  }
}
```

### 2. README Structure

#### Essential Sections
- Overview
- Architecture diagram
- Prerequisites
- Quick start
- Configuration
- Deployment
- Monitoring
- Troubleshooting
- Contributing
- License

### 3. Keep Documentation Updated

#### Documentation as Code
- Update docs in same PR as code changes
- Use terraform-docs to auto-generate module docs
- Keep architecture diagrams up to date
- Document all manual steps

```bash
# Auto-generate Terraform docs
terraform-docs markdown table . > README.md
```

---

## Additional Resources

### Official Documentation
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Security
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [OWASP Cloud Security](https://owasp.org/www-project-cloud-security/)

### Tools
- [tfsec](https://github.com/aquasecurity/tfsec) - Terraform security scanner
- [checkov](https://www.checkov.io/) - Infrastructure as code scanner
- [terratest](https://terratest.gruntwork.io/) - Go testing framework
- [infracost](https://www.infracost.io/) - Cost estimation

---

**Last Updated**: 2025-11-15  
**Version**: 1.0.0
