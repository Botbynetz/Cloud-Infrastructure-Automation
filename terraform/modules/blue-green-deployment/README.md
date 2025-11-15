# Blue-Green Deployment Module

Terraform module for implementing zero-downtime deployments using AWS Application Load Balancer (ALB) with blue-green, canary, and rolling deployment strategies.

## 🎯 Features

- **Zero-Downtime Deployments**: Switch traffic between blue and green environments without downtime
- **Multiple Deployment Strategies**: Support for blue-green, canary, and rolling deployments
- **Health-Based Routing**: Automatic health checks with configurable thresholds
- **Test Traffic Routing**: Separate listener for testing inactive environment
- **Weighted Traffic Distribution**: Gradual traffic shifting for canary deployments
- **Auto Scaling Integration**: Seamless integration with AWS Auto Scaling groups
- **CloudWatch Monitoring**: Built-in alarms and dashboards for deployment monitoring
- **HTTPS/SSL Support**: Optional HTTPS listener with configurable SSL policies
- **Sticky Sessions**: Optional session affinity for stateful applications

## 📋 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Application Load Balancer              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │ Listener   │  │ Listener   │  │ Listener   │       │
│  │ :80 (HTTP) │  │ :443(HTTPS)│  │ :8080(Test)│       │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘       │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
          │  Production    │                │  Test Traffic
          │  Traffic       │                │
          └────────┬───────┘                │
                   │                        │
        ┌──────────▼──────────┐   ┌────────▼────────┐
        │   Active Target     │   │  Inactive Target│
        │   Group (Blue)      │   │  Group (Green)  │
        │                     │   │                 │
        │  ┌────┐  ┌────┐    │   │  ┌────┐ ┌────┐ │
        │  │EC2 │  │EC2 │    │   │  │EC2 │ │EC2 │ │
        │  └────┘  └────┘    │   │  └────┘ └────┘ │
        └─────────────────────┘   └─────────────────┘
```

## 🚀 Usage

### Basic Blue-Green Deployment

```hcl
module "blue_green_deployment" {
  source = "./modules/blue-green-deployment"

  application_name    = "my-app"
  vpc_id             = "vpc-12345678"
  alb_subnets        = ["subnet-abc123", "subnet-def456"]
  alb_security_groups = ["sg-12345678"]

  # Active environment
  active_environment = "blue"

