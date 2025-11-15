locals {
  # Determine service principal based on role type
  service_principals = {
    ec2      = "ec2.amazonaws.com"
    lambda   = "lambda.amazonaws.com"
    ecs      = "ecs-tasks.amazonaws.com"
    user     = null
    federated = null
  }
  
  service_principal = lookup(local.service_principals, var.role_type, "ec2.amazonaws.com")
  
  # Compliance-specific settings
  compliance_settings = {
    standard = {
      max_session = 3600
      require_mfa = false
    }
    pci-dss = {
      max_session = 900
      require_mfa = true
    }
    hipaa = {
      max_session = 1800
      require_mfa = true
    }
    soc2 = {
      max_session = 3600
      require_mfa = true
    }
  }
  
  effective_max_session = var.max_session_duration != 3600 ? var.max_session_duration : local.compliance_settings[var.compliance_level].max_session
  effective_require_mfa = var.require_mfa || local.compliance_settings[var.compliance_level].require_mfa
}

# Assume Role Policy Document
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = var.role_type == "federated" ? "Federated" : (
        var.role_type == "user" ? "AWS" : "Service"
      )
      identifiers = var.role_type == "federated" ? [var.federated_principal] : (
        var.role_type == "user" ? [for account in var.trusted_accounts : "arn:aws:iam::${account}:root"] : 
        [local.service_principal]
      )
    }

    actions = ["sts:AssumeRole"]

    dynamic "condition" {
      for_each = local.effective_require_mfa ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }

    dynamic "condition" {
      for_each = local.effective_require_mfa ? [1] : []
      content {
        test     = "NumericLessThan"
        variable = "aws:MultiFactorAuthAge"
        values   = [var.mfa_age_limit]
      }
    }

    dynamic "condition" {
      for_each = var.condition != null ? [var.condition] : []
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

# IAM Role
resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = local.effective_max_session
  permissions_boundary = var.permission_boundary

  tags = merge(
    var.tags,
    {
      Name           = var.role_name
      ManagedBy      = "terraform"
      ComplianceLevel = var.compliance_level
      RequiresMFA    = tostring(local.effective_require_mfa)
    }
  )
}

# Custom Policy Document
data "aws_iam_policy_document" "custom" {
  count = length(var.permissions) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = var.permissions
    resources = var.resource_arns
  }
}

# Custom IAM Policy
resource "aws_iam_policy" "custom" {
  count = length(var.permissions) > 0 ? 1 : 0

  name        = "${var.role_name}-policy"
  description = "Custom policy for ${var.role_name}"
  policy      = data.aws_iam_policy_document.custom[0].json

  tags = var.tags
}

# Attach Custom Policy to Role
resource "aws_iam_role_policy_attachment" "custom" {
  count = length(var.permissions) > 0 ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Session Manager Policy (if enabled)
data "aws_iam_policy_document" "session_manager" {
  count = var.enable_session_manager ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/ssm/*"]
  }
}

resource "aws_iam_policy" "session_manager" {
  count = var.enable_session_manager ? 1 : 0

  name        = "${var.role_name}-session-manager"
  description = "Allow Session Manager access for ${var.role_name}"
  policy      = data.aws_iam_policy_document.session_manager[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "session_manager" {
  count = var.enable_session_manager ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.session_manager[0].arn
}

# CloudWatch Logs Policy
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/ec2/${var.role_name}*",
      "arn:aws:logs:*:*:log-group:/aws/lambda/${var.role_name}*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.role_name}-cloudwatch-logs"
  description = "CloudWatch Logs policy for ${var.role_name}"
  policy      = data.aws_iam_policy_document.cloudwatch_logs.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# Instance Profile (for EC2 roles)
resource "aws_iam_instance_profile" "this" {
  count = var.role_type == "ec2" ? 1 : 0

  name = "${var.role_name}-profile"
  role = aws_iam_role.this.name

  tags = var.tags
}

# IAM Access Analyzer
resource "aws_accessanalyzer_analyzer" "role_analyzer" {
  count = var.enable_cloudtrail_logging ? 1 : 0

  analyzer_name = "${var.role_name}-analyzer"
  type          = "ACCOUNT"

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-access-analyzer"
      ManagedBy = "terraform"
    }
  )
}
