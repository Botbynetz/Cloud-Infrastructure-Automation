terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure via backend config file or CLI
    # terraform init -backend-config="backend.conf"
    # Or use environment-specific backend configs
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = var.project_name
      ManagedBy  = "Terraform"
      Repository = "cloud-infra"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw-${var.environment}"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${var.environment}"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt-${var.environment}"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg-${var.environment}"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-sg-${var.environment}"
    Environment = var.environment
  }
}

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key-${var.environment}"
  public_key = var.ssh_public_key

  tags = {
    Name        = "${var.project_name}-key-${var.environment}"
    Environment = var.environment
  }
}

# EC2 Instance Module
module "ec2" {
  source = "./modules/ec2"

  instance_name        = "${var.project_name}-web-${var.environment}"
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  subnet_id            = aws_subnet.public.id
  security_group_id    = aws_security_group.web.id
  key_name             = aws_key_pair.deployer.key_name
  environment          = var.environment
  iam_instance_profile = var.enable_monitoring ? aws_iam_instance_profile.cloudwatch[0].name : null

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Optional Bastion Host
module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "./modules/bastion"

  instance_name     = "${var.project_name}-bastion-${var.environment}"
  instance_type     = "t2.micro"
  ami_id            = var.ami_id
  subnet_id         = aws_subnet.public.id
  security_group_id = aws_security_group.bastion[0].id
  key_name          = aws_key_pair.deployer.key_name
  environment       = var.environment

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name        = "${var.project_name}-bastion-sg-${var.environment}"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-bastion-sg-${var.environment}"
    Environment = var.environment
  }
}
