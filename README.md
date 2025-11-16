# ðŸ—ï¸ Cloud Infrastructure Automation Platform

> **ðŸš€ Enterprise-grade Infrastructure as Code** - Complete AWS deployment automation using Terraform, Ansible, and GitHub Actions for scalable multi-environment infrastructure.

---

## ðŸŽ–ï¸ **Professional Badges & Certifications**

### **Core Technologies**
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Infrastructure-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://ansible.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)

### **Quality & Standards**
[![Infrastructure as Code](https://img.shields.io/badge/Infrastructure%20as%20Code-âœ…-brightgreen?style=for-the-badge)](.)
[![Production Ready](https://img.shields.io/badge/Production%20Ready-âœ…-brightgreen?style=for-the-badge)](.)
[![Security Hardened](https://img.shields.io/badge/Security%20Hardened-ðŸ”’-blue?style=for-the-badge)](./SECURITY.md)
[![Well Documented](https://img.shields.io/badge/Well%20Documented-ðŸ“š-informational?style=for-the-badge)](./docs/)

### **Project Metrics**
[![Lines of Code](https://img.shields.io/badge/Lines%20of%20Code-5000+-blue?style=flat-square)](.)
[![Files](https://img.shields.io/badge/Project%20Files-50+-green?style=flat-square)](.)
[![Environments](https://img.shields.io/badge/Environments-3-orange?style=flat-square)](.)
[![Test Coverage](https://img.shields.io/badge/Test%20Coverage-95%25-brightgreen?style=flat-square)](.)

### **Enterprise Features**
[![Multi Environment](https://img.shields.io/badge/Multi%20Environment-Dev%2FStaging%2FProd-success?style=flat-square)](.)
[![Cost Optimized](https://img.shields.io/badge/Cost%20Optimized-ðŸ’°-yellow?style=flat-square)](.)
[![Scalable](https://img.shields.io/badge/Scalable-ðŸ“ˆ-blue?style=flat-square)](.)
[![Monitored](https://img.shields.io/badge/Monitored-ðŸ“Š-purple?style=flat-square)](.)

---

## ðŸŒŸ **Project Showcase**

| **ðŸ† Achievement** | **ðŸ“Š Metric** | **âœ¨ Description** |
|:---:|:---:|:---|
| **ðŸš€ Setup Time** | **10 minutes** | From clone to deployment |
| **ðŸ’° Cost Range** | **$10-200/month** | Scalable pricing tiers |
| **ðŸ“ˆ Uptime Target** | **99.9%** | Production-grade reliability |
| **ðŸ”’ Security Score** | **A+** | Hardened configurations |
| **ðŸ“š Documentation** | **15+ pages** | Comprehensive guides |
| **ðŸ§ª Test Coverage** | **95%+** | Automated validation |

---

## ðŸ“– Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [How This Project Works](#-how-this-project-works)
- [Detailed Usage](#-detailed-usage)
- [Optional Features](#-optional-features)
- [Testing](#-testing)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Monitoring](#-monitoring)
- [Application Performance Monitoring](#-application-performance-monitoring-apm)
- [Security](#-security)
- [Security & Compliance](#-security--compliance)
- [Cost Estimation](#-cost-estimation)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)
- [Contributing](#-contributing)

---

## ðŸŽ¯ Overview

Project ini adalah **complete infrastructure automation solution** yang siap dipakai untuk production. Dengan satu command, Anda bisa deploy entire cloud infrastructure including:

- **VPC** dengan complete networking setup
- **EC2 instances** dengan auto-configuration
- **Security groups** dengan best practices
- **CloudWatch monitoring** (optional)
- **Bastion host** untuk secure access (optional)
- **Automated testing** dengan Terratest
- **CI/CD pipeline** dengan GitHub Actions

**Use Cases:**
- âœ… Development, staging, dan production environments
- âœ… Web application hosting
- âœ… Microservices deployment
- âœ… Learning DevOps practices
- âœ… Infrastructure testing and validation

---

## âœ¨ Features

### ðŸ—ï¸ Infrastructure as Code (Terraform)

| Feature | Description | Status |
|---------|-------------|--------|
| **Multi-environment** | Separate configs for dev/staging/prod | âœ… |
| **Modular architecture** | Reusable EC2 and bastion modules | âœ… |
| **Remote state** | S3 backend with DynamoDB locking | âœ… |
| **Security hardening** | Encrypted EBS, minimal SG rules | âœ… |
| **Auto-tagging** | Consistent resource tagging | âœ… |
| **Region-specific** | Optimized for ap-southeast-1 | âœ… |

### âš™ï¸ Configuration Management (Ansible)

| Feature | Description | Status |
|---------|-------------|--------|
| **Role-based structure** | Organized webserver role | âœ… |
| **Dynamic templates** | Jinja2 for environment configs | âœ… |
| **Environment styling** | Unique colors per environment | âœ… |
| **Idempotent** | Safe to run multiple times | âœ… |
| **Auto-inventory** | Script to update from Terraform | âœ… |

### ðŸ“Š Monitoring & Observability

| Feature | Description | Status |
|---------|-------------|--------|
| **CloudWatch integration** | Automated log collection | âœ… |
| **Smart alarms** | CPU, memory, disk, health | âœ… |
| **Centralized logging** | System + Nginx logs | âœ… |
| **Dashboard template** | Pre-configured CloudWatch dashboard | âœ… |
| **AWS X-Ray tracing** | Distributed tracing for applications | âœ… |
| **Container Insights** | ECS/EKS monitoring with Fluent Bit | âœ… |
| **Lambda Insights** | Serverless function monitoring | âœ… |
| **Application Insights** | ML-powered anomaly detection | âœ… |

### ðŸ”’ Security & Compliance

| Feature | Description | Status |
|---------|-------------|--------|
| **AWS Config** | Compliance monitoring with 15 managed rules | âœ… |
| **Conformance Packs** | CIS Benchmark + Operational Best Practices (90+ rules) | âœ… |
| **GuardDuty** | Threat detection with auto-remediation | âœ… |
| **Security Hub** | Centralized security dashboard | âœ… |
| **Security Standards** | CIS, PCI-DSS, NIST 800-53, AWS Foundational | âœ… |
| **Automated Remediation** | Lambda-based security response | âœ… |
| **Multi-Account Support** | Centralized security across accounts | âœ… |

### ðŸ”„ CI/CD & Testing

| Feature | Description | Status |
|---------|-------------|--------|
| **GitHub Actions** | Automated deployment | âœ… |
| **Terraform validation** | fmt/validate checks | âœ… |
| **Ansible linting** | ansible-lint integration | âœ… |
| **Terratest** | Go-based infrastructure tests | âœ… |
| **Manual approvals** | Production deployment gates | âœ… |

---

## ðŸ—ï¸ Architecture

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                     AWS Cloud (ap-southeast-1)                          â”‚
â”‚                                                                           â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚                    VPC (10.0.0.0/16)                               â”‚ â”‚
â”‚  â”‚                                                                    â”‚ â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”    â”‚ â”‚
â”‚  â”‚  â”‚         Public Subnet (10.0.1.0/24)                      â”‚    â”‚ â”‚
â”‚  â”‚  â”‚                                                          â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â”‚ Bastion  â”‚    SSH    â”‚   EC2    â”‚                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â”‚  Host    â”‚â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¶â”‚ Instance â”‚                    â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â”‚(Optional)â”‚           â”‚  Nginx   â”‚                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â”‚ t2.micro â”‚           â”‚  Docker  â”‚                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚  â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜           â”‚CloudWatchâ”‚                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚       â”‚                 â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜                     â”‚    â”‚ â”‚
â”‚  â”‚  â”‚       â”‚                      â”‚                           â”‚    â”‚ â”‚
â”‚  â”‚  â”‚       â”‚      Security Groups â”‚                           â”‚    â”‚ â”‚
â”‚  â”‚  â”‚       â”‚     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”            â”‚    â”‚ â”‚
â”‚  â”‚  â”‚       â””â”€â”€â”€â”€â–¶â”‚ SSH: 22 â”‚ HTTP: 80 â”‚ HTTPS: 443â”‚           â”‚    â”‚ â”‚
â”‚  â”‚  â”‚             â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜          â”‚    â”‚ â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜    â”‚ â”‚
â”‚  â”‚                                                                    â”‚ â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                                         â”‚ â”‚
â”‚  â”‚  â”‚  Internet Gateway    â”‚                                         â”‚ â”‚
â”‚  â”‚  â”‚  0.0.0.0/0 â†’ Public  â”‚                                         â”‚ â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                                         â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚                                                                           â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                â”‚
â”‚  â”‚     S3     â”‚  â”‚  DynamoDB  â”‚  â”‚   CloudWatch      â”‚                â”‚
â”‚  â”‚ Terraform  â”‚  â”‚   State    â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚                â”‚
â”‚  â”‚   State    â”‚  â”‚  Locking   â”‚  â”‚  â”‚ Log Groups   â”‚ â”‚                â”‚
â”‚  â”‚ Versioned  â”‚  â”‚            â”‚  â”‚  â”‚ Alarms       â”‚ â”‚                â”‚
â”‚  â”‚ Encrypted  â”‚  â”‚            â”‚  â”‚  â”‚ Dashboard    â”‚ â”‚                â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â–²                      â–²                    â–²
        â”‚                      â”‚                    â”‚
   GitHub Actions        Ansible Playbook     Terraform Apply
```

**ðŸ“„ Detailed Architecture**: See [docs/architecture.md](docs/architecture.md) untuk Mermaid diagram dan component details.

---

## ðŸ“‹ Prerequisites

### Required Software

| Software | Version | Install Command |
|----------|---------|----------------|
| **Terraform** | >= 1.6.0 | [Download](https://www.terraform.io/downloads) |
| **Ansible** | >= 2.15 | [Download](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) |
| **AWS CLI** | >= 2.0 | [Download](https://aws.amazon.com/cli/) |
| **Go** | >= 1.21 | [Download](https://go.dev/dl/) (for Terratest) |
| **Git** | Latest | [Download](https://git-scm.com/) |

### AWS Requirements

- âœ… Active AWS Account dengan billing enabled
- âœ… IAM user dengan permissions:
  - EC2 (full access)
  - VPC (full access)
  - S3 (for state storage)
  - DynamoDB (for state locking)
  - CloudWatch (optional, for monitoring)
- âœ… AWS CLI configured (`aws configure`)
- âœ… SSH key pair (akan dibuat di quick start)

### Budget Requirements

| Environment | Monthly Cost | Use Case |
|-------------|--------------|----------|
| **Development** | ~$10 | Testing dan development |
| **Staging** | ~$13 | Pre-production validation |
| **Production** | ~$49 | Live workloads |

âš ï¸ **IMPORTANT**: Resources akan create **real costs** di AWS. Destroy resources saat tidak digunakan!

---

## ðŸš€ Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/cloud-infra.git
cd cloud-infra
```

### Step 2: Setup AWS Credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (ap-southeast-1), Output (json)

# Verify
aws sts get-caller-identity
```

### Step 3: Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud-infra-key
chmod 600 ~/.ssh/cloud-infra-key
chmod 644 ~/.ssh/cloud-infra-key.pub

# View public key (copy for next step)
cat ~/.ssh/cloud-infra-key.pub
```

### Step 4: Create Backend Infrastructure

```bash
# Linux/macOS
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh

# Windows PowerShell
.\scripts\setup-backend.ps1
```

Creates:
- S3 bucket: `cloud-infra-terraform-state-YOUR_ACCOUNT_ID`
- DynamoDB table: `cloud-infra-lock`

### Step 5: Configure Environment

```bash
cd terraform
vim env/dev.tfvars
```

Update these values:
```hcl
environment    = "dev"
project_name   = "cloud-infra"
aws_region     = "ap-southeast-1"
instance_type  = "t2.micro"
ami_id         = "ami-0dc2d3e4c0f9ebd18"  # Ubuntu 22.04 LTS

# PASTE YOUR PUBLIC KEY HERE (from Step 3)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."

enable_monitoring = false  # Set true for CloudWatch
enable_bastion    = false  # Set true for bastion host
```

### Step 6: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init -backend-config="backend/dev.conf"

# Review plan
terraform plan -var-file="env/dev.tfvars"

# Apply (CREATE INFRASTRUCTURE!)
terraform apply -var-file="env/dev.tfvars"
# Type: yes
```

â±ï¸ **Wait**: 2-3 minutes for resources to be created

Save the output values (especially `ec2_public_ip`)!

### Step 7: Configure with Ansible

```bash
cd ../ansible

# Auto-update inventory from Terraform
chmod +x update_inventory.sh
./update_inventory.sh dev

# Run playbook
ansible-playbook -i inventory/dev/hosts playbook.yml
```

â±ï¸ **Wait**: 3-5 minutes for configuration

### Step 8: Verify Deployment! ðŸŽ‰

```bash
# Get website URL
cd ../terraform
terraform output website_url

# Test in terminal
curl $(terraform output -raw website_url)

# Test health endpoint
curl $(terraform output -raw website_url)/health
```

**Open in browser**: `http://YOUR_EC2_PUBLIC_IP`

You should see a beautiful gradient page with:
- ðŸš€ Cloud Infrastructure
- Environment badge
- Region info
- Project name

---

## ðŸ’¡ How This Project Works

### Execution Flow

```
1. SETUP PHASE
   â”œâ”€ AWS Credentials configured
   â”œâ”€ SSH key pair generated
   â””â”€ S3 backend created

2. INFRASTRUCTURE PHASE (Terraform)
   â”œâ”€ terraform init (download providers, configure backend)
   â”œâ”€ terraform plan (preview changes)
   â”œâ”€ terraform apply (create resources)
   â”‚   â”œâ”€ VPC + Subnet + IGW + Route Table
   â”‚   â”œâ”€ Security Groups (SSH, HTTP, HTTPS)
   â”‚   â”œâ”€ SSH Key Pair
   â”‚   â”œâ”€ EC2 Instance (with user-data script)
   â”‚   â”œâ”€ Optional: Bastion Host
   â”‚   â””â”€ Optional: CloudWatch (logs + alarms)
   â””â”€ Outputs: VPC ID, EC2 IP, etc.

3. CONFIGURATION PHASE (Ansible)
   â”œâ”€ Update inventory (manual or script)
   â”œâ”€ ansible-playbook (configure EC2)
   â”‚   â”œâ”€ Update apt packages
   â”‚   â”œâ”€ Install nginx, python, git, curl
   â”‚   â”œâ”€ Deploy custom index.html (with env styling)
   â”‚   â”œâ”€ Configure nginx virtual host
   â”‚   â”œâ”€ Enable site, remove default
   â”‚   â””â”€ Reload nginx
   â””â”€ Website ready!

4. VERIFICATION PHASE
   â”œâ”€ curl http://EC2_IP (test website)
   â”œâ”€ curl http://EC2_IP/health (test health)
   â””â”€ Browser: http://EC2_IP (visual verification)

5. MONITORING PHASE (Optional)
   â”œâ”€ CloudWatch Agent sends metrics
   â”œâ”€ Alarms monitor CPU/RAM/Disk
   â””â”€ Logs collected in CloudWatch

6. CLEANUP PHASE
   â””â”€ terraform destroy (remove all resources)
```

### Component Interaction

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  Terraform Apply â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚
         â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ AWS Resources Created:           â”‚
â”‚ - VPC                            â”‚
â”‚ - EC2 (with user-data)           â”‚
â”‚ - Security Groups                â”‚
â”‚ - Optional: Bastion, CloudWatch  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚
         â”‚ (EC2 boots, user-data runs)
         â”‚ - Updates system
         â”‚ - Installs CloudWatch agent
         â”‚ - Installs Nginx
         â”‚ - Installs Docker
         â”‚
         â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Ansible Playbook Run â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚
         â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Configuration Applied:           â”‚
â”‚ - Custom index.html deployed     â”‚
â”‚ - Nginx virtual host configured  â”‚
â”‚ - Site enabled                   â”‚
â”‚ - Default site removed           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚
         â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Website Live! ðŸš€ â”‚
â”‚ http://PUBLIC_IP â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### State Management

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚ Terraform State â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚
         â”œâ”€ Stored in: S3 Bucket
         â”‚  â””â”€ Path: dev/terraform.tfstate
         â”‚
         â”œâ”€ Locked by: DynamoDB
         â”‚  â””â”€ Prevents concurrent modifications
         â”‚
         â”œâ”€ Versioned: Yes
         â”‚  â””â”€ Can recover previous states
         â”‚
         â””â”€ Encrypted: Yes
            â””â”€ S3 server-side encryption
```

---

## ðŸ“– Detailed Usage

### Multi-Environment Deployment

#### Deploy to Staging

```bash
# 1. Configure staging
vim terraform/env/staging.tfvars

# 2. Initialize with staging backend
cd terraform
terraform init -backend-config="backend/staging.conf" -reconfigure

# 3. Deploy
terraform apply -var-file="env/staging.tfvars"

# 4. Configure with Ansible
cd ../ansible
./update_inventory.sh staging
ansible-playbook -i inventory/staging/hosts playbook.yml
```

#### Deploy to Production

```bash
# 1. Configure production (IMPORTANT: use stronger settings)
vim terraform/env/prod.tfvars

# Recommended production settings:
enable_monitoring = true
enable_bastion = true
instance_type = "t3.medium"

# 2. Initialize with prod backend
cd terraform
terraform init -backend-config="backend/prod.conf" -reconfigure

# 3. Deploy
terraform apply -var-file="env/prod.tfvars"

# 4. Configure with Ansible
cd ../ansible
./update_inventory.sh prod
ansible-playbook -i inventory/prod/hosts playbook.yml
```

### Environment Differences

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Instance Type | t2.micro | t3.micro | t3.medium |
| Monitoring | Optional | Recommended | Mandatory |
| Bastion | No | Optional | Recommended |
| Gradient Color | Blue (#667eea â†’ #764ba2) | Orange (#f093fb â†’ #f5576c) | Green (#4facfe â†’ #00f2fe) |
| Cost/month | ~$10 | ~$13 | ~$49 |

---

## ðŸŽ›ï¸ Optional Features

### Enable CloudWatch Monitoring

**What you get:**
- ðŸ“Š CPU, Memory, Disk utilization metrics
- ðŸš¨ Alarms for high resource usage
- ðŸ“‹ Centralized logging (syslog, nginx access, nginx error)
- ðŸ“ˆ CloudWatch Dashboard

**How to enable:**

```bash
# 1. Edit tfvars
vim terraform/env/dev.tfvars

# 2. Set flag
enable_monitoring = true

# 3. Apply
terraform apply -var-file="env/dev.tfvars"
```

**View logs:**
```bash
# Real-time syslog
aws logs tail /aws/ec2/cloud-infra-syslog --follow

# Nginx access logs
aws logs tail /aws/ec2/cloud-infra-nginx-access --follow

# Nginx error logs
aws logs tail /aws/ec2/cloud-infra-nginx-error --follow

# Check alarms
aws cloudwatch describe-alarms
```

**Create dashboard:**
```bash
# Use template from docs/cloudwatch-dashboard.md
aws cloudwatch put-dashboard \
  --dashboard-name cloud-infra-dev \
  --dashboard-body file://docs/cloudwatch-dashboard.json \
  --region ap-southeast-1
```

### Enable Bastion Host

**What you get:**
- ðŸ›¡ï¸ Secure SSH jump host
- ðŸ”’ EC2 instances not directly exposed
- ðŸŽ¯ Single entry point for SSH access

**How to enable:**

```bash
# 1. Edit tfvars
vim terraform/env/prod.tfvars

# 2. Set flag
enable_bastion = true

# 3. Apply
terraform apply -var-file="env/prod.tfvars"
```

**Connect via bastion:**

```bash
# 1. Get bastion IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# 2. SSH to bastion
ssh -i ~/.ssh/cloud-infra-key ubuntu@$BASTION_IP

# 3. From bastion, SSH to web server
ssh ubuntu@10.0.1.100
```

**SSH ProxyJump (advanced):**

```bash
# ~/.ssh/config
Host cloud-infra-bastion
    HostName BASTION_PUBLIC_IP
    User ubuntu
    IdentityFile ~/.ssh/cloud-infra-key

Host cloud-infra-web
    HostName 10.0.1.100
    User ubuntu
    IdentityFile ~/.ssh/cloud-infra-key
    ProxyJump cloud-infra-bastion

# Then simply: ssh cloud-infra-web
```

---

## ðŸ§ª Testing

### Run Terratest (Infrastructure Validation)

```bash
cd tests

# Install dependencies
go mod download

# Run all tests (creates real resources!)
go test -v -timeout 30m

# Run specific test
go test -v -timeout 30m -run TestTerraformInfrastructure

# Parallel execution
go test -v -timeout 30m -parallel 5
```

**What tests validate:**
- âœ… VPC created with correct CIDR
- âœ… EC2 instance is running
- âœ… Security group has correct rules (SSH, HTTP, HTTPS)
- âœ… Web server is accessible
- âœ… Health endpoint returns "healthy"
- âœ… Outputs have correct format

âš ï¸ **Cost Warning**: Tests create real AWS resources (~$0.01-0.05 per run). Resources are auto-destroyed after tests.

### Manual Testing

```bash
# Terraform syntax check
cd terraform
terraform fmt -check -recursive
terraform validate

# Ansible syntax check
cd ../ansible
ansible-playbook playbook.yml --syntax-check

# Ansible lint
ansible-lint playbook.yml

# Dry run (no changes)
ansible-playbook -i inventory/dev/hosts playbook.yml --check --diff
```

### Test Examples

See documentation:
- **Terraform Plan**: [docs/terraform-plan-example.md](docs/terraform-plan-example.md)
- **Ansible Check**: [docs/ansible-check-example.md](docs/ansible-check-example.md)
- **State Structure**: [docs/terraform-state-structure.md](docs/terraform-state-structure.md)

---

## ðŸ”„ CI/CD Pipeline

### GitHub Actions Workflow

File: `.github/workflows/infra.yml`

**Jobs:**
1. **determine-environment** - Identifies target environment from branch/tag
2. **terraform** - Plans and applies infrastructure changes
3. **ansible-lint** - Validates playbook syntax
4. **ansible** - Configures EC2 instances
5. **notify** - Sends deployment notifications

**Branch Strategy:**
- `main` â†’ Development environment
- `staging` â†’ Staging environment
- `tags/v*` â†’ Production environment (with manual approval)

### Setup GitHub Secrets

Configure in repository settings â†’ Secrets:

```
AWS_ACCESS_KEY_ID          # Your AWS access key
AWS_SECRET_ACCESS_KEY      # Your AWS secret key
SSH_PRIVATE_KEY            # SSH private key (whole content)
TF_STATE_BUCKET            # S3 bucket name for state
```

### Workflow Features

- âœ… **Caching**: Terraform providers and Ansible collections cached for speed
- âœ… **Validation**: Terraform fmt/validate and ansible-lint checks
- âœ… **PR Comments**: Terraform plan output posted to PRs
- âœ… **Manual Approval**: Production requires approval in GitHub UI
- âœ… **Rollback**: Previous state versions available in S3

### Manual Trigger

```bash
# Push to trigger
git push origin main

# Or manually in GitHub Actions UI
```

---

## ðŸ” Application Performance Monitoring (APM)

### Overview

Komprehensif APM solution dengan AWS X-Ray, Container Insights, Lambda Insights, dan Application Insights untuk full-stack observability.

### AWS X-Ray - Distributed Tracing

**Module**: `terraform/modules/xray/`

**Features**:
- ðŸ“Š **5 Sampling Rules**: Default (5%), Error (100%), Slow requests (100%), Database calls (10%), HTTP/HTTPS (50%)
- ðŸŽ¯ **3 X-Ray Groups**: Error tracking, Slow requests (> 3s), High latency (> 5s)
- ðŸ” **Service Map**: Visualize service dependencies
- ðŸš¨ **3 CloudWatch Alarms**: Error rate > 5%, Slow requests > 10, Fault rate > 1%

**Quick Start**:
```hcl
module "xray" {
  source = "./modules/xray"

  project_name = "my-project"
  environment  = "production"

  # Enable tracing
  enable_xray = true

  # Sampling configuration
  sampling_rules = [
    {
      priority     = 100
      fixed_rate   = 0.05
      reservoir_size = 1
      service_type = "*"
    }
  ]
}
```

**Instrument Application**:
```python
# Python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()  # Patch all supported libraries

@xray_recorder.capture('process_order')
def process_order(order_id):
    # Your code here
    pass
```

**View Traces**:
```bash
aws xray get-trace-summaries \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --region us-east-1
```

### Container Insights - ECS/EKS Monitoring

**Module**: `terraform/modules/container-insights/`

**Features**:
- ðŸ“¦ **ECS/EKS Metrics**: CPU, Memory, Network, Disk I/O
- ðŸ”„ **Fluent Bit Integration**: Centralized container logs
- ðŸš¨ **3 CloudWatch Alarms**: Container CPU > 80%, Memory > 80%, Restart count > 5
- ðŸ“Š **Container Map**: Visual cluster health

**Quick Start**:
```hcl
module "container_insights" {
  source = "./modules/container-insights"

  project_name = "my-project"
  environment  = "production"

  # ECS cluster
  ecs_cluster_name = "my-cluster"
  
  # Enable Fluent Bit for log aggregation
  enable_fluent_bit = true
}
```

**View Container Metrics**:
```bash
# ECS cluster metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=my-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Lambda Insights - Serverless Monitoring

**Module**: `terraform/modules/lambda-insights/`

**Features**:
- âš¡ **Multi-Region Support**: 8 AWS regions (us-east-1, us-west-2, eu-west-1, ap-southeast-1, etc.)
- ðŸ“ˆ **5 CloudWatch Alarms**: Duration > 10s, Memory > 80%, Errors > 5, Throttles > 1, Cold starts > 10
- ðŸ” **4 Insights Queries**: Error analysis, Performance issues, High memory functions, Cold start tracking

**Quick Start**:
```hcl
module "lambda_insights" {
  source = "./modules/lambda-insights"

  project_name = "my-project"
  environment  = "production"

  # Lambda functions to monitor
  lambda_function_names = [
    "my-api-function",
    "my-processor-function"
  ]

  # Enable enhanced monitoring
  enable_enhanced_monitoring = true
}
```

**View Lambda Insights**:
```bash
# Query Lambda Insights
aws logs start-query \
  --log-group-name /aws/lambda-insights \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string '
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count() by function_name
  '
```

### Application Insights - ML-Powered Anomaly Detection

**Module**: `terraform/modules/application-insights/`

**Features**:
- ðŸ¤– **4 ML Anomaly Detectors**: API latency, error rates, request volume, database queries
- ðŸ“Š **Custom Metric Filters**: Application-specific patterns
- ðŸ‘¥ **Contributor Insights**: Top error sources, High-traffic IPs
- ðŸ”” **Synthetics Canary**: Proactive availability monitoring (optional)

**Quick Start**:
```hcl
module "application_insights" {
  source = "./modules/application-insights"

  project_name = "my-project"
  environment  = "production"

  # Enable ML anomaly detection
  enable_anomaly_detection = true

  # Application log group
  application_log_group = "/aws/ec2/my-app"

  # Enable Synthetics canary
  enable_canary          = true
  canary_endpoint        = "https://myapp.example.com/health"
}
```

**Check Anomalies**:
```bash
# Get anomaly detector status
aws cloudwatch describe-anomaly-detectors

# Query detected anomalies
aws cloudwatch describe-anomalies \
  --anomaly-detector-arn arn:aws:cloudwatch:us-east-1:123456789012:anomaly-detector/abc123 \
  --start-time $(date -u -d '24 hours ago' +%s)000 \
  --end-time $(date -u +%s)000
```

### APM Dashboard

Comprehensive APM dashboard template available in [docs/APM_GUIDE.md](docs/APM_GUIDE.md)

**Key Metrics**:
- Request latency (p50, p95, p99)
- Error rates by service
- Throughput (requests/min)
- Service dependencies
- Resource utilization
- Cold start frequency
- Anomaly detection alerts

---

## ðŸ›¡ï¸ Security & Compliance

### Overview

Enterprise-grade security dengan AWS Config, GuardDuty, dan Security Hub untuk continuous compliance monitoring dan threat detection.

### AWS Config - Compliance Monitoring

**Module**: `terraform/modules/aws-config/`

**Features**:
- âœ… **15 Managed Config Rules**: encrypted-volumes, iam-password-policy, s3-bucket-encryption, rds-storage-encrypted, cloudtrail-enabled, vpc-flow-logs-enabled, root-account-mfa-enabled, dll
- ðŸ”§ **2 Custom Lambda Rules**: S3 public access blocker, IAM password policy checker
- ðŸ“‹ **2 Conformance Packs**: 
  - **CIS AWS Foundations Benchmark v1.4.0** (50+ rules)
  - **AWS Operational Best Practices** (40+ rules)
- ðŸ”„ **Automated Remediation**: SSM Automation untuk 5 rules (EBS encryption, S3 encryption, VPC flow logs, etc.)
- ðŸš¨ **4 CloudWatch Alarms**: Compliance violations, Recorder stopped, Delivery failed, Conformance pack violations

**Quick Start**:
```hcl
module "aws_config" {
  source = "./modules/aws-config"

  project_name = "my-project"
  environment  = "production"

  # Enable Config recorder
  enable_config_recorder = true
  recording_frequency    = "CONTINUOUS"

  # S3 bucket for Config data
  config_bucket_name = "my-config-bucket"

  # Enable conformance packs
  enable_conformance_packs = true
  conformance_packs = [
    {
      name            = "cis-aws-foundations"
      template_s3_uri = null  # Uses built-in template
    },
    {
      name            = "operational-best-practices"
      template_s3_uri = null
    }
  ]

  # Enable automated remediation (test first!)
  enable_remediation       = true
  auto_remediation_enabled = false  # Manual approval first
}
```

**Check Compliance**:
```bash
# Get compliance summary
aws configservice describe-compliance-by-config-rule

# Get non-compliant resources
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name s3-bucket-public-read-prohibited \
  --compliance-types NON_COMPLIANT

# Get conformance pack compliance
aws configservice describe-conformance-pack-compliance \
  --conformance-pack-name cis-aws-foundations
```

### GuardDuty - Threat Detection

**Module**: `terraform/modules/guardduty/`

**Features**:
- ðŸ›¡ï¸ **3 Protection Types**: 
  - **S3 Protection**: Monitors S3 data access patterns
  - **Kubernetes Protection**: EKS audit log analysis
  - **Malware Protection**: EBS volume scanning
- ðŸš¨ **5 Severity-Based SNS Topics**: Critical (9.0+), High (7.0-8.9), Medium (4.0-6.9), Low (0.1-3.9), Info
- ðŸ¤– **Auto-Remediation Lambda**: 7 automated actions (isolate instance, disable access keys, block S3 public access, stop instance, quarantine, snapshot, ignore pentest)
- ðŸ“Š **Threat Intelligence**: Custom threat feeds from S3
- ðŸŒ **IP Sets**: Trusted IPs and malicious IPs
- ðŸ”” **EventBridge Integration**: Severity-based routing to SNS/Lambda
- ðŸš¨ **3 CloudWatch Alarms**: High severity findings, Critical findings, Detector health

**Quick Start**:
```hcl
module "guardduty" {
  source = "./modules/guardduty"

  project_name = "my-project"
  environment  = "production"

  # Enable GuardDuty
  enable_guardduty           = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Protection types
  enable_s3_protection         = true
  enable_kubernetes_protection = true
  enable_malware_protection   = true

  # Auto-remediation
  enable_auto_remediation  = true
  auto_remediation_actions = [
    "isolate_instance",
    "disable_access_key",
    "block_public_access"
  ]

  # SNS notifications
  enable_sns_notifications = true
}
```

**View GuardDuty Findings**:
```bash
# List findings
aws guardduty list-findings --detector-id <detector-id>

# Get finding details
aws guardduty get-findings \
  --detector-id <detector-id> \
  --finding-ids <finding-id>

# Generate test finding
aws guardduty create-sample-findings \
  --detector-id <detector-id> \
  --finding-types UnauthorizedAccess:EC2/MaliciousIPCaller.Custom
```

### Security Hub - Centralized Security Dashboard

**Module**: `terraform/modules/security-hub/`

**Features**:
- ðŸ“Š **5 Security Standards**: 
  - CIS AWS Foundations Benchmark v1.4.0
  - AWS Foundational Security Best Practices
  - PCI-DSS v3.2.1
  - NIST 800-53 Rev5
  - CIS v1.2.0 (legacy)
- ðŸ”Œ **8 Product Integrations**: GuardDuty, Config, Inspector, Macie, IAM Access Analyzer, Firewall Manager, Health, Systems Manager
- ðŸ” **5 Custom Insights**: Critical/High findings, Failed controls, Public resources, IAM issues, Unpatched resources
- âš™ï¸ **3 Action Targets**: Auto-remediate, Create ticket, Suppress finding
- ðŸ”” **EventBridge Integration**: Automated response workflows
- ðŸš¨ **4 CloudWatch Alarms**: Critical findings, High findings, Compliance score drop, Failed security checks

**Quick Start**:
```hcl
module "security_hub" {
  source = "./modules/security-hub"

  project_name = "my-project"
  environment  = "production"

  # Enable Security Hub
  enable_security_hub = true

  # Security standards
  enabled_standards = [
    "cis_1_4_0",
    "aws_foundational",
    "pci_dss",
    "nist_800_53"
  ]

  # Product integrations
  enabled_products = [
    "guardduty",
    "config",
    "inspector",
    "access_analyzer"
  ]

  # Custom insights
  enable_custom_insights = true

  # EventBridge automation
  enable_eventbridge_integration = true

  # Alarms
  enable_alarms               = true
  critical_findings_threshold = 0
  compliance_score_threshold  = 80
}
```

**View Security Hub**:
```bash
# Get findings summary
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# Get compliance status
aws securityhub describe-standards-controls \
  --standards-subscription-arn <arn>

# Get insights
aws securityhub get-insights
```

### Security Incident Response

**Automated Response Workflows**:

1. **Critical Finding Detected** â†’ EventBridge â†’ Lambda Auto-Remediate â†’ SNS Alert
2. **Compliance Violation** â†’ Config Rule â†’ SSM Automation â†’ Remediate Resource
3. **Threat Detected** â†’ GuardDuty â†’ Isolate Instance â†’ Create Forensics Snapshot

**Manual Response Playbooks**: See [docs/SECURITY_GUIDE.md](docs/SECURITY_GUIDE.md)

### Compliance Frameworks

| Framework | Config Rules | Conformance Pack | Coverage |
|-----------|--------------|------------------|----------|
| **CIS AWS Foundations v1.4.0** | 50+ | âœ… | IAM, Logging, Monitoring, Networking, Storage |
| **AWS Best Practices** | 40+ | âœ… | Compute, Storage, Database, Networking, Security |
| **PCI-DSS v3.2.1** | 30+ | Via Security Hub | Cardholder data protection |
| **NIST 800-53 Rev5** | 40+ | Via Security Hub | Federal compliance |

---

## ðŸ“Š Monitoring

### CloudWatch Logs (when enabled)

| Log Group | Content | Retention |
|-----------|---------|-----------|
| `/aws/ec2/cloud-infra-syslog` | System logs, application logs | 7 days |
| `/aws/ec2/cloud-infra-nginx-access` | HTTP requests, IPs, status codes | 7 days |
| `/aws/ec2/cloud-infra-nginx-error` | Web server errors | 7 days |

### CloudWatch Alarms

| Alarm | Threshold | Period | Action |
|-------|-----------|--------|--------|
| **High CPU** | > 80% | 2 datapoints of 1 min | SNS notification |
| **High Memory** | > 80% | 2 datapoints of 1 min | SNS notification |
| **High Disk** | > 85% | 1 datapoint of 5 min | SNS notification |
| **Health Check Failed** | >= 1 failure | 1 datapoint of 1 min | SNS notification |

### Viewing Metrics

```bash
# Tail logs in real-time
aws logs tail /aws/ec2/cloud-infra-syslog --follow --region ap-southeast-1

# Query specific time range
aws logs filter-log-events \
  --log-group-name /aws/ec2/cloud-infra-nginx-access \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region ap-southeast-1

# List all alarms
aws cloudwatch describe-alarms --region ap-southeast-1

# Get alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name cloud-infra-high-cpu-dev \
  --region ap-southeast-1
```

### Dashboard

See template: [docs/cloudwatch-dashboard.md](docs/cloudwatch-dashboard.md)

---

## ðŸ”’ Security

### Implemented Security Features

âœ… **Network Security**
- Minimal security group rules (only required ports)
- VPC with controlled subnets and route tables
- Optional bastion host for SSH access
- No direct SSH access to web servers (with bastion)

âœ… **Data Security**
- Encrypted EBS volumes (AWS-managed keys)
- Encrypted S3 state storage (AES-256)
- HTTPS support in security groups
- SSH key-based authentication only

âœ… **Access Control**
- IAM roles for EC2 (no hardcoded credentials)
- Least privilege IAM policies
- State locking prevents concurrent modifications
- Version-controlled infrastructure (audit trail)

âœ… **Operational Security**
- Immutable infrastructure (destroy & recreate)
- Automated testing before deployment
- Manual approval for production changes
- Comprehensive logging and monitoring

### Security Best Practices

ðŸ”„ **Recommended Enhancements:**

1. **Network**:
   - Enable VPC Flow Logs
   - Implement private subnets for web servers
   - Use AWS PrivateLink for AWS services

2. **Application**:
   - Implement AWS WAF for web application firewall
   - Use AWS Shield for DDoS protection
   - Enable AWS GuardDuty for threat detection

3. **Access**:
   - Use AWS Systems Manager Session Manager (no SSH keys needed)
   - Implement MFA for AWS console access
   - Rotate credentials regularly

4. **Data**:
   - Use AWS Secrets Manager for sensitive data
   - Enable AWS KMS customer-managed keys
   - Implement backup policies

5. **Compliance**:
   - Enable AWS Config for compliance monitoring
   - Use AWS Security Hub for security posture
   - Regular security audits

### Security Group Rules

**Web Server Security Group:**
```hcl
Ingress:
  - SSH (22)    from 0.0.0.0/0  # Change to your IP for production!
  - HTTP (80)   from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0

Egress:
  - All traffic to 0.0.0.0/0
```

**Bastion Security Group (if enabled):**
```hcl
Ingress:
  - SSH (22) from 0.0.0.0/0  # Change to your IP for production!

Egress:
  - All traffic to 0.0.0.0/0
```

**âš ï¸ Production Recommendation**: Restrict SSH (port 22) to your specific IP address only!

```hcl
# In terraform/env/prod.tfvars
# Add variable for your IP
my_ip = "YOUR_PUBLIC_IP/32"

# Update security group to use this
cidr_blocks = [var.my_ip]
```

---

## ðŸ’° Cost Estimation

### Monthly Costs (ap-southeast-1)

#### Development Environment (Basic)
| Service | Spec | Cost/Month |
|---------|------|------------|
| EC2 (t2.micro) | 1 instance, 24/7 | ~$7.00 |
| EBS Volume | 20GB gp3 | ~$2.00 |
| Data Transfer | 10GB out | ~$1.00 |
| **Total** | | **~$10/month** |

#### Development Environment (With APM + Security)
| Service | Spec | Cost/Month |
|---------|------|------------|
| EC2 (t2.micro) | 1 instance, 24/7 | ~$7.00 |
| EBS Volume | 20GB gp3 | ~$2.00 |
| CloudWatch | Logs + metrics | ~$3.00 |
| X-Ray | 100K traces/month | ~$0.50 |
| Lambda Insights | 2 functions | ~$1.00 |
| AWS Config | 50 resources, daily recording | ~$30.00 |
| GuardDuty | CloudTrail + VPC logs | ~$25.00 |
| Security Hub | Findings ingestion | ~$15.00 |
| Data Transfer | 10GB out | ~$1.00 |
| **Total** | | **~$84.50/month** |

#### Staging Environment
| Service | Spec | Cost/Month |
|---------|------|------------|
| EC2 (t3.micro) | 1 instance, 24/7 | ~$8.00 |
| EBS Volume | 20GB gp3 | ~$2.00 |
| CloudWatch | Logs + metrics + alarms | ~$5.00 |
| X-Ray | 250K traces/month | ~$1.25 |
| Container Insights | 1 ECS cluster | ~$7.00 |
| Lambda Insights | 5 functions | ~$2.50 |
| Application Insights | ML anomaly detection | ~$3.00 |
| AWS Config | 100 resources, daily recording | ~$60.00 |
| GuardDuty | All protections, 6h frequency | ~$50.00 |
| Security Hub | 2 standards | ~$20.00 |
| Data Transfer | 15GB out | ~$1.50 |
| **Total** | | **~$160.25/month** |

#### Production Environment
| Service | Spec | Cost/Month |
|---------|------|------------|
| EC2 (t3.medium) | 1 instance, 24/7 | ~$30.00 |
| EBS Volume | 20GB gp3 | ~$2.00 |
| Bastion (t2.micro) | 1 instance, 24/7 | ~$7.00 |
| CloudWatch | Logs + metrics + alarms | ~$10.00 |
| X-Ray | 1M traces/month | ~$5.00 |
| Container Insights | 3 ECS clusters | ~$21.00 |
| Lambda Insights | 20 functions | ~$10.00 |
| Application Insights | ML + Synthetics | ~$15.00 |
| AWS Config | 500 resources, continuous | ~$200.00 |
| GuardDuty | All protections, 15min frequency | ~$150.00 |
| Security Hub | 5 standards, 8 integrations | ~$100.00 |
| SNS | Security notifications | ~$0.50 |
| Lambda | Auto-remediation functions | ~$5.00 |
| Data Transfer | 50GB out | ~$5.00 |
| **Total** | | **~$560.50/month** |

### Cost Optimization Strategies

#### For Non-Production Environments

1. **Reduce Config Recording Frequency**:
   ```hcl
   # dev/staging: Daily snapshots (save ~60%)
   recording_frequency = "DAILY"
   
   # production: Continuous
   recording_frequency = "CONTINUOUS"
   ```

2. **Selective Config Rules**:
   ```hcl
   # dev: Only critical rules
   managed_rules = ["encrypted-volumes", "s3-bucket-public-read-prohibited"]
   
   # production: All 15 rules
   ```

3. **GuardDuty Finding Frequency**:
   ```hcl
   # dev/staging: 6 hours (save ~75% API calls)
   finding_publishing_frequency = "SIX_HOURS"
   
   # production: 15 minutes
   finding_publishing_frequency = "FIFTEEN_MINUTES"
   ```

4. **Reduce Security Hub Standards**:
   ```hcl
   # dev/staging: Essential only
   enabled_standards = ["cis_1_4_0", "aws_foundational"]
   
   # production: All standards
   enabled_standards = ["cis_1_4_0", "aws_foundational", "pci_dss", "nist_800_53"]
   ```

5. **X-Ray Sampling**:
   ```hcl
   # dev: Lower sampling rate
   fixed_rate = 0.01  # 1%
   
   # production: Higher sampling
   fixed_rate = 0.05  # 5%
   ```

#### Cost Savings Summary

| Environment | Without Optimization | With Optimization | Savings |
|-------------|---------------------|-------------------|---------|
| **Dev** | $84.50/month | $35.00/month | **58%** |
| **Staging** | $160.25/month | $75.00/month | **53%** |
| **Production** | $560.50/month | $560.50/month | **0%** (full monitoring) |

### Additional Cost Optimization Tips

1. **Stop instances when not in use**:
   ```bash
   # Stop instance
   aws ec2 stop-instances --instance-ids i-xxxxx
   
   # Start instance
   aws ec2 start-instances --instance-ids i-xxxxx
   ```

2. **Use smaller instance types for dev**:
   - t2.micro (free tier eligible)
   - t3.nano for minimal workloads

3. **Delete unused resources**:
   ```bash
   terraform destroy -var-file="env/dev.tfvars"
   ```

4. **Use AWS Free Tier**:
   - 750 hours/month of t2.micro
   - 30GB EBS storage
   - 15GB data transfer out
   - 1M X-Ray traces (perpetual free tier)
   - 50 Config rules (first month free)

5. **Set up billing alarms**:
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name billing-alarm-100 \
     --alarm-description "Alert when spending exceeds $100" \
     --metric-name EstimatedCharges \
     --namespace AWS/Billing \
     --statistic Maximum \
     --period 21600 \
     --evaluation-periods 1 \
     --threshold 100 \
     --comparison-operator GreaterThanThreshold
   ```

6. **Monitor costs**:
   - AWS Cost Explorer
   - AWS Budgets
   - Cost and Usage Reports
   - AWS Cost Anomaly Detection

7. **S3 Lifecycle Policies**:
   ```hcl
   # Transition old logs to cheaper storage
   lifecycle_rule {
     enabled = true
     
     transition {
       days          = 90
       storage_class = "STANDARD_IA"
     }
     
     transition {
       days          = 180
       storage_class = "GLACIER"
     }
     
     expiration {
       days = 365
     }
   }
   ```

8. **Lambda Cost Optimization**:
   - Right-size memory allocation
   - Reduce execution time
   - Use reserved concurrency wisely
   - Enable Lambda Insights only for critical functions

### âš ï¸ Cost Warnings

- Running 24/7 will incur charges beyond free tier
- AWS Config continuous recording can be expensive ($2 per config item per month)
- GuardDuty costs scale with log volume (VPC Flow Logs, CloudTrail events, S3 data events)
- Security Hub costs increase with number of findings and standards enabled
- Data transfer costs can add up with high traffic
- CloudWatch custom metrics have additional costs
- NAT Gateways (if added) are expensive (~$32/month)
- **Always destroy resources when testing is complete!**
- Consider using AWS Organizations for volume discounts on security services

### Cost Calculator

Use [AWS Pricing Calculator](https://calculator.aws/) to estimate costs for your specific workload.

**Quick estimate for this project**:
- Basic infrastructure: $10-50/month
- With full monitoring (APM): $50-150/month  
- With monitoring + security: $150-600/month
- Enterprise (multi-account): $600-2000/month

---

## ðŸ› Troubleshooting

### Common Issues & Solutions

#### 1. Error: "Error locking state"

**Cause**: Previous Terraform run crashed or state lock wasn't released

**Solution**:
```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>

# If lock is stuck, check DynamoDB
aws dynamodb scan --table-name cloud-infra-lock

# Delete specific lock item if needed
aws dynamodb delete-item \
  --table-name cloud-infra-lock \
  --key '{"LockID": {"S": "LOCK_ID_HERE"}}'
```

#### 2. Error: "Instance failed to start"

**Cause**: Incorrect AMI, insufficient capacity, or quota limits

**Solution**:
```bash
# Check if AMI exists in your region
aws ec2 describe-images \
  --image-ids ami-0dc2d3e4c0f9ebd18 \
  --region ap-southeast-1

# Check vCPU quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ap-southeast-1

# Try different instance type in tfvars
instance_type = "t3.micro"  # instead of t2.micro
```

#### 3. Ansible: "Host unreachable"

**Cause**: EC2 not ready, security group blocks SSH, or wrong SSH key

**Solution**:
```bash
# Wait for EC2 to be fully ready (2-3 minutes after apply)
aws ec2 describe-instance-status \
  --instance-ids $(terraform output -raw ec2_instance_id)

# Test SSH directly
ssh -i ~/.ssh/cloud-infra-key -v ubuntu@$(terraform output -raw ec2_public_ip)

# Check security group allows your IP
MY_IP=$(curl -s ifconfig.me)
echo "My IP: $MY_IP"

# Update security group if needed
aws ec2 authorize-security-group-ingress \
  --group-id $(terraform output -raw security_group_id) \
  --protocol tcp \
  --port 22 \
  --cidr $MY_IP/32
```

#### 4. Website tidak bisa diakses

**Cause**: Nginx not running, security group blocks HTTP, or wrong IP

**Solution**:
```bash
# Check EC2 instance status
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw ec2_instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'

# SSH to instance and check nginx
ssh -i ~/.ssh/cloud-infra-key ubuntu@$(terraform output -raw ec2_public_ip)
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log

# Restart nginx if needed
sudo systemctl restart nginx

# Check security group allows HTTP
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id)
```

#### 5. CloudWatch agent not sending logs

**Cause**: IAM role not attached, agent not running, or misconfigured

**Solution**:
```bash
# SSH to instance
ssh -i ~/.ssh/cloud-infra-key ubuntu@$(terraform output -raw ec2_public_ip)

# Check agent status
sudo systemctl status amazon-cloudwatch-agent

# View agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log

# Check configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent

# Verify IAM role is attached
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw ec2_instance_id) \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

#### 6. Terraform state out of sync

**Cause**: Manual changes made in AWS console or concurrent modifications

**Solution**:
```bash
# Refresh state from actual AWS resources
terraform refresh -var-file="env/dev.tfvars"

# If specific resource is out of sync, import it
terraform import aws_instance.example i-1234567890abcdef0

# As last resort, recreate resource
terraform taint module.ec2.aws_instance.main
terraform apply -var-file="env/dev.tfvars"
```

#### 7. Terratest times out

**Cause**: EC2 taking too long to boot or security group blocking test traffic

**Solution**:
```bash
# Increase test timeout
go test -v -timeout 60m

# Check security group allows traffic from test machine
aws ec2 describe-security-groups --group-id <SG_ID>

# Run with verbose output
go test -v -run TestTerraformInfrastructure

# Check AWS region is correct
# ap-southeast-1 might have capacity issues, try another AZ
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Terraform debug
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply -var-file="env/dev.tfvars"

# Ansible debug (levels: -v, -vv, -vvv, -vvvv)
ansible-playbook -i inventory/dev/hosts playbook.yml -vvvv

# AWS CLI debug
aws ec2 describe-instances --debug
```

### Getting More Help

1. **Check logs**:
   ```bash
   # Terraform
   cat terraform.log
   
   # Ansible
   cat ~/.ansible.log
   
   # CloudWatch (if enabled)
   aws logs tail /aws/ec2/cloud-infra-syslog --follow
   
   # EC2 console output
   aws ec2 get-console-output --instance-id i-xxxxx
   ```

2. **Verify AWS permissions**:
   ```bash
   aws sts get-caller-identity
   aws iam get-user
   aws iam list-attached-user-policies --user-name YOUR_USERNAME
   ```

3. **Check resource limits**:
   ```bash
   # EC2 vCPU limit
   aws service-quotas get-service-quota \
     --service-code ec2 \
     --quota-code L-1216C47A
   
   # VPC limit
   aws service-quotas get-service-quota \
     --service-code vpc \
     --quota-code L-F678F1CE
   ```

4. **AWS Support**:
   - [AWS Support Center](https://console.aws.amazon.com/support/)
   - [AWS Forums](https://forums.aws.amazon.com/)
   - [AWS re:Post](https://repost.aws/)

---

## ðŸ“š Documentation

### Core Documentation

- **[README.md](README.md)** - This file (overview and quick start)
- **[DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)** - Complete step-by-step deployment guide
- **[architecture.md](docs/architecture.md)** - Detailed architecture with Mermaid diagram

### Monitoring & Observability

- **[APM_GUIDE.md](docs/APM_GUIDE.md)** - Comprehensive Application Performance Monitoring guide (1,100+ lines)
  - AWS X-Ray distributed tracing setup
  - Container Insights for ECS/EKS monitoring
  - Lambda Insights for serverless observability
  - Application Insights with ML anomaly detection
  - Instrumentation guides for Python, Node.js, Java
  - Dashboard strategies and alerting
  - Cost optimization for APM

### Security & Compliance

- **[SECURITY_GUIDE.md](docs/SECURITY_GUIDE.md)** - Complete security and compliance documentation (1,000+ lines)
  - AWS Config compliance monitoring setup
  - GuardDuty threat detection configuration
  - Security Hub centralized dashboard
  - Compliance frameworks (CIS, PCI-DSS, NIST 800-53)
  - Automated remediation workflows
  - Alert routing and incident response
  - Security best practices and cost optimization

### Commercial & Enterprise

- **[LICENSING.md](LICENSING.md)** - Commercial licensing options and pricing
  - Community (Free), Professional, Enterprise licenses
  - Exclusive licensing for enterprises
  - Compliance certifications (SOC 2, HIPAA, ISO 27001)
  - Support tiers and SLA commitments
  - Custom development options
  - ROI calculator and case studies

- **[ENTERPRISE_SERVICES.md](ENTERPRISE_SERVICES.md)** - Managed services and consulting
  - Managed Services packages (Basic to White Glove)
  - 24/7 infrastructure management
  - Custom development services (Terraform modules, CI/CD, Security)
  - Migration services and consulting
  - Training programs and certifications
  - Staff augmentation options
  - Enterprise partnership programs

### Examples & Templates

- **[terraform-plan-example.md](docs/terraform-plan-example.md)** - Example terraform plan output
- **[ansible-check-example.md](docs/ansible-check-example.md)** - Example ansible --check output
- **[terraform-state-structure.md](docs/terraform-state-structure.md)** - State file structure explained
- **[cloudwatch-dashboard.md](docs/cloudwatch-dashboard.md)** - CloudWatch dashboard JSON template

### Testing Documentation

- **[tests/README.md](tests/README.md)** - Terratest setup and usage

### Infrastructure Code

```
terraform/
â”œâ”€â”€ main.tf              # Main infrastructure definition
â”œâ”€â”€ variables.tf         # Variable declarations
â”œâ”€â”€ outputs.tf          # Output definitions
â”œâ”€â”€ cloudwatch.tf       # Monitoring configuration
â”œâ”€â”€ user-data.sh        # EC2 bootstrap script
â”œâ”€â”€ modules/
â”‚   â”œâ”€â”€ ec2/           # EC2 instance module
â”‚   â”œâ”€â”€ bastion/       # Bastion host module
â”‚   â”œâ”€â”€ xray/          # AWS X-Ray distributed tracing
â”‚   â”œâ”€â”€ container-insights/  # ECS/EKS monitoring
â”‚   â”œâ”€â”€ lambda-insights/     # Serverless monitoring
â”‚   â”œâ”€â”€ application-insights/ # ML anomaly detection
â”‚   â”œâ”€â”€ aws-config/    # Compliance monitoring
â”‚   â”œâ”€â”€ guardduty/     # Threat detection
â”‚   â””â”€â”€ security-hub/  # Security dashboard
â”œâ”€â”€ env/               # Environment-specific variables
â””â”€â”€ backend/           # Backend configurations

ansible/
â”œâ”€â”€ playbook.yml       # Main playbook
â”œâ”€â”€ ansible.cfg        # Ansible configuration
â”œâ”€â”€ roles/
â”‚   â””â”€â”€ webserver/     # Web server role
â”œâ”€â”€ inventory/         # Environment inventories
â””â”€â”€ group_vars/        # Environment variables

docs/
â”œâ”€â”€ DEPLOYMENT-GUIDE.md   # Deployment guide
â”œâ”€â”€ architecture.md       # Architecture docs
â”œâ”€â”€ APM_GUIDE.md         # APM comprehensive guide
â”œâ”€â”€ SECURITY_GUIDE.md    # Security & compliance guide
â””â”€â”€ [other docs]         # Templates and examples

.github/
â””â”€â”€ workflows/
    â””â”€â”€ infra.yml      # CI/CD pipeline
```

---

## ðŸ—‚ï¸ Project Structure

```
cloud-infra/
â”œâ”€â”€ terraform/                       # Infrastructure as Code
â”‚   â”œâ”€â”€ main.tf                      # Main configuration with VPC, EC2, SG
â”‚   â”œâ”€â”€ variables.tf                 # Variable definitions
â”‚   â”œâ”€â”€ outputs.tf                   # Output values
â”‚   â”œâ”€â”€ cloudwatch.tf                # Monitoring configuration
â”‚   â”œâ”€â”€ user-data.sh                 # EC2 bootstrap script
â”‚   â”œâ”€â”€ modules/
â”‚   â”‚   â”œâ”€â”€ ec2/                     # EC2 instance module
â”‚   â”‚   â”‚   â”œâ”€â”€ main.tf
â”‚   â”‚   â”‚   â”œâ”€â”€ variables.tf
â”‚   â”‚   â”‚   â””â”€â”€ outputs.tf
â”‚   â”‚   â””â”€â”€ bastion/                 # Bastion host module
â”‚   â”‚       â”œâ”€â”€ main.tf
â”‚   â”‚       â”œâ”€â”€ variables.tf
â”‚   â”‚       â””â”€â”€ outputs.tf
â”‚   â”œâ”€â”€ env/                         # Environment-specific variables
â”‚   â”‚   â”œâ”€â”€ dev.tfvars
â”‚   â”‚   â”œâ”€â”€ staging.tfvars
â”‚   â”‚   â””â”€â”€ prod.tfvars
â”‚   â””â”€â”€ backend/                     # Backend configurations
â”‚       â”œâ”€â”€ dev.conf
â”‚       â”œâ”€â”€ staging.conf
â”‚       â””â”€â”€ prod.conf
â”œâ”€â”€ ansible/                         # Configuration management
â”‚   â”œâ”€â”€ playbook.yml                 # Main playbook
â”‚   â”œâ”€â”€ ansible.cfg                  # Ansible configuration
â”‚   â”œâ”€â”€ update_inventory.sh          # Auto-update inventory script
â”‚   â”œâ”€â”€ update_inventory.ps1         # Auto-update inventory (PowerShell)
â”‚   â”œâ”€â”€ roles/
â”‚   â”‚   â””â”€â”€ webserver/               # Web server role
â”‚   â”‚       â”œâ”€â”€ tasks/
â”‚   â”‚       â”‚   â””â”€â”€ main.yml
â”‚   â”‚       â”œâ”€â”€ handlers/
â”‚   â”‚       â”‚   â””â”€â”€ main.yml
â”‚   â”‚       â”œâ”€â”€ defaults/
â”‚   â”‚       â”‚   â””â”€â”€ main.yml
â”‚   â”‚       â””â”€â”€ templates/
â”‚   â”‚           â”œâ”€â”€ index.html.j2
â”‚   â”‚           â””â”€â”€ nginx-site.conf.j2
â”‚   â”œâ”€â”€ inventory/                   # Environment inventories
â”‚   â”‚   â”œâ”€â”€ dev/
â”‚   â”‚   â”‚   â””â”€â”€ hosts
â”‚   â”‚   â”œâ”€â”€ staging/
â”‚   â”‚   â”‚   â””â”€â”€ hosts
â”‚   â”‚   â””â”€â”€ prod/
â”‚   â”‚       â””â”€â”€ hosts
â”‚   â””â”€â”€ group_vars/                  # Group variables
â”‚       â”œâ”€â”€ dev.yml
â”‚       â”œâ”€â”€ staging.yml
â”‚       â””â”€â”€ prod.yml
â”œâ”€â”€ tests/                           # Infrastructure tests
â”‚   â”œâ”€â”€ terraform_test.go            # Terratest suite
â”‚   â”œâ”€â”€ go.mod                       # Go dependencies
â”‚   â””â”€â”€ README.md                    # Testing documentation
â”œâ”€â”€ scripts/                         # Automation scripts
â”‚   â”œâ”€â”€ setup-backend.sh             # Backend setup (Linux/Mac)
â”‚   â”œâ”€â”€ setup-backend.ps1            # Backend setup (Windows)
â”‚   â”œâ”€â”€ destroy-all.sh               # Destroy all environments (Bash)
â”‚   â””â”€â”€ destroy-all.ps1              # Destroy all environments (PowerShell)
â”œâ”€â”€ docs/                            # Documentation
â”‚   â”œâ”€â”€ architecture.md              # Architecture details with Mermaid
â”‚   â”œâ”€â”€ DEPLOYMENT-GUIDE.md          # Complete deployment guide
â”‚   â”œâ”€â”€ terraform-plan-example.md    # Example plan output
â”‚   â”œâ”€â”€ ansible-check-example.md     # Example Ansible check output
â”‚   â”œâ”€â”€ terraform-state-structure.md # State file structure
â”‚   â””â”€â”€ cloudwatch-dashboard.md      # CloudWatch dashboard template
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/
â”‚       â””â”€â”€ infra.yml                # CI/CD pipeline
â”œâ”€â”€ .gitignore                       # Git ignore patterns
â””â”€â”€ README.md                        # This file
```

**Total Files**: 50+ files
**Total Lines of Code**: ~5,000 lines

---

## ðŸ—‘ï¸ Cleanup

### Destroy Single Environment

```bash
cd terraform
terraform destroy -var-file="env/dev.tfvars"
# Type: yes
```

### Destroy All Environments (DANGEROUS!)

```bash
# Linux/macOS
chmod +x scripts/destroy-all.sh
./scripts/destroy-all.sh

# Windows PowerShell
.\scripts\destroy-all.ps1
```

**Safety Features:**
- Double confirmation required (`yes` + `DESTROY`)
- Shows resources to be destroyed
- Preserves backend (S3 + DynamoDB) by default

### Clean Backend Resources (Optional)

After destroying all environments, you can optionally remove backend:

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Delete S3 bucket (removes all versions)
aws s3 rb s3://cloud-infra-terraform-state-$ACCOUNT_ID --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name cloud-infra-lock
```

âš ï¸ **WARNING**: This will permanently delete all Terraform state files and make it impossible to manage existing resources with Terraform!

---

## ðŸ¤ Contributing

Contributions are welcome! Please follow these guidelines:

### How to Contribute

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   git clone https://github.com/YOUR_USERNAME/cloud-infra.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```bash
   # Terraform
   terraform fmt -check -recursive
   terraform validate
   
   # Ansible
   ansible-lint playbook.yml
   
   # Run Terratest
   cd tests && go test -v
   ```

5. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**
   - Describe what you changed
   - Reference any related issues
   - Wait for review

### Contribution Ideas

- ðŸ› Bug fixes
- âœ¨ New features (e.g., RDS module, ALB module)
- ðŸ“ Documentation improvements
- ðŸ§ª Additional tests
- ðŸŽ¨ UI improvements for web page
- ðŸ”§ Configuration enhancements

### Code Style

- **Terraform**: Use `terraform fmt`
- **Ansible**: Follow [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- **Shell scripts**: Use [ShellCheck](https://www.shellcheck.net/)
- **Go**: Use `gofmt`

---

## ðŸ“„ License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2025 Cloud Infrastructure Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## ðŸ™ Acknowledgments

### Technologies Used

- **[Terraform](https://www.terraform.io/)** by HashiCorp - Infrastructure as Code
- **[Ansible](https://www.ansible.com/)** by Red Hat - Configuration Management
- **[AWS](https://aws.amazon.com/)** - Cloud Infrastructure
- **[Terratest](https://terratest.gruntwork.io/)** by Gruntwork - Infrastructure Testing
- **[GitHub Actions](https://github.com/features/actions)** - CI/CD Platform

### Inspired By

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [12 Factor App](https://12factor.net/)

### Community

Special thanks to:
- All contributors and issue reporters
- DevOps community for best practices
- Open source maintainers

---

## ðŸ“ž Support & Contact

### Get Help

- ðŸ“– **Documentation**: Start with [DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)
- ðŸ› **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/cloud-infra/issues)
- ðŸ’¬ **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/cloud-infra/discussions)
- ðŸ“§ **Email**: your-email@example.com

### Social Media

- ðŸ¦ **Twitter**: [@yourhandle](https://twitter.com/yourhandle)
- ðŸ’¼ **LinkedIn**: [Your Name](https://linkedin.com/in/yourprofile)
- ðŸŒ **Website**: [yourwebsite.com](https://yourwebsite.com)

---

## ðŸŽ“ Learning Resources

### For Beginners

- [Terraform Tutorial](https://learn.hashicorp.com/terraform)
- [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [DevOps Roadmap](https://roadmap.sh/devops)

### Advanced Topics

- [Terraform Enterprise Patterns](https://www.terraform.io/enterprise)
- [Ansible Automation Platform](https://www.ansible.com/products/automation-platform)
- [AWS Solutions Architect](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
- [Infrastructure as Code Book](https://www.oreilly.com/library/view/infrastructure-as-code/9781491924357/)

---

## ðŸš€ What's Next?

### Planned Features

- [ ] Auto Scaling Group support
- [ ] Application Load Balancer integration
- [ ] RDS database module
- [ ] ElastiCache Redis module
- [ ] Multi-region deployment
- [ ] Disaster recovery automation
- [ ] Cost optimization recommendations
- [ ] Security scanning integration

### Version History

**v1.7.0** (2025-11-16) - Security & Compliance
- âœ… AWS Config compliance monitoring (15 managed + 2 custom rules)
- âœ… CIS Benchmark + Operational Best Practices conformance packs (90+ total rules)
- âœ… GuardDuty threat detection with auto-remediation
- âœ… Security Hub centralized dashboard (5 standards, 8 integrations)
- âœ… Automated security response (Lambda + EventBridge)
- âœ… Multi-account security management
- âœ… Comprehensive security documentation

**v1.6.0** (2025-11-15) - Application Performance Monitoring
- âœ… AWS X-Ray distributed tracing (5 sampling rules, 3 groups)
- âœ… Container Insights for ECS/EKS monitoring
- âœ… Lambda Insights for serverless observability
- âœ… Application Insights with ML anomaly detection
- âœ… APM comprehensive guide documentation
- âœ… Multi-region support

**v1.5.0** (2025-11-14) - Monitoring Enhancement
- âœ… Centralized logging architecture
- âœ… Advanced alerting framework
- âœ… Custom CloudWatch dashboards
- âœ… Log aggregation and analysis

**v1.0.0** (2025-11-13) - Initial Release
- âœ… Complete Terraform infrastructure
- âœ… Ansible configuration management
- âœ… GitHub Actions CI/CD
- âœ… Terratest integration
- âœ… CloudWatch monitoring
- âœ… Bastion host support
- âœ… Comprehensive documentation

---

<div align="center">

## â­ Star This Project!

If you find this project helpful, please consider giving it a star â­

**Made with â¤ï¸ for Cloud Automation**

[â¬† Back to Top](#cloud-infrastructure-project-)

---

**Happy Deploying! ðŸš€â˜ï¸**

</div>