  # Health check configuration
  health_check_path              = "/health"
  health_check_interval          = 30
  health_check_healthy_threshold = 2

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### With HTTPS and SSL Certificate

```hcl
module "blue_green_deployment" {
  source = "./modules/blue-green-deployment"

  application_name    = "my-app"
  vpc_id             = "vpc-12345678"
  alb_subnets        = ["subnet-abc123", "subnet-def456"]
  alb_security_groups = ["sg-12345678"]

  # Enable HTTPS
  enable_https    = true
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  active_environment = "blue"
}
```

### Canary Deployment (10% Traffic to New Version)

```hcl
module "blue_green_deployment" {
  source = "./modules/blue-green-deployment"

  application_name    = "my-app"
  vpc_id             = "vpc-12345678"
  alb_subnets        = ["subnet-abc123", "subnet-def456"]
  alb_security_groups = ["sg-12345678"]

  active_environment = "blue"

  # Enable canary deployment
  enable_canary_deployment = true
  canary_weight_active     = 90   # 90% to blue (old version)
  canary_weight_inactive   = 10   # 10% to green (new version)
}
```

### With Auto Scaling Integration

```hcl
module "blue_green_deployment" {
  source = "./modules/blue-green-deployment"

  application_name    = "my-app"
  vpc_id             = "vpc-12345678"
  alb_subnets        = ["subnet-abc123", "subnet-def456"]
  alb_security_groups = ["sg-12345678"]

  active_environment = "blue"

  # Auto Scaling integration
  enable_autoscaling            = true
  blue_autoscaling_group_name   = "my-app-blue-asg"
  green_autoscaling_group_name  = "my-app-green-asg"
}
```

### With CloudWatch Monitoring

```hcl
module "blue_green_deployment" {
  source = "./modules/blue-green-deployment"

  application_name    = "my-app"
  vpc_id             = "vpc-12345678"
  alb_subnets        = ["subnet-abc123", "subnet-def456"]
  alb_security_groups = ["sg-12345678"]

  active_environment = "blue"

  # Monitoring configuration
  enable_cloudwatch_dashboard    = true
  alarm_sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:alerts"
  unhealthy_host_alarm_threshold = 1
  response_time_threshold        = 1.0  # 1 second
}
```

## 📝 Deployment Workflow

### 1. Initial Deployment (Blue Active)

```bash
# Deploy blue environment
terraform apply -var="active_environment=blue"

# Application is live on blue target group
# Green target group is idle
```

### 2. Deploy New Version to Green

```bash
# Deploy new application version to green instances
# Green target group receives the new version
# Blue continues serving production traffic
```

### 3. Test Green Environment

```bash
# Access green environment via test listener
curl http://<alb-dns-name>:8080/health

# Run smoke tests against green environment
# If tests pass, proceed to cutover
```

### 4. Canary Cutover (Optional)

```bash
# Gradually shift traffic to green
terraform apply \
  -var="enable_canary_deployment=true" \
  -var="canary_weight_active=90" \
  -var="canary_weight_inactive=10"

# Monitor metrics, increase green traffic gradually
# 10% → 25% → 50% → 75% → 100%
```

### 5. Full Cutover to Green

```bash
# Switch all traffic to green
terraform apply -var="active_environment=green"

# Green is now production
# Blue becomes idle and ready for next deployment
```

### 6. Rollback (If Needed)

```bash
# Instant rollback to blue
terraform apply -var="active_environment=blue"

# Traffic switches back to blue immediately
```

## 🎛️ Deployment Strategies

### Blue-Green Deployment

**Use Case**: Full cutover with instant rollback capability

```hcl
active_environment       = "blue"
enable_canary_deployment = false
```

**Process**:
1. Deploy to inactive environment (green)
2. Test thoroughly via test listener
3. Switch `active_environment` to "green"
4. Apply changes - instant cutover
5. Keep blue idle for quick rollback

**Pros**: Instant cutover, instant rollback, no complex logic  
**Cons**: Doubles infrastructure cost during deployment

---

### Canary Deployment

**Use Case**: Gradual rollout with real-user testing

```hcl
active_environment       = "blue"
enable_canary_deployment = true
canary_weight_active     = 90  # 90% old version
canary_weight_inactive   = 10  # 10% new version
```

**Process**:
1. Deploy to green (inactive)
2. Enable canary with 10% traffic to green
3. Monitor metrics and errors
4. Gradually increase green traffic: 10% → 25% → 50% → 100%
5. Disable canary, switch active_environment

**Pros**: Risk mitigation, gradual validation, A/B testing  
**Cons**: More complex, longer deployment time

---

### Rolling Deployment

**Use Case**: Incremental updates within same target group

```hcl
deregistration_delay             = 30
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3
```

**Process**:
1. Use Auto Scaling group with both blue and green instances
2. Update instances gradually via ASG update policy
3. Health checks ensure smooth transitions
4. No full environment switch needed

**Pros**: Simple, cost-effective, no downtime  
**Cons**: No instant rollback, harder to test

## 📊 Monitoring & Alerting

### CloudWatch Alarms

The module creates the following alarms:

1. **Unhealthy Host Count (Blue)**
   - Triggers when blue target group has unhealthy instances
   - Threshold: Configurable (default: 1)

2. **Unhealthy Host Count (Green)**
   - Triggers when green target group has unhealthy instances
   - Threshold: Configurable (default: 1)

3. **High Response Time**
   - Triggers when ALB response time exceeds threshold
   - Threshold: Configurable (default: 1 second)

### CloudWatch Dashboard

Automatically created dashboard includes:

- **Target Health Status**: Healthy/unhealthy host counts for both environments
- **Request Count**: Total requests per minute
- **Response Time**: Average target response time
- **HTTP Status Codes**: Distribution of 2xx, 4xx, 5xx responses

### Metrics to Monitor

```bash
# Check target health
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HealthyHostCount \
  --dimensions Name=TargetGroup,Value=<target-group-arn-suffix> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average

# Check request count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=<alb-arn-suffix> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Sum
```

## 🔧 Configuration Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `application_name` | string | Application name for resource naming |
| `vpc_id` | string | VPC ID where resources will be created |
| `alb_subnets` | list(string) | Subnet IDs for ALB (min 2 AZs) |
| `alb_security_groups` | list(string) | Security group IDs for ALB |

### Deployment Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `active_environment` | string | `"blue"` | Active environment (blue or green) |
| `test_traffic_port` | number | `8080` | Port for test traffic to inactive env |
| `enable_canary_deployment` | bool | `false` | Enable canary deployment |
| `canary_weight_active` | number | `90` | Traffic % to active environment |
| `canary_weight_inactive` | number | `10` | Traffic % to inactive environment |

### Health Check Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `health_check_path` | string | `"/health"` | Health check endpoint |
| `health_check_interval` | number | `30` | Interval between checks (seconds) |
| `health_check_timeout` | number | `5` | Health check timeout (seconds) |
| `health_check_healthy_threshold` | number | `2` | Healthy threshold count |
| `health_check_unhealthy_threshold` | number | `3` | Unhealthy threshold count |
| `health_check_matcher` | string | `"200-299"` | Successful HTTP status codes |

### Monitoring Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_cloudwatch_dashboard` | bool | `true` | Enable CloudWatch dashboard |
| `alarm_sns_topic_arn` | string | `""` | SNS topic for alarm notifications |
| `unhealthy_host_alarm_threshold` | number | `1` | Unhealthy host count threshold |
| `response_time_threshold` | number | `1.0` | Response time threshold (seconds) |

## 📤 Outputs

### Load Balancer Outputs

- `alb_dns_name`: ALB DNS name
- `alb_arn`: ALB ARN
- `alb_zone_id`: ALB Route 53 zone ID

### Target Group Outputs

- `blue_target_group_arn`: Blue target group ARN
- `green_target_group_arn`: Green target group ARN
- `active_target_group_arn`: Currently active target group ARN
- `inactive_target_group_arn`: Currently inactive target group ARN

### Deployment Information

- `deployment_info`: Comprehensive deployment details
- `switch_commands`: Commands for environment switching
- `test_urls`: URLs for testing both environments

## 🛠️ Prerequisites

1. **AWS Provider**: >= 5.0
2. **Terraform**: >= 1.6.0
3. **VPC Setup**: VPC with at least 2 subnets in different AZs
4. **Security Groups**: Configured ALB security groups
5. **Target Instances**: EC2 instances or Auto Scaling groups
6. **SSL Certificate** (optional): ACM certificate for HTTPS

## 🔐 Security Best Practices

1. **Use HTTPS**: Always enable HTTPS in production
2. **SSL Policy**: Use modern TLS 1.3 policy
3. **Security Groups**: Restrict ALB access to specific sources
4. **Health Checks**: Implement robust health check endpoints
5. **CloudWatch Alarms**: Configure SNS notifications for alerts
6. **Deletion Protection**: Enable for production ALBs
7. **Access Logs**: Enable ALB access logs for audit trail

## 🎯 Real-World Example

Complete example with all features:

```hcl
module "production_deployment" {
  source = "./modules/blue-green-deployment"

  # Application configuration
  application_name = "ecommerce-api"
  vpc_id          = "vpc-prod-12345"
  
  # Network configuration
  alb_subnets         = ["subnet-public-1a", "subnet-public-1b"]
  alb_security_groups = ["sg-alb-prod"]
  internal_alb        = false

  # HTTPS configuration
  enable_https    = true
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/prod-cert"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # Deployment strategy
  active_environment       = "blue"
  enable_canary_deployment = false
  
  # Target configuration
  application_port    = 8080
  target_type        = "instance"
  deregistration_delay = 30

  # Health checks
  health_check_path              = "/api/health"
  health_check_interval          = 15
  health_check_timeout           = 5
  health_check_healthy_threshold = 2
  health_check_unhealthy_threshold = 3
  health_check_matcher           = "200"

  # Sticky sessions
  enable_stickiness   = true
  stickiness_duration = 3600

  # Auto Scaling
  enable_autoscaling            = true
  blue_autoscaling_group_name   = "ecommerce-blue-asg"
  green_autoscaling_group_name  = "ecommerce-green-asg"

  # Monitoring
  enable_cloudwatch_dashboard    = true
  alarm_sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:prod-alerts"
  unhealthy_host_alarm_threshold = 2
  response_time_threshold        = 0.5

  # Access logs
  enable_access_logs  = true
  access_logs_bucket  = "prod-alb-logs"

  # Protection
  enable_deletion_protection = true

  tags = {
    Environment = "production"
    Project     = "ecommerce"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

## 📚 Additional Resources

- [AWS Blue-Green Deployments](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/welcome.html)
- [ALB Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
- [Weighted Target Groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html#weighted-target-groups)

## 🤝 Contributing

Contributions welcome! Please test changes thoroughly before submitting PRs.

## 📄 License

MIT License - See LICENSE file for details.
