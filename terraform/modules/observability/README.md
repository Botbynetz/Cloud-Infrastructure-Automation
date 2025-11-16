# Observability 2.0 Module 📊

Unified observability platform: Metrics + Logs + Distributed Traces + SLO Management.

## Features
- **CloudWatch Logs**: Centralized logging with 30-day retention, KMS encryption
- **X-Ray Distributed Tracing**: 10% sampling, full request flow visibility
- **Synthetic Monitoring**: CloudWatch Canaries (5-min health checks)
- **SLO Burn Rate Alerts**: Composite alarms for error budget tracking
- **Unified Dashboard**: Request rate, errors (5XX), latency (P50/P95/P99), traces, canary success
- **CloudWatch Insights**: Pre-built SLO availability queries

## Usage
\`\`\`hcl
module "observability" {
  source = "./modules/observability"
  project_name = "cloud-infra"
  environment  = "production"
  log_retention_days = 30
  sns_topic_arn = module.monitoring.sns_topic_arn
}
\`\`\`

## SLO Tracking
- **Availability SLO**: 99.9% uptime target
- **Latency SLO**: P95 < 1s
- **Error Rate SLO**: < 0.1% 5XX errors
- **Composite Alarm**: Fires when error budget burn rate exceeds threshold

## Observability Pillars
1. **Metrics**: CloudWatch metrics (request rate, latency, errors)
2. **Logs**: Centralized CloudWatch Logs with Insights queries
3. **Traces**: X-Ray distributed tracing for request flows
4. **SLOs**: Error budget tracking with burn rate alerts

**Value**: $15,000-25,000 | **Impact**: Full-stack observability, proactive SLO management
