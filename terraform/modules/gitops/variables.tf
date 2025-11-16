variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "codestar_connection_arn" { type = string; description = "CodeStar connection ARN for GitHub" }
variable "git_repository" { type = string; description = "GitHub repo (owner/repo)" }
variable "git_branch" { type = string; default = "main" }
variable "sns_topic_arn" { type = string }
variable "tags" { type = map(string); default = {} }
