output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "Unique identifier for the IAM role"
  value       = aws_iam_role.this.unique_id
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (for EC2 roles)"
  value       = var.role_type == "ec2" ? aws_iam_instance_profile.this[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (for EC2 roles)"
  value       = var.role_type == "ec2" ? aws_iam_instance_profile.this[0].name : null
}

output "policy_arns" {
  description = "List of all policy ARNs attached to the role"
  value = concat(
    length(var.permissions) > 0 ? [aws_iam_policy.custom[0].arn] : [],
    var.enable_session_manager ? [aws_iam_policy.session_manager[0].arn] : [],
    [aws_iam_policy.cloudwatch_logs.arn]
  )
}

output "custom_policy_arn" {
  description = "ARN of the custom IAM policy"
  value       = length(var.permissions) > 0 ? aws_iam_policy.custom[0].arn : null
}

output "session_manager_policy_arn" {
  description = "ARN of the Session Manager policy"
  value       = var.enable_session_manager ? aws_iam_policy.session_manager[0].arn : null
}

output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch Logs policy"
  value       = aws_iam_policy.cloudwatch_logs.arn
}

output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer"
  value       = var.enable_cloudtrail_logging ? aws_accessanalyzer_analyzer.role_analyzer[0].arn : null
}

output "max_session_duration" {
  description = "Maximum session duration for the role"
  value       = aws_iam_role.this.max_session_duration
}

output "requires_mfa" {
  description = "Whether the role requires MFA"
  value       = local.effective_require_mfa
}
