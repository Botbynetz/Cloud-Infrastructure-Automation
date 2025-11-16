# AWS X-Ray Distributed Tracing Module

This Terraform module configures AWS X-Ray distributed tracing for comprehensive application performance monitoring and debugging.

## Features

- **Flexible Sampling Rules**: Multiple sampling strategies for different use cases
- **X-Ray Groups**: Organized trace filtering and analysis
- **IAM Integration**: Pre-configured roles for EC2, ECS, and Lambda
- **CloudWatch Alarms**: Automated alerting for performance issues
- **Service Map**: Automatic service dependency visualization
- **Trace Analytics**: Built-in analysis capabilities
- **Encryption Support**: KMS encryption for trace data
- **Dashboard**: Pre-built CloudWatch dashboard for X-Ray metrics

## Usage

### Basic Configuration

```hcl
module "xray" {
  source = "./modules/xray"

  project_name = "my-project"
  environment  = "production"
  service_name = "my-api-service"

  tags = {
    Project     = "MyProject"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Configuration with Custom Sampling

```hcl
module "xray" {
  source = "./modules/xray"

  project_name = "my-project"
  environment  = "production"
  service_name = "my-api-service"

  # Sampling Configuration
  default_sampling_rate        = 0.05  # 5% of normal requests
  enable_high_priority_sampling = true
  high_priority_sampling_rate  = 0.5   # 50% of critical endpoints
  high_priority_url_pattern    = "/api/payment/*"
  
  enable_api_sampling          = true
  api_sampling_rate            = 0.1   # 10% of API calls
  
  enable_error_sampling        = true  # 100% of errors
  enable_slow_request_sampling = true  # 100% of slow requests
  slow_request_threshold       = 3     # 3 seconds

  # X-Ray Groups
  enable_insights                 = true
  enable_insights_notifications   = true
  enable_error_group              = true
  enable_slow_request_group       = true

  # IAM Configuration
  create_xray_role         = true
  create_instance_profile  = true

  # Alarms
  enable_xray_alarms       = true
  error_rate_threshold     = 5      # 5%
  latency_threshold        = 2000   # 2 seconds
  throttle_rate_threshold  = 1      # 1%
  
  alarm_actions = [
    "arn:aws:sns:us-east-1:123456789012:critical-alerts"
  ]

  # Encryption
  enable_encryption = true
  kms_key_id        = aws_kms_key.xray.id

  # Dashboard
  enable_xray_dashboard        = true
  application_log_group_name   = "/aws/myapp/production"

  tags = {
    Project     = "MyProject"
    Environment = "production"
  }
}
```

### Integration with Application Load Balancer

```hcl
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  
  # Enable X-Ray tracing
  enable_xff_client_port = true
  
  tags = var.tags
}

# ALB needs to forward X-Ray headers
resource "aws_lb_listener_rule" "xray" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Amzn-Trace-Id"
      values           = ["*"]
    }
  }
}
```

### ECS Task Definition with X-Ray

```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = module.xray.xray_role_arn
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "my-app:latest"
      
      environment = [
        {
          name  = "AWS_XRAY_TRACING_NAME"
          value = var.service_name
        },
        {
          name  = "AWS_XRAY_DAEMON_ADDRESS"
          value = "xray-daemon:2000"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "app"
        }
      }
    },
    {
      name  = "xray-daemon"
      image = "public.ecr.aws/xray/aws-xray-daemon:latest"
      
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "xray"
        }
      }
    }
  ])
}
```

### Lambda Function with X-Ray

```hcl
resource "aws_lambda_function" "api" {
  filename      = "function.zip"
  function_name = "${var.project_name}-${var.environment}-api"
  role          = module.xray.xray_role_arn
  handler       = "index.handler"
  runtime       = "python3.11"

  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      SERVICE_NAME       = var.service_name
      ENVIRONMENT        = var.environment
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  }

  tags = var.tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment (dev/staging/production) | `string` | n/a | yes |
| service_name | Name of the service to trace | `string` | n/a | yes |
| tags | Common tags for all resources | `map(string)` | `{}` | no |
| default_sampling_rate | Default sampling rate (0.0-1.0) | `number` | `0.05` | no |
| default_reservoir_size | Requests per second to always sample | `number` | `1` | no |
| enable_high_priority_sampling | Enable high priority sampling | `bool` | `true` | no |
| high_priority_sampling_rate | High priority sampling rate | `number` | `0.5` | no |
| high_priority_url_pattern | URL pattern for high priority | `string` | `"/api/critical/*"` | no |
| enable_api_sampling | Enable API endpoint sampling | `bool` | `true` | no |
| api_sampling_rate | API sampling rate | `number` | `0.1` | no |
| enable_error_sampling | Enable 100% error sampling | `bool` | `true` | no |
| enable_slow_request_sampling | Enable 100% slow request sampling | `bool` | `true` | no |
| slow_request_threshold | Slow request threshold (seconds) | `number` | `3` | no |
| enable_insights | Enable X-Ray Insights | `bool` | `true` | no |
| enable_insights_notifications | Enable Insights notifications | `bool` | `true` | no |
| enable_error_group | Create error trace group | `bool` | `true` | no |
| enable_slow_request_group | Create slow request group | `bool` | `true` | no |
| create_xray_role | Create IAM role for X-Ray | `bool` | `true` | no |
| create_instance_profile | Create instance profile for EC2 | `bool` | `true` | no |
| enable_xray_alarms | Enable CloudWatch alarms | `bool` | `true` | no |
| alarm_actions | SNS topic ARNs for alarms | `list(string)` | `[]` | no |
| error_rate_threshold | Error rate alarm threshold (%) | `number` | `5` | no |
| latency_threshold | Latency alarm threshold (ms) | `number` | `2000` | no |
| throttle_rate_threshold | Throttle rate threshold (%) | `number` | `1` | no |
| enable_encryption | Enable KMS encryption | `bool` | `true` | no |
| kms_key_id | KMS key ID for encryption | `string` | `""` | no |
| enable_xray_dashboard | Create CloudWatch dashboard | `bool` | `true` | no |
| application_log_group_name | Application log group name | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| xray_group_name | Main X-Ray group name |
| xray_group_arn | Main X-Ray group ARN |
| xray_role_arn | X-Ray IAM role ARN |
| xray_role_name | X-Ray IAM role name |
| xray_instance_profile_arn | X-Ray instance profile ARN |
| console_urls | AWS Console URLs for X-Ray resources |
| xray_summary | Configuration summary |
| instrumentation_config | Application instrumentation settings |

## Sampling Strategy

### Sampling Rules Priority

1. **Error Traces** (Priority 50): 100% of errors
2. **Slow Requests** (Priority 200): 100% of requests exceeding threshold
3. **High Priority Endpoints** (Priority 100): 50% of critical endpoints
4. **API Endpoints** (Priority 500): 10% of API calls
5. **Default** (Priority 10000): 5% of all other requests

### Reservoir Size

The reservoir size ensures a minimum number of traces per second are captured regardless of the sampling rate. This is useful for low-traffic services.

## X-Ray Groups

### Main Group
Filters all traces for the specified service name.

### Error Group
Automatically captures all traces with errors for quick debugging.

### Slow Request Group
Captures all traces exceeding the latency threshold for performance analysis.

## Instrumentation Guide

### Python Application

```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

app = Flask(__name__)

# Configure X-Ray
xray_recorder.configure(
    service='my-api-service',
    sampling=True,
    context_missing='LOG_ERROR'
)

# Instrument Flask app
XRayMiddleware(app, xray_recorder)

@app.route('/api/users')
def get_users():
    # This request will be traced
    return jsonify(users)
```

### Node.js Application

```javascript
const AWSXRay = require('aws-xray-sdk-core');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));
const express = require('express');

const app = express();

// Enable X-Ray for Express
app.use(AWSXRay.express.openSegment('my-api-service'));

app.get('/api/users', (req, res) => {
  // This request will be traced
  res.json(users);
});

app.use(AWSXRay.express.closeSegment());
```

### Java Application

```java
import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.javax.servlet.AWSXRayServletFilter;

@Configuration
public class XRayConfig {
    
    @Bean
    public Filter tracingFilter() {
        return new AWSXRayServletFilter("my-api-service");
    }
    
    @Bean
    public AWSXRay xray() {
        AWSXRay.setGlobalRecorder(
            AWSXRayRecorderBuilder
                .standard()
                .withSamplingStrategy(
                    new LocalizedSamplingStrategy(
                        getClass().getResource("/sampling-rules.json")
                    )
                )
                .build()
        );
        return new AWSXRay();
    }
}
```

## Cost Optimization

### Sampling Recommendations by Environment

| Environment | Sampling Rate | Estimated Cost/Month |
|-------------|--------------|---------------------|
| Development | 0.01 (1%) | $10-20 |
| Staging | 0.05 (5%) | $30-50 |
| Production | 0.05-0.1 (5-10%) | $100-200 |

### Cost Factors

1. **Traces Recorded**: $5.00 per 1 million traces recorded
2. **Traces Retrieved**: $0.50 per 1 million traces retrieved
3. **Traces Scanned**: $0.50 per 1 million traces scanned

### Tips

- Use reservoir size for low-traffic services
- Enable 100% sampling only for errors and critical paths
- Reduce default sampling rate in high-traffic production
- Use X-Ray Groups to filter unnecessary traces

## Troubleshooting

### Traces Not Appearing

```bash
# Check X-Ray daemon logs (ECS)
aws logs tail /ecs/my-project/xray --follow

# Check sampling rules
aws xray get-sampling-rules

# Verify IAM permissions
aws iam get-role --role-name my-project-production-xray-role
```

### High X-Ray Costs

```bash
# Check trace volume
aws cloudwatch get-metric-statistics \
  --namespace AWS/XRay \
  --metric-name TracesRecorded \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --period 86400 \
  --statistics Sum

# Review sampling rules
aws xray get-sampling-rules --query 'SamplingRuleRecords[*].[SamplingRule.RuleName,SamplingRule.FixedRate]'
```

### Missing Service Map Connections

1. Ensure X-Ray SDK is properly instrumented in all services
2. Verify trace ID propagation between services
3. Check that downstream services have X-Ray enabled
4. Confirm IAM permissions for X-Ray daemon

## Best Practices

1. **Start with Conservative Sampling**: Begin with 5% and adjust based on needs
2. **Always Sample Errors**: Enable 100% sampling for errors
3. **Use X-Ray Groups**: Organize traces by use case
4. **Enable Insights**: Detect anomalies automatically
5. **Monitor Costs**: Set up billing alarms
6. **Document Service Names**: Use consistent naming across services
7. **Propagate Trace Context**: Ensure trace IDs flow through all services
8. **Add Custom Annotations**: Include business context in traces

## Security Considerations

- **IAM Permissions**: Grant minimal required permissions
- **Encryption**: Enable KMS encryption for sensitive trace data
- **PII Data**: Avoid logging sensitive information in traces
- **Network Security**: X-Ray daemon communicates over UDP port 2000
- **VPC Endpoints**: Use VPC endpoints for private communication

## Version History

- **v1.6.0** (2024-01-20): Initial X-Ray module release

## Support

For issues and questions:
- GitHub: https://github.com/Botbynetz/Cloud-Infrastructure-Automation
- Documentation: https://botbynetz.github.io

## References

- [AWS X-Ray Documentation](https://docs.aws.amazon.com/xray/)
- [X-Ray SDK for Python](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-python.html)
- [X-Ray SDK for Node.js](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-nodejs.html)
- [X-Ray SDK for Java](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-java.html)
- [X-Ray Sampling Rules](https://docs.aws.amazon.com/xray/latest/devguide/xray-console-sampling.html)
