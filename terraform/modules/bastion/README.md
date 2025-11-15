# Bastion Host Module

Terraform module for provisioning a secure bastion host (jump box) for SSH access to private resources.

## Overview

This module creates a hardened bastion host that provides:
- Secure SSH gateway to private instances
- Public IP with strict security group rules
- CloudWatch monitoring and logging
- Automated security updates
- Session logging for audit compliance

## Usage

```hcl
module "bastion" {
  source = "./modules/bastion"

  instance_type   = "t3.micro"
  ami_id          = "ami-xxxxxxxxx"
  subnet_id       = module.vpc.public_subnet_id
  key_name        = "bastion-key"
  allowed_ssh_ips = ["203.0.113.0/24"]
  
  tags = {
    Name        = "bastion-host"
    Environment = "production"
    Purpose     = "ssh-gateway"
  }
}
```

## Features

✅ Security-hardened configuration  
✅ Restricted SSH access by IP  
✅ CloudWatch monitoring enabled  
✅ Session logging for compliance  
✅ Automated security updates  
✅ Cost-optimized instance sizing

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Security Best Practices

### SSH Key Management
- Use separate SSH keys for bastion and internal instances
- Rotate SSH keys regularly (every 90 days)
- Store private keys securely (use AWS Secrets Manager)

### Access Control
- Restrict bastion access to specific IPs only
- Use VPN connection for additional security
- Implement MFA for SSH access where possible
- Log all SSH sessions for audit purposes

### Network Isolation
- Place bastion in public subnet with minimal access
- Internal instances should only accept SSH from bastion
- Use security group rules to enforce access patterns

## Example Configurations

### Production Bastion

```hcl
module "bastion_prod" {
  source = "./modules/bastion"

  instance_type    = "t3.micro"
  ami_id           = data.aws_ami.ubuntu_hardened.id
  subnet_id        = aws_subnet.public.id
  key_name         = "prod-bastion-key"
  allowed_ssh_ips  = ["10.0.0.0/8"]  # Corporate VPN range
  
  enable_monitoring     = true
  enable_session_logging = true
  
  tags = {
    Name        = "production-bastion"
    Environment = "production"
    Compliance  = "required"
  }
}
```

### Development Bastion

```hcl
module "bastion_dev" {
  source = "./modules/bastion"

  instance_type   = "t3.micro"
  ami_id          = data.aws_ami.ubuntu.id
  subnet_id       = aws_subnet.public_dev.id
  key_name        = "dev-bastion-key"
  allowed_ssh_ips = ["0.0.0.0/0"]  # More permissive for dev
  
  tags = {
    Name        = "development-bastion"
    Environment = "development"
  }
}
```

## Maintenance

Regular maintenance checklist:
- [ ] Update bastion AMI monthly
- [ ] Review CloudWatch logs weekly
- [ ] Rotate SSH keys every 90 days
- [ ] Review allowed IP list monthly
- [ ] Test disaster recovery procedures quarterly

## Troubleshooting

### Cannot connect to bastion
1. Verify security group allows your IP
2. Check instance is running
3. Verify SSH key permissions (chmod 600)
4. Check VPC routing and internet gateway

### Cannot reach internal instances from bastion
1. Verify internal security groups allow bastion SG
2. Check private subnet routing
3. Verify SSH agent forwarding is enabled
4. Check network ACLs

## Compliance Notes

This bastion configuration supports:
- SOC 2 Type II compliance
- PCI-DSS requirements
- HIPAA security standards
- ISO 27001 controls

Ensure session logging is enabled and retained according to your compliance requirements.
