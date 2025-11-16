# Service Mesh Module 🕸️

AWS App Mesh with mTLS encryption, traffic management, circuit breakers, and service discovery.

## Features
- **mTLS Encryption**: Strict TLS between services
- **Traffic Management**: Weighted routing (90/10 canary default)
- **Circuit Breakers**: Outlier detection (5 errors → 30s ejection)
- **Health Checks**: HTTP /health endpoint (5s interval)
- **Retry Policy**: 3 retries with 5s timeout
- **Service Discovery**: AWS Cloud Map

## Usage
\`\`\`hcl
module "service_mesh" {
  source = "./modules/service-mesh"
  project_name = "cloud-infra"
  environment  = "production"
  vpc_id = module.networking.vpc_id
  acm_certificate_arn = "arn:aws:acm:..."
  service_name = "api"
  traffic_weight_v1 = 90  # Canary: 90% v1, 10% v2
  traffic_weight_v2 = 10
}
\`\`\`

## Architecture
- Virtual Gateway (TLS ingress)
- Virtual Service → Virtual Router → Virtual Nodes (v1 + v2)
- Cloud Map for DNS-based service discovery

**Value**: $18,000-30,000 | **Impact**: Zero-trust networking, advanced traffic control
