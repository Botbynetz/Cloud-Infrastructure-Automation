# =============================================================================
# STEP 7: Enterprise Observability Stack - Prometheus & Grafana
# =============================================================================
# Enhanced monitoring solution integrating all previous steps
# Provides: Metrics, Logs, Traces, Dashboards, Alerts, SLOs

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

# =============================================================================
# DATA SOURCES - Integration with Previous Steps
# =============================================================================

# STEP 1: Get VPC and Subnet Information
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Type"
    values = ["private"]
  }
}

# STEP 2: Get KMS Key for Encryption
data "aws_kms_key" "main" {
  key_id = "alias/${var.environment}-kms-key"
}

# Get existing EKS cluster if available
data "aws_eks_cluster" "existing" {
  count = var.use_existing_eks ? 1 : 0
  name  = "${var.environment}-eks-cluster"
}

data "aws_eks_cluster_auth" "existing" {
  count = var.use_existing_eks ? 1 : 0
  name  = data.aws_eks_cluster.existing[0].name
}

# =============================================================================
# EKS CLUSTER FOR OBSERVABILITY (if needed)
# =============================================================================

# IAM Role for EKS Cluster
resource "aws_iam_role" "observability_cluster_role" {
  count = var.create_dedicated_cluster ? 1 : 0
  name  = "${var.environment}-observability-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-observability-cluster-role"
    Step = "7-observability"
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "observability_cluster_policy" {
  count      = var.create_dedicated_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.observability_cluster_role[0].name
}

# EKS Cluster for Observability Stack
resource "aws_eks_cluster" "observability" {
  count    = var.create_dedicated_cluster ? 1 : 0
  name     = "${var.environment}-observability-eks"
  role_arn = aws_iam_role.observability_cluster_role[0].arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true
    endpoint_public_access  = var.eks_public_access
    public_access_cidrs     = var.allowed_cidr_blocks
  }

  encryption_config {
    provider {
      key_arn = data.aws_kms_key.main.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.observability_cluster_policy[0],
    aws_cloudwatch_log_group.observability_cluster[0]
  ]

  tags = merge(var.tags, {
    Name        = "${var.environment}-observability-eks"
    Component   = "observability"
    Environment = var.environment
    Step        = "7-observability"
  })
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "observability_cluster" {
  count             = var.create_dedicated_cluster ? 1 : 0
  name              = "/aws/eks/${var.environment}-observability-eks/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = data.aws_kms_key.main.arn

  tags = merge(var.tags, {
    Name = "${var.environment}-observability-cluster-logs"
    Step = "7-observability"
  })
}

# IAM Role for Node Group
resource "aws_iam_role" "observability_node_role" {
  count = var.create_dedicated_cluster ? 1 : 0
  name  = "${var.environment}-observability-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-observability-node-role"
    Step = "7-observability"
  })
}

# Node Group Policies
resource "aws_iam_role_policy_attachment" "observability_worker_node_policy" {
  count      = var.create_dedicated_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.observability_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "observability_cni_policy" {
  count      = var.create_dedicated_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.observability_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "observability_ecr_policy" {
  count      = var.create_dedicated_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.observability_node_role[0].name
}

# EKS Node Group
resource "aws_eks_node_group" "observability" {
  count           = var.create_dedicated_cluster ? 1 : 0
  cluster_name    = aws_eks_cluster.observability[0].name
  node_group_name = "${var.environment}-observability-nodes"
  node_role_arn   = aws_iam_role.observability_node_role[0].arn
  subnet_ids      = data.aws_subnets.private.ids

  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.observability_worker_node_policy[0],
    aws_iam_role_policy_attachment.observability_cni_policy[0],
    aws_iam_role_policy_attachment.observability_ecr_policy[0],
  ]

  tags = merge(var.tags, {
    Name = "${var.environment}-observability-nodes"
    Step = "7-observability"
  })
}

# =============================================================================
# KUBERNETES PROVIDER CONFIGURATION
# =============================================================================

provider "kubernetes" {
  host                   = var.use_existing_eks ? data.aws_eks_cluster.existing[0].endpoint : aws_eks_cluster.observability[0].endpoint
  cluster_ca_certificate = base64decode(var.use_existing_eks ? data.aws_eks_cluster.existing[0].certificate_authority[0].data : aws_eks_cluster.observability[0].certificate_authority[0].data)
  token                  = var.use_existing_eks ? data.aws_eks_cluster_auth.existing[0].token : null
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.use_existing_eks ? data.aws_eks_cluster.existing[0].name : aws_eks_cluster.observability[0].name]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.use_existing_eks ? data.aws_eks_cluster.existing[0].endpoint : aws_eks_cluster.observability[0].endpoint
    cluster_ca_certificate = base64decode(var.use_existing_eks ? data.aws_eks_cluster.existing[0].certificate_authority[0].data : aws_eks_cluster.observability[0].certificate_authority[0].data)
    token                  = var.use_existing_eks ? data.aws_eks_cluster_auth.existing[0].token : null
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.use_existing_eks ? data.aws_eks_cluster.existing[0].name : aws_eks_cluster.observability[0].name]
    }
  }
}

# =============================================================================
# MONITORING NAMESPACE AND RBAC
# =============================================================================

# Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name                     = "monitoring"
      "pod-security.kubernetes.io/enforce" = "privileged"
      component                = "observability"
      environment              = var.environment
      step                     = "7-observability"
    }
  }
}

# Service Account for Prometheus
resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.prometheus_service_account.arn
    }
  }
}

# IAM Role for Prometheus Service Account (IRSA)
resource "aws_iam_role" "prometheus_service_account" {
  name = "${var.environment}-prometheus-service-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = var.use_existing_eks ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, "https://", "")}" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.observability[0].identity[0].oidc[0].issuer, "https://", "")}"
        }
        Condition = {
          StringEquals = {
            "${var.use_existing_eks ? replace(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, "https://", "") : replace(aws_eks_cluster.observability[0].identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:monitoring:prometheus"
            "${var.use_existing_eks ? replace(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, "https://", "") : replace(aws_eks_cluster.observability[0].identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.environment}-prometheus-service-account"
    Step = "7-observability"
  })
}

# CloudWatch access policy for Prometheus
resource "aws_iam_role_policy" "prometheus_cloudwatch" {
  name = "${var.environment}-prometheus-cloudwatch"
  role = aws_iam_role.prometheus_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# =============================================================================
# STORAGE CLASS FOR PERSISTENT VOLUMES
# =============================================================================

resource "kubernetes_storage_class" "monitoring_storage" {
  metadata {
    name = "monitoring-gp3"
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Retain"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = data.aws_kms_key.main.arn
    iops      = "3000"
    throughput = "125"
  }
}

# =============================================================================
# S3 BUCKET FOR LONG-TERM STORAGE
# =============================================================================

resource "aws_s3_bucket" "observability_storage" {
  bucket = "${var.project_name}-observability-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-observability-${var.environment}"
    Purpose     = "Long-term metrics and logs storage"
    Component   = "observability"
    Environment = var.environment
    Step        = "7-observability"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "observability_storage" {
  bucket = aws_s3_bucket.observability_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "observability_storage" {
  bucket = aws_s3_bucket.observability_storage.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = data.aws_kms_key.main.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "observability_storage" {
  bucket = aws_s3_bucket.observability_storage.id

  rule {
    id     = "observability_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.long_term_retention_days
    }
  }
}

# =============================================================================
# PROMETHEUS STACK DEPLOYMENT
# =============================================================================

# Prometheus Operator CRDs (install first)
resource "helm_release" "prometheus_operator_crds" {
  name       = "prometheus-operator-crds"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-operator-crds"
  version    = var.prometheus_operator_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # This chart only installs CRDs and has no values
  timeout = 300
}

# kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml", {
      environment                = var.environment
      storage_class             = kubernetes_storage_class.monitoring_storage.metadata[0].name
      prometheus_retention      = var.prometheus_retention
      prometheus_storage_size   = var.prometheus_storage_size
      grafana_admin_password    = var.grafana_admin_password
      slack_webhook_url         = var.slack_webhook_url
      slack_channel            = var.slack_channel
      pagerduty_service_key    = var.pagerduty_service_key
      alertmanager_retention   = var.alertmanager_retention
      enable_ingress          = var.enable_ingress
      domain_name             = var.domain_name
      ssl_certificate_arn     = var.ssl_certificate_arn
      prometheus_service_account = kubernetes_service_account.prometheus.metadata[0].name
      s3_bucket               = aws_s3_bucket.observability_storage.bucket
      aws_region              = var.aws_region
      kms_key_id              = data.aws_kms_key.main.arn
      cost_threshold_dev      = var.cost_threshold_dev
      cost_threshold_staging  = var.cost_threshold_staging
      cost_threshold_prod     = var.cost_threshold_prod
      cost_threshold_dr       = var.cost_threshold_dr
    })
  ]

  depends_on = [
    helm_release.prometheus_operator_crds,
    kubernetes_service_account.prometheus,
    kubernetes_storage_class.monitoring_storage
  ]

  timeout = 900 # 15 minutes
}

# =============================================================================
# ADDITIONAL MONITORING COMPONENTS
# =============================================================================

# CloudWatch Exporter for AWS metrics
resource "helm_release" "cloudwatch_exporter" {
  name       = "cloudwatch-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-cloudwatch-exporter"
  version    = var.cloudwatch_exporter_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/cloudwatch-exporter-values.yaml", {
      environment = var.environment
      aws_region  = var.aws_region
      service_account_name = kubernetes_service_account.prometheus.metadata[0].name
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

# Node Exporter (if not using managed EKS nodes)
resource "helm_release" "node_exporter" {
  count      = var.enable_node_exporter ? 1 : 0
  name       = "node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"
  version    = var.node_exporter_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/node-exporter-values.yaml", {
      environment = var.environment
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

# Thanos for Long-term Storage (optional)
resource "helm_release" "thanos" {
  count      = var.enable_thanos ? 1 : 0
  name       = "thanos"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "thanos"
  version    = var.thanos_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/thanos-values.yaml", {
      environment   = var.environment
      s3_bucket     = aws_s3_bucket.observability_storage.bucket
      aws_region    = var.aws_region
      storage_class = kubernetes_storage_class.monitoring_storage.metadata[0].name
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}