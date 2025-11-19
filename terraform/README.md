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


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 3.20 |

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 ~> 5.0 |

## Modules

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ./modules/bastion | n/a |
| <a name="module_ec2"></a> [ec2](#module\_ec2) | ./modules/ec2 | n/a |

## Resources

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.nginx_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.nginx_error](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.syslog](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.high_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_disk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_memory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.instance_health](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_instance_profile.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.deployer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional custom tags | `map(string)` | `{}` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for EC2 instance (Ubuntu 22.04 LTS) | `string` | `"ami-0dc2d3e4c0f9ebd18"` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Application name | `string` | `""` | no |
| <a name="input_application_version"></a> [application\_version](#input\_application\_version) | Application version | `string` | `""` | no |
| <a name="input_auto_shutdown_enabled"></a> [auto\_shutdown\_enabled](#input\_auto\_shutdown\_enabled) | Enable auto-shutdown for cost optimization | `bool` | `false` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability zone for subnet | `string` | `"ap-southeast-1a"` | no |
| <a name="input_aws_assume_role_arn"></a> [aws\_assume\_role\_arn](#input\_aws\_assume\_role\_arn) | AWS IAM role ARN to assume (optional) | `string` | `""` | no |
| <a name="input_aws_dr_region"></a> [aws\_dr\_region](#input\_aws\_dr\_region) | DR AWS region | `string` | `"us-west-2"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"ap-southeast-1"` | no |
| <a name="input_azure_client_id"></a> [azure\_client\_id](#input\_azure\_client\_id) | Azure service principal client ID | `string` | `""` | no |
| <a name="input_azure_client_secret"></a> [azure\_client\_secret](#input\_azure\_client\_secret) | Azure service principal client secret | `string` | `""` | no |
| <a name="input_azure_skip_provider_registration"></a> [azure\_skip\_provider\_registration](#input\_azure\_skip\_provider\_registration) | Skip Azure provider registration | `bool` | `false` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Azure subscription ID | `string` | `""` | no |
| <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id) | Azure tenant ID | `string` | `""` | no |
| <a name="input_backup_policy"></a> [backup\_policy](#input\_backup\_policy) | Backup policy | `string` | `"none"` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Business unit name (MANDATORY) | `string` | n/a | yes |
| <a name="input_compliance_framework"></a> [compliance\_framework](#input\_compliance\_framework) | Compliance framework requirements (comma-separated) | `string` | `"none"` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for billing allocation (MANDATORY) | `string` | n/a | yes |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Data classification level (MANDATORY for compliance) | `string` | n/a | yes |
| <a name="input_deployed_by"></a> [deployed\_by](#input\_deployed\_by) | Who deployed this resource (user or CI/CD system) | `string` | `"terraform-automation"` | no |
| <a name="input_dr_rpo"></a> [dr\_rpo](#input\_dr\_rpo) | Disaster Recovery Recovery Point Objective | `string` | `"24h"` | no |
| <a name="input_dr_rto"></a> [dr\_rto](#input\_dr\_rto) | Disaster Recovery Recovery Time Objective | `string` | `"24h"` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | Enable bastion host for secure access | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable CloudWatch monitoring and alarms | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_gcp_additional_labels"></a> [gcp\_additional\_labels](#input\_gcp\_additional\_labels) | Additional labels for GCP resources | `map(string)` | `{}` | no |
| <a name="input_gcp_credentials_file"></a> [gcp\_credentials\_file](#input\_gcp\_credentials\_file) | Path to GCP service account credentials JSON file | `string` | `""` | no |
| <a name="input_gcp_dr_region"></a> [gcp\_dr\_region](#input\_gcp\_dr\_region) | DR GCP region | `string` | `"us-west1"` | no |
| <a name="input_gcp_dr_zone"></a> [gcp\_dr\_zone](#input\_gcp\_dr\_zone) | DR GCP zone | `string` | `"us-west1-a"` | no |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | GCP project ID | `string` | `""` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | Primary GCP region | `string` | `"asia-southeast1"` | no |
| <a name="input_gcp_zone"></a> [gcp\_zone](#input\_gcp\_zone) | Primary GCP zone | `string` | `"asia-southeast1-a"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | `"t2.micro"` | no |
| <a name="input_lifecycle_stage"></a> [lifecycle\_stage](#input\_lifecycle\_stage) | Lifecycle stage of resources | `string` | `"active"` | no |
| <a name="input_owner_email"></a> [owner\_email](#input\_owner\_email) | Email of the resource owner (MANDATORY) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"cloud-infra"` | no |
| <a name="input_public_subnet_cidr"></a> [public\_subnet\_cidr](#input\_public\_subnet\_cidr) | CIDR block for public subnet | `string` | `"10.0.1.0/24"` | no |
| <a name="input_repository_url"></a> [repository\_url](#input\_repository\_url) | Git repository URL | `string` | `"https://github.com/Botbynetz/Cloud-Infrastructure-Automation"` | no |
| <a name="input_service_level"></a> [service\_level](#input\_service\_level) | Service level agreement tier | `string` | `"bronze"` | no |
| <a name="input_shutdown_schedule"></a> [shutdown\_schedule](#input\_shutdown\_schedule) | Auto-shutdown schedule (e.g., weekdays-after-hours, weekends) | `string` | `"disabled"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key for EC2 access | `string` | n/a | yes |
| <a name="input_vault_address"></a> [vault\_address](#input\_vault\_address) | HashiCorp Vault server address | `string` | `"https://vault.example.com:8200"` | no |
| <a name="input_vault_token"></a> [vault\_token](#input\_vault\_token) | HashiCorp Vault authentication token | `string` | `""` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP address of the bastion host |
| <a name="output_cloudwatch_log_groups"></a> [cloudwatch\_log\_groups](#output\_cloudwatch\_log\_groups) | CloudWatch log group names |
| <a name="output_common_tags"></a> [common\_tags](#output\_common\_tags) | Common tags to be applied to all resources |
| <a name="output_ec2_instance_id"></a> [ec2\_instance\_id](#output\_ec2\_instance\_id) | ID of the EC2 instance |
| <a name="output_ec2_public_dns"></a> [ec2\_public\_dns](#output\_ec2\_public\_dns) | Public DNS name of the EC2 instance |
| <a name="output_ec2_public_ip"></a> [ec2\_public\_ip](#output\_ec2\_public\_ip) | Public IP address of the EC2 instance |
| <a name="output_mandatory_tags"></a> [mandatory\_tags](#output\_mandatory\_tags) | Mandatory tags only (for validation) |
| <a name="output_public_subnet_id"></a> [public\_subnet\_id](#output\_public\_subnet\_id) | ID of the public subnet |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group |
| <a name="output_ssh_connection_command"></a> [ssh\_connection\_command](#output\_ssh\_connection\_command) | SSH command to connect to the EC2 instance |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
| <a name="output_website_url"></a> [website\_url](#output\_website\_url) | URL to access the website |
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
