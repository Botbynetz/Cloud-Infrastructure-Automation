variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "log_retention_days" { type = number; default = 30 }
variable "kms_key_id" { type = string; default = null; description = "KMS key for log encryption" }
variable "sns_topic_arn" { type = string; description = "SNS topic for SLO alerts" }
variable "tags" { type = map(string); default = {} }
