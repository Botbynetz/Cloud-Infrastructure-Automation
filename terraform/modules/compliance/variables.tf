variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "sns_topic_arn" { type = string; description = "SNS topic for compliance alerts" }
variable "enable_auto_remediation" { type = bool; default = false; description = "Enable automatic remediation of non-compliant resources" }
variable "tags" { type = map(string); default = {} }
