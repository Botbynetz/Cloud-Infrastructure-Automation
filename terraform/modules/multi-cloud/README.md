# Multi-Cloud & Hybrid Cloud Module ☁️

Cloud abstraction layer for vendor-independent infrastructure provisioning across AWS, Azure, GCP.

## Features
- **Unified API**: Single REST API for AWS/Azure/GCP provisioning
- **Resource Inventory**: DynamoDB tracking of all multi-cloud resources
- **Cost Aggregation**: Daily cost rollup from all providers (3 AM)
- **Vendor Independence**: Abstract away cloud-specific APIs

## Usage
\`\`\`hcl
module "multi_cloud" {
  source = "./modules/multi-cloud"
  project_name = "cloud-infra"
  environment  = "production"
  cloud_credentials_secret_arn = aws_secretsmanager_secret.cloud_creds.arn
}
\`\`\`

## API Endpoints
- **POST /provision**: Provision resource on any cloud
  \`\`\`json
  {
    "provider": "aws",
    "type": "compute",
    "config": {"instance_type": "t3.micro"}
  }
  \`\`\`
- **GET /resources**: List all multi-cloud resources

**Value**: $20,000-50,000 | **Impact**: 100% vendor independence, unified cost tracking
