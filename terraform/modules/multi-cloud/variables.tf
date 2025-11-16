variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "cloud_credentials_secret_arn" { type = string; description = "Secrets Manager ARN for Azure/GCP credentials" }
variable "tags" { type = map(string); default = {} }
