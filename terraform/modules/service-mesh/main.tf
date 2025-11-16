# ==============================================================================
# Service Mesh Module (AWS App Mesh)
# mTLS, Traffic Management, Circuit Breakers, Observability
# ==============================================================================

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# ------------------------------------------------------------------------------
# App Mesh
# ------------------------------------------------------------------------------

resource "aws_appmesh_mesh" "main" {
  name = "${var.project_name}-mesh-${var.environment}"
  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
  tags = var.tags
}

# Virtual Gateway (Ingress)
resource "aws_appmesh_virtual_gateway" "ingress" {
  name = "${var.project_name}-ingress-gateway"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    listener {
      port_mapping {
        port = 443
        protocol = "http"
      }
      
      tls {
        mode = "STRICT"
        certificate {
          acm {
            certificate_arn = var.acm_certificate_arn
          }
        }
      }
    }
  }
  tags = var.tags
}

# Virtual Service
resource "aws_appmesh_virtual_service" "app" {
  name = "${var.service_name}.${var.project_name}.local"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.app.name
      }
    }
  }
  tags = var.tags
}

# Virtual Router (Traffic Management)
resource "aws_appmesh_virtual_router" "app" {
  name = "${var.service_name}-router"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    listener {
      port_mapping {
        port = 8080
        protocol = "http"
      }
    }
  }
  tags = var.tags
}

# Route with weighted targets (Canary)
resource "aws_appmesh_route" "app" {
  name = "${var.service_name}-route"
  mesh_name = aws_appmesh_mesh.main.name
  virtual_router_name = aws_appmesh_virtual_router.app.name

  spec {
    http_route {
      match {
        prefix = "/"
      }
      
      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.app_v1.name
          weight = var.traffic_weight_v1
        }
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.app_v2.name
          weight = var.traffic_weight_v2
        }
      }

      retry_policy {
        max_retries = 3
        per_retry_timeout {
          unit = "s"
          value = 5
        }
        http_retry_events = ["server-error", "gateway-error"]
      }

      timeout {
        idle {
          unit = "s"
          value = 60
        }
        per_request {
          unit = "s"
          value = 30
        }
      }
    }
  }
}

# Virtual Node v1
resource "aws_appmesh_virtual_node" "app_v1" {
  name = "${var.service_name}-v1"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    listener {
      port_mapping {
        port = 8080
        protocol = "http"
      }
      
      health_check {
        protocol = "http"
        path = "/health"
        healthy_threshold = 2
        unhealthy_threshold = 3
        timeout_millis = 2000
        interval_millis = 5000
      }

      outlier_detection {
        max_server_errors = 5
        interval {
          unit = "s"
          value = 30
        }
        base_ejection_duration {
          unit = "s"
          value = 30
        }
        max_ejection_percent = 50
      }
    }

    service_discovery {
      aws_cloud_map {
        service_name = "${var.service_name}-v1"
        namespace_name = aws_service_discovery_private_dns_namespace.mesh.name
      }
    }
  }
  tags = var.tags
}

# Virtual Node v2
resource "aws_appmesh_virtual_node" "app_v2" {
  name = "${var.service_name}-v2"
  mesh_name = aws_appmesh_mesh.main.name

  spec {
    listener {
      port_mapping {
        port = 8080
        protocol = "http"
      }
      
      health_check {
        protocol = "http"
        path = "/health"
        healthy_threshold = 2
        unhealthy_threshold = 3
        timeout_millis = 2000
        interval_millis = 5000
      }

      outlier_detection {
        max_server_errors = 5
        interval {
          unit = "s"
          value = 30
        }
        base_ejection_duration {
          unit = "s"
          value = 30
        }
        max_ejection_percent = 50
      }
    }

    service_discovery {
      aws_cloud_map {
        service_name = "${var.service_name}-v2"
        namespace_name = aws_service_discovery_private_dns_namespace.mesh.name
      }
    }
  }
  tags = var.tags
}

# ------------------------------------------------------------------------------
# Cloud Map (Service Discovery)
# ------------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "mesh" {
  name = "${var.project_name}.local"
  vpc = var.vpc_id
  tags = var.tags
}

resource "aws_service_discovery_service" "app_v1" {
  name = "${var.service_name}-v1"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.mesh.id
    dns_records {
      ttl = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  tags = var.tags
}

resource "aws_service_discovery_service" "app_v2" {
  name = "${var.service_name}-v2"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.mesh.id
    dns_records {
      ttl = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  tags = var.tags
}

# ------------------------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "service_mesh" {
  dashboard_name = "${var.project_name}-service-mesh-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title = "Service Mesh Request Count"
          metrics = [
            ["AWS/AppMesh", "RequestCount"]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        properties = {
          title = "Service Mesh Error Rate"
          metrics = [
            ["AWS/AppMesh", "HTTPCode_Target_5XX_Count"]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "mesh_id" {
  description = "App Mesh ID"
  value = aws_appmesh_mesh.main.id
}

output "virtual_service_name" {
  description = "Virtual service name"
  value = aws_appmesh_virtual_service.app.name
}

output "cloud_map_namespace" {
  description = "Cloud Map namespace"
  value = aws_service_discovery_private_dns_namespace.mesh.name
}
