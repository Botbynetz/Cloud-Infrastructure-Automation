variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "allowed_origins" { type = list(string); default = ["*"] }
variable "enable_auto_approve" { type = bool; default = false }
variable "tags" { type = map(string); default = {} }
