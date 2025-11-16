# GitOps & Advanced CI/CD Module 🔄

Git as single source of truth with CodePipeline, progressive delivery, and DORA metrics tracking.

## Features
- **CodePipeline**: 3-stage (Source → Build → Deploy)
- **Progressive Delivery**: Canary deployments (10% → 100%)
- **DORA Metrics**: Deployment frequency, lead time, MTTR, failure rate
- **Deployment Tracking**: DynamoDB audit trail with 90-day retention

## Usage
\`\`\`hcl
module "gitops" {
  source = "./modules/gitops"
  project_name = "cloud-infra"
  environment  = "production"
  codestar_connection_arn = "arn:aws:codestar-connections:..."
  git_repository = "owner/repo"
  git_branch = "main"
  sns_topic_arn = module.monitoring.sns_topic_arn
}
\`\`\`

## DORA Metrics (Daily Calculation at 1 AM)
1. **Deployment Frequency**: Deployments per day
2. **Lead Time for Changes**: Commit to production (minutes)
3. **Mean Time to Recovery**: Incident resolution time
4. **Change Failure Rate**: Failed deployment percentage

**Value**: $15,000-25,000 | **Impact**: Git-driven automation, elite DORA performance
