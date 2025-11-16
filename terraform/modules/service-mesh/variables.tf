variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string; default = "us-east-1" }
variable "vpc_id" { type = string; description = "VPC ID for Cloud Map" }
variable "acm_certificate_arn" { type = string; description = "ACM certificate for TLS" }
variable "service_name" { type = string; default = "app" }
variable "traffic_weight_v1" { type = number; default = 90; description = "Traffic weight for v1 (0-100)" }
variable "traffic_weight_v2" { type = number; default = 10; description = "Traffic weight for v2 (0-100)" }
variable "tags" { type = map(string); default = {} }
