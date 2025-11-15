# Terraform Main Module

Enterprise-grade infrastructure as code for AWS cloud deployment with multi-environment support.

## Overview

This is the root Terraform module that orchestrates the deployment of:
- Virtual Private Cloud (VPC) with public/private subnets
- EC2 instances for application hosting
- Bastion host for secure SSH access
- Security groups with least-privilege principles
- CloudWatch monitoring and dashboards
- Auto-scaling capabilities

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    VPC                          │
│  ┌──────────────┐      ┌──────────────┐        │
│  │Public Subnet │      │Private Subnet│        │
│  │              │      │              │        │
│  │  Bastion     │──────▶  EC2 Instances│       │
│  │  Host        │      │              │        │
│  └──────────────┘      └──────────────┘        │
│                                                 │
│  CloudWatch Monitoring & Alarms                │
└─────────────────────────────────────────────────┘
```

## Usage

```hcl
terraform init -backend-config="backend/dev.conf"
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

## Environments

- **dev**: Development environment with minimal resources
- **staging**: Pre-production environment for testing
- **prod**: Production environment with high availability

## Features

✅ Multi-environment support (dev/staging/prod)  
✅ Security hardening with least-privilege IAM  
✅ Automated monitoring with CloudWatch  
✅ Cost-optimized resource allocation  
✅ Secure bastion host access  
✅ Automated backups and disaster recovery

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Security Considerations

- SSH access only through bastion host
- Security groups restrict traffic to necessary ports
- All resources tagged for cost allocation
- CloudWatch alarms for anomaly detection
- Encrypted storage for sensitive data

## Maintenance

Regular maintenance tasks:
- Review CloudWatch alarms weekly
- Update AMIs monthly for security patches
- Rotate SSH keys every 90 days
- Review IAM policies quarterly

## Support

For issues or questions, please refer to the main project documentation or open an issue in the repository.
