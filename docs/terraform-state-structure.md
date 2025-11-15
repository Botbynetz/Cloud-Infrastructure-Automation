# Terraform State Structure Example

This document shows the structure of the Terraform state file stored in S3.

## State File Location

```
S3 Bucket: cloud-infra-terraform-state-ACCOUNT_ID
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate

DynamoDB Table: cloud-infra-lock
├── LockID (Hash Key)
└── Items per environment
```

## State File Structure (Simplified)

```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 1,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "ec2_instance_id": {
      "value": "i-0a1b2c3d4e5f67890",
      "type": "string"
    },
    "ec2_public_ip": {
      "value": "13.213.45.67",
      "type": "string"
    },
    "ec2_private_ip": {
      "value": "10.0.1.100",
      "type": "string"
    },
    "vpc_id": {
      "value": "vpc-0a1b2c3d4e5f67890",
      "type": "string"
    },
    "subnet_id": {
      "value": "subnet-0a1b2c3d4e5f67890",
      "type": "string"
    },
    "security_group_id": {
      "value": "sg-0a1b2c3d4e5f67890",
      "type": "string"
    },
    "website_url": {
      "value": "http://13.213.45.67",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_vpc",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "vpc-0a1b2c3d4e5f67890",
            "arn": "arn:aws:ec2:ap-southeast-1:123456789012:vpc/vpc-0a1b2c3d4e5f67890",
            "cidr_block": "10.0.0.0/16",
            "enable_dns_hostnames": true,
            "enable_dns_support": true,
            "tags": {
              "Name": "cloud-infra-vpc-dev",
              "Environment": "dev",
              "Project": "cloud-infra",
              "ManagedBy": "Terraform"
            }
          }
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_subnet",
      "name": "public",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "subnet-0a1b2c3d4e5f67890",
            "vpc_id": "vpc-0a1b2c3d4e5f67890",
            "cidr_block": "10.0.1.0/24",
            "availability_zone": "ap-southeast-1a",
            "map_public_ip_on_launch": true,
            "tags": {
              "Name": "cloud-infra-public-subnet-dev",
              "Environment": "dev"
            }
          },
          "dependencies": [
            "aws_vpc.main"
          ]
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_internet_gateway",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "igw-0a1b2c3d4e5f67890",
            "vpc_id": "vpc-0a1b2c3d4e5f67890",
            "tags": {
              "Name": "cloud-infra-igw-dev",
              "Environment": "dev"
            }
          },
          "dependencies": [
            "aws_vpc.main"
          ]
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_security_group",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "sg-0a1b2c3d4e5f67890",
            "name": "cloud-infra-web-sg-dev",
            "vpc_id": "vpc-0a1b2c3d4e5f67890",
            "ingress": [
              {
                "from_port": 22,
                "to_port": 22,
                "protocol": "tcp",
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "SSH"
              },
              {
                "from_port": 80,
                "to_port": 80,
                "protocol": "tcp",
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "HTTP"
              },
              {
                "from_port": 443,
                "to_port": 443,
                "protocol": "tcp",
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "HTTPS"
              }
            ],
            "egress": [
              {
                "from_port": 0,
                "to_port": 0,
                "protocol": "-1",
                "cidr_blocks": ["0.0.0.0/0"],
                "description": "All outbound traffic"
              }
            ]
          },
          "dependencies": [
            "aws_vpc.main"
          ]
        }
      ]
    },
    {
      "module": "module.ec2",
      "mode": "managed",
      "type": "aws_instance",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0a1b2c3d4e5f67890",
            "ami": "ami-0dc2d3e4c0f9ebd18",
            "instance_type": "t2.micro",
            "key_name": "cloud-infra-key-dev",
            "subnet_id": "subnet-0a1b2c3d4e5f67890",
            "vpc_security_group_ids": ["sg-0a1b2c3d4e5f67890"],
            "public_ip": "13.213.45.67",
            "private_ip": "10.0.1.100",
            "public_dns": "ec2-13-213-45-67.ap-southeast-1.compute.amazonaws.com",
            "tags": {
              "Name": "cloud-infra-web-dev",
              "Environment": "dev",
              "Project": "cloud-infra",
              "ManagedBy": "Terraform"
            },
            "root_block_device": [
              {
                "volume_type": "gp3",
                "volume_size": 20,
                "encrypted": true,
                "delete_on_termination": true
              }
            ]
          },
          "dependencies": [
            "aws_subnet.public",
            "aws_security_group.web",
            "aws_key_pair.deployer"
          ]
        }
      ]
    }
  ],
  "check_results": null
}
```

## DynamoDB Lock Item Structure

```json
{
  "LockID": {
    "S": "cloud-infra-terraform-state-ACCOUNT_ID/dev/terraform.tfstate-md5"
  },
  "Info": {
    "S": "{\"ID\":\"a1b2c3d4-e5f6-7890-abcd-ef1234567890\",\"Operation\":\"OperationTypeApply\",\"Info\":\"\",\"Who\":\"user@hostname\",\"Version\":\"1.6.0\",\"Created\":\"2025-11-15T10:30:45.123456Z\",\"Path\":\"cloud-infra-terraform-state-ACCOUNT_ID/dev/terraform.tfstate\"}"
  }
}
```

## State Commands

### View State
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Show all outputs
terraform output
```

### Remote State Access
```bash
# Pull remote state to local
terraform state pull > terraform.tfstate.backup

# Push local state to remote (DANGEROUS!)
# terraform state push terraform.tfstate
```

### State Inspection
```bash
# Show state in human-readable format
terraform show

# Show state in JSON format
terraform show -json > state.json
```

## Example State List Output

```
aws_internet_gateway.main
aws_key_pair.deployer
aws_route_table.public
aws_route_table_association.public
aws_security_group.web
aws_subnet.public
aws_vpc.main
module.ec2.aws_instance.main
```

## State File Versioning in S3

S3 versioning is enabled, so you can recover previous states:

```bash
# List all versions
aws s3api list-object-versions \
  --bucket cloud-infra-terraform-state-ACCOUNT_ID \
  --prefix dev/terraform.tfstate

# Restore specific version
aws s3api get-object \
  --bucket cloud-infra-terraform-state-ACCOUNT_ID \
  --key dev/terraform.tfstate \
  --version-id VERSION_ID \
  terraform.tfstate.restored
```

## State Locking

When running terraform apply/plan:
1. Terraform acquires lock in DynamoDB
2. LockID is created with operation info
3. State file is updated in S3
4. Lock is released after operation

If lock exists, you'll see:
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Path:      cloud-infra-terraform-state-ACCOUNT_ID/dev/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.6.0
  Created:   2025-11-15 10:30:45.123456 +0000 UTC
```

## Best Practices

1. **Never edit state files manually**
2. **Use `terraform state` commands for modifications**
3. **Enable S3 versioning for state recovery**
4. **Use DynamoDB locking to prevent concurrent modifications**
5. **Backup state before major changes**
6. **Encrypt state files (S3 encryption enabled)**
7. **Restrict S3 bucket access with IAM policies**
