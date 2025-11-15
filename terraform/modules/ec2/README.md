# EC2 Module

Terraform module for creating and managing AWS EC2 instances with auto-scaling capabilities.

## Overview

This module provisions EC2 instances with:
- Custom AMI selection
- User data for initialization
- Security group configuration
- CloudWatch monitoring
- Auto-scaling group support
- EBS volume management

## Usage

```hcl
module "ec2" {
  source = "./modules/ec2"

  instance_type    = "t3.micro"
  ami_id           = "ami-xxxxxxxxx"
  subnet_id        = module.vpc.private_subnet_id
  security_groups  = [module.security.web_sg_id]
  key_name         = "my-key-pair"
  
  tags = {
    Name        = "web-server"
    Environment = "production"
    Project     = "cloud-infra"
  }
}
```

## Features

✅ Flexible instance type selection  
✅ Automated monitoring setup  
✅ Custom user data support  
✅ Security group integration  
✅ Cost-optimized defaults  
✅ Tag-based resource management

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

### Basic Web Server

```hcl
module "web_server" {
  source = "./modules/ec2"

  instance_type = "t3.small"
  ami_id        = data.aws_ami.ubuntu.id
  subnet_id     = aws_subnet.public.id
  user_data     = file("${path.module}/scripts/web-server-init.sh")
  
  tags = {
    Name = "production-web-server"
  }
}
```

### Application Server with Monitoring

```hcl
module "app_server" {
  source = "./modules/ec2"

  instance_type           = "t3.medium"
  ami_id                  = data.aws_ami.amazon_linux.id
  subnet_id               = aws_subnet.private.id
  monitoring_enabled      = true
  cloudwatch_logs_enabled = true
  
  tags = {
    Name        = "app-server"
    Environment = "production"
  }
}
```

## Security Notes

- Instances in private subnets should only be accessed via bastion host
- Ensure security groups follow least-privilege principle
- Regularly update AMIs for security patches
- Enable CloudWatch logs for audit purposes
