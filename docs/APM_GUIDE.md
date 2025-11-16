# Application Performance Monitoring (APM) Guide

Complete guide for implementing comprehensive application performance monitoring using AWS observability services.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Module Documentation](#module-documentation)
5. [Instrumentation Guide](#instrumentation-guide)
6. [Dashboard & Visualization](#dashboard--visualization)
7. [Alerting Strategy](#alerting-strategy)
8. [Cost Optimization](#cost-optimization)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Overview

This APM infrastructure provides end-to-end observability for your applications across four key areas:

### Phase 6 Components

| Component | Purpose | Key Features |
|-----------|---------|--------------|
| **AWS X-Ray** | Distributed tracing | Service map, trace analytics, sampling rules, performance insights |
| **Container Insights** | Container monitoring | ECS/EKS metrics, Fluent Bit logging, resource utilization |
| **Lambda Insights** | Serverless monitoring | Cold starts, memory usage, duration, network I/O |
| **Application Insights** | Custom metrics & anomaly detection | Business metrics, contributor insights, synthetics |

### Integration with Phase 5

Phase 6 APM modules integrate seamlessly with Phase 5 monitoring:

- **X-Ray** → CloudWatch Logs (trace data)
- **Container Insights** → CloudWatch Metrics (resource data)
- **Lambda Insights** → CloudWatch dashboards (serverless data)
- **Application Insights** → Centralized alerting (anomaly detection)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Application Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │   API    │  │   Web    │  │  Lambda  │  │  Worker  │         │
│  │ Gateway  │  │   App    │  │Functions │  │  Tasks   │         │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘         │
│       │             │              │             │              │
└───────┼─────────────┼──────────────┼─────────────┼──────────────┘
        │             │              │             │
        ├─────────────┴──────────────┴─────────────┤
        │                                          │
┌───────▼───────────────────────────────────────────▼──────────────┐
│                  AWS X-Ray (Distributed Tracing)                 │
│  • Sampling Rules    • Service Map    • Trace Analytics          │
│  • Performance Insights    • Error Tracking                      │
└────────────────────┬─────────────────────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────────────────────┐
│              CloudWatch Container Insights                        │
│  ┌─────────────────┐        ┌─────────────────┐                   │
│  │  ECS Cluster    │        │  EKS Cluster    │                   │
│  │  • Tasks        │        │  • Pods         │                   │
│  │  • Services     │        │  • Nodes        │                   │
│  │  • Fluent Bit   │        │  • ADOT         │                   │
│  └─────────────────┘        └─────────────────┘                   │
└────────────────────┬──────────────────────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────────────────────┐
│              CloudWatch Lambda Insights                           │
│  • Duration    • Memory    • Cold Starts    • Network I/O         │
└────────────────────┬──────────────────────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────────────────────┐
│           CloudWatch Application Insights                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐   │
│  │ Anomaly Detection│  │ Custom Metrics   │  │  Synthetics    │   │
│  │ • Response Time  │  │ • Business KPIs  │  │  • API Health  │   │
│  │ • Error Rates    │  │ • Cache Stats    │  │  • Endpoints   │   │
│  └──────────────────┘  └──────────────────┘  └────────────────┘   │
└────────────────────┬──────────────────────────────────────────────┘
                     │
┌────────────────────▼──────────────────────────────────────────────┐
│            Phase 5: Centralized Monitoring & Alerting             │
│  • CloudWatch Dashboards    • SNS Topics    • Slack/PagerDuty     │
│  • S3 Log Export    • Kinesis Streaming    • Alert Aggregation    │
└───────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### 1. X-Ray Distributed Tracing

```hcl
module "xray" {
  source = "./terraform/modules/xray"

  project_name = "my-app"
  environment  = "production"
  service_name = "api-service"

  # Sampling Configuration
  default_sampling_rate        = 0.05  # 5%
  enable_error_sampling        = true  # 100% errors
  enable_slow_request_sampling = true
  slow_request_threshold       = 3     # seconds

  # X-Ray Groups
  enable_insights               = true
  enable_error_group            = true
  enable_slow_request_group     = true

  # Alarms
  enable_xray_alarms    = true
  error_rate_threshold  = 5
  latency_threshold     = 2000
  
  alarm_actions = [
    module.alerting.critical_topic_arn  # From Phase 5
  ]

  tags = var.common_tags
}
```

### 2. Container Insights (ECS)

```hcl
module "container_insights_ecs" {
  source = "./terraform/modules/container-insights"

  project_name = "my-app"
  environment  = "production"

  # ECS Configuration
  enable_ecs_insights    = true
  ecs_cluster_name       = "my-ecs-cluster"
  deploy_fluent_bit      = true
  ecs_subnet_ids         = module.vpc.private_subnet_ids
  ecs_security_group_ids = [aws_security_group.ecs.id]

  # Alarms
  enable_container_alarms        = true
  cpu_utilization_threshold      = 80
  memory_utilization_threshold   = 80
  container_restart_threshold    = 5

  alarm_actions = [module.alerting.warning_topic_arn]

  tags = var.common_tags
}
```

### 3. Lambda Insights

```hcl
module "lambda_insights" {
  source = "./terraform/modules/lambda-insights"

  project_name = "my-app"
  environment  = "production"

  # Lambda Configuration
  lambda_role_names       = [aws_iam_role.lambda_api.name]
  lambda_log_group_names  = ["/aws/lambda/api-function"]
  primary_function_name   = "my-api-function"

  # Alarms
  enable_lambda_alarms        = true
  duration_threshold_ms       = 10000
  memory_utilization_threshold = 80
  error_threshold             = 10
  monitor_cold_starts         = true

  alarm_actions = [module.alerting.warning_topic_arn]

  tags = var.common_tags
}

# Apply Lambda Insights to your functions
resource "aws_lambda_function" "api" {
  function_name = "my-api-function"
  # ... other config ...

  layers = [
    module.lambda_insights.lambda_insights_layer_arn
  ]

  environment {
    variables = merge(
      # Your variables
      module.lambda_insights.lambda_function_config.environment_variables
    )
  }
}
```

### 4. Application Insights

```hcl
module "application_insights" {
  source = "./terraform/modules/application-insights"

  project_name              = "my-app"
  environment               = "production"
  application_namespace     = "MyApplication"
  application_log_group_name = module.monitoring.application_log_group_name

  # Anomaly Detection
  enable_anomaly_detection      = true
  anomaly_detection_band        = 2
  enable_database_monitoring    = true

  # Custom Metrics
  enable_business_metrics       = true
  enable_performance_metrics    = true
  enable_cache_metrics          = true

  # Contributor Insights
  enable_contributor_insights   = true

  # Synthetics (optional)
  enable_synthetics             = true
  synthetics_bucket_name        = "my-app-synthetics-artifacts"
  synthetics_schedule           = "rate(5 minutes)"

  alarm_actions = [module.alerting.warning_topic_arn]

  tags = var.common_tags
}
```

---

## Module Documentation

### X-Ray Module

**Location**: `terraform/modules/xray/`

#### Features

- **5 Sampling Rules**: Default (5%), High Priority (50%), API (10%), Errors (100%), Slow Requests (100%)
- **3 X-Ray Groups**: Main service, Errors, Slow requests
- **IAM Integration**: Pre-configured roles for EC2, ECS, Lambda
- **3 CloudWatch Alarms**: Error rate, latency, throttling
- **Dashboard**: Real-time X-Ray metrics visualization

#### Key Outputs

```hcl
module.xray.xray_role_arn              # IAM role for applications
module.xray.xray_instance_profile_arn  # EC2 instance profile
module.xray.console_urls.service_map   # Service map URL
module.xray.instrumentation_config     # App config
```

#### Usage Patterns

| Use Case | Configuration |
|----------|---------------|
| High Traffic API | `default_sampling_rate = 0.01` (1%) |
| Critical Endpoints | `high_priority_sampling_rate = 1.0` (100%) |
| Development | `default_sampling_rate = 0.5` (50%) |
| Error Debugging | `enable_error_sampling = true` |

---

### Container Insights Module

**Location**: `terraform/modules/container-insights/`

#### Features

- **ECS Support**: Fluent Bit sidecar, task-level metrics
- **EKS Support**: CloudWatch agent, pod/node metrics
- **3 CloudWatch Alarms**: CPU, memory, container restarts
- **Dashboard**: Container resource utilization

#### Key Outputs

```hcl
module.container_insights.fluent_bit_task_role_arn
module.container_insights.ecs_insights_log_group_name
module.container_insights.dashboard_name
```

#### Fluent Bit Configuration

Automatically collects:
- Container stdout/stderr logs
- ECS task metadata
- Performance metrics (CPU, memory, network, disk)

---

### Lambda Insights Module

**Location**: `terraform/modules/lambda-insights/`

#### Features

- **AWS Lambda Insights Layer**: Pre-built extension
- **5 CloudWatch Alarms**: Duration, memory, errors, throttles, cold starts
- **Dashboard**: Lambda performance metrics
- **4 Insights Queries**: Performance, cold starts, errors, memory analysis

#### Key Metrics

| Metric | Description | Unit |
|--------|-------------|------|
| `duration_max` | Maximum execution time | Milliseconds |
| `memory_utilization` | Memory usage percentage | Percent |
| `init_duration` | Cold start duration | Milliseconds |
| `cpu_total_time` | CPU time used | Milliseconds |
| `total_network` | Network I/O | Bytes |

---

### Application Insights Module

**Location**: `terraform/modules/application-insights/`

#### Features

- **Anomaly Detection**: 4 detectors (response time, request count, error rate, DB connections)
- **Custom Metrics**: Business transactions, user signups, API response time, cache stats
- **Contributor Insights**: Top error endpoints, top users by requests
- **Synthetics**: API health check canary (optional)
- **Dashboard**: Application-level insights

#### Custom Metric Filters

```python
# Log format for custom metrics (JSON)
{
  "timestamp": "2024-01-20T10:30:45Z",
  "request_id": "abc-123",
  "level": "INFO",
  "method": "POST",
  "endpoint": "/api/users",
  "status_code": 200,
  "response_time_ms": 150,
  "user_id": "user-456",
  "event": "TRANSACTION",
  "transaction_type": "USER_SIGNUP",
  "cache_key": "users:456",
  "cache_hit": true
}
```

---

## Instrumentation Guide

### Python Application

#### 1. Install Dependencies

```bash
pip install aws-xray-sdk boto3
```

#### 2. Configure X-Ray

```python
import json
import time
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware
from flask import Flask, request, jsonify
import boto3

# Initialize Flask app
app = Flask(__name__)

# Configure X-Ray
xray_recorder.configure(
    service='my-api-service',
    sampling=True,
    context_missing='LOG_ERROR',
    daemon_address='127.0.0.1:2000'  # X-Ray daemon
)

# Instrument Flask app
XRayMiddleware(app, xray_recorder)

# CloudWatch client for custom metrics
cloudwatch = boto3.client('cloudwatch')

@app.route('/api/users', methods=['GET'])
def get_users():
    start_time = time.time()
    
    # Add X-Ray metadata
    segment = xray_recorder.current_segment()
    segment.put_annotation('endpoint', '/api/users')
    segment.put_annotation('method', 'GET')
    
    try:
        # Your business logic
        users = fetch_users_from_db()
        
        # Calculate duration
        duration = (time.time() - start_time) * 1000
        
        # Log structured data for custom metrics
        log_data = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "request_id": request.headers.get('X-Request-Id'),
            "level": "INFO",
            "method": "GET",
            "endpoint": "/api/users",
            "status_code": 200,
            "response_time_ms": duration,
            "user_id": request.headers.get('X-User-Id')
        }
        print(json.dumps(log_data))
        
        # Publish custom CloudWatch metric
        cloudwatch.put_metric_data(
            Namespace='MyApplication',
            MetricData=[
                {
                    'MetricName': 'ApiResponseTime',
                    'Value': duration,
                    'Unit': 'Milliseconds',
                    'Dimensions': [
                        {'Name': 'Environment', 'Value': 'production'},
                        {'Name': 'Endpoint', 'Value': '/api/users'},
                        {'Name': 'Method', 'Value': 'GET'}
                    ]
                }
            ]
        )
        
        return jsonify(users), 200
        
    except Exception as e:
        # Log error
        error_data = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "level": "ERROR",
            "endpoint": "/api/users",
            "error_type": type(e).__name__,
            "message": str(e)
        }
        print(json.dumps(error_data))
        
        # Add X-Ray error
        segment.put_metadata('error', str(e))
        
        return jsonify({"error": "Internal server error"}), 500

# Business transaction tracking
@app.route('/api/signup', methods=['POST'])
def user_signup():
    # Log business event
    transaction_log = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "request_id": request.headers.get('X-Request-Id'),
        "event": "USER_SIGNUP",
        "transaction_type": "signup"
    }
    print(json.dumps(transaction_log))
    
    # Your signup logic
    return jsonify({"status": "success"}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### 3. Cache Monitoring

```python
import redis
from functools import wraps

redis_client = redis.Redis(host='localhost', port=6379)

def cache_with_monitoring(key_prefix):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            cache_key = f"{key_prefix}:{args[0]}"
            
            # Check cache
            cached = redis_client.get(cache_key)
            
            if cached:
                # Log cache hit
                cache_log = {
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "event": "CACHE_HIT",
                    "cache_key": cache_key
                }
                print(json.dumps(cache_log))
                return json.loads(cached)
            else:
                # Log cache miss
                cache_log = {
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "event": "CACHE_MISS",
                    "cache_key": cache_key
                }
                print(json.dumps(cache_log))
                
                # Fetch and cache
                result = f(*args, **kwargs)
                redis_client.setex(cache_key, 3600, json.dumps(result))
                return result
        return wrapper
    return decorator

@cache_with_monitoring('users')
def fetch_user(user_id):
    # Database query
    return {"id": user_id, "name": "John Doe"}
```

---

### Node.js Application

#### 1. Install Dependencies

```bash
npm install aws-xray-sdk aws-sdk express
```

#### 2. Configure X-Ray

```javascript
const AWSXRay = require('aws-xray-sdk-core');
const AWS = AWSXRay.captureAWS(require('aws-sdk'));
const express = require('express');

const app = express();
const cloudwatch = new AWS.CloudWatch();

// Enable X-Ray for Express
app.use(AWSXRay.express.openSegment('my-api-service'));

// Middleware for structured logging
app.use((req, res, next) => {
  req.startTime = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - req.startTime;
    
    // Structured log
    const logData = {
      timestamp: new Date().toISOString(),
      request_id: req.headers['x-request-id'],
      level: 'INFO',
      method: req.method,
      endpoint: req.path,
      status_code: res.statusCode,
      response_time_ms: duration,
      user_id: req.headers['x-user-id']
    };
    console.log(JSON.stringify(logData));
    
    // Publish custom metric
    cloudwatch.putMetricData({
      Namespace: 'MyApplication',
      MetricData: [{
        MetricName: 'ApiResponseTime',
        Value: duration,
        Unit: 'Milliseconds',
        Dimensions: [
          { Name: 'Environment', Value: 'production' },
          { Name: 'Endpoint', Value: req.path },
          { Name: 'Method', Value: req.method }
        ]
      }]
    }, (err) => {
      if (err) console.error('CloudWatch metric error:', err);
    });
  });
  next();
});

app.get('/api/users', (req, res) => {
  // Add X-Ray annotations
  const segment = AWSXRay.getSegment();
  segment.addAnnotation('endpoint', '/api/users');
  segment.addAnnotation('method', 'GET');
  
  // Your business logic
  res.json({ users: [] });
});

app.use(AWSXRay.express.closeSegment());

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

---

### Java Spring Boot Application

#### 1. Add Dependencies

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-xray-recorder-sdk-spring</artifactId>
    <version>2.15.0</version>
</dependency>
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-java-sdk-cloudwatch</artifactId>
    <version>1.12.500</version>
</dependency>
```

#### 2. Configure X-Ray

```java
import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.javax.servlet.AWSXRayServletFilter;
import com.amazonaws.services.cloudwatch.AmazonCloudWatch;
import com.amazonaws.services.cloudwatch.AmazonCloudWatchClientBuilder;
import com.amazonaws.services.cloudwatch.model.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.filter.OncePerRequestFilter;

@Configuration
public class ObservabilityConfig {
    
    @Bean
    public Filter tracingFilter() {
        return new AWSXRayServletFilter("my-api-service");
    }
    
    @Bean
    public AmazonCloudWatch cloudWatchClient() {
        return AmazonCloudWatchClientBuilder.defaultClient();
    }
}

@RestController
@RequestMapping("/api")
public class UserController {
    
    @Autowired
    private AmazonCloudWatch cloudWatch;
    
    @GetMapping("/users")
    public ResponseEntity<List<User>> getUsers(HttpServletRequest request) {
        long startTime = System.currentTimeMillis();
        
        // Add X-Ray annotations
        AWSXRay.getCurrentSegment().putAnnotation("endpoint", "/api/users");
        AWSXRay.getCurrentSegment().putAnnotation("method", "GET");
        
        try {
            List<User> users = userService.findAll();
            long duration = System.currentTimeMillis() - startTime;
            
            // Log structured data
            logStructuredData(request, "INFO", "/api/users", 200, duration);
            
            // Publish CloudWatch metric
            publishMetric("ApiResponseTime", duration, "/api/users", "GET");
            
            return ResponseEntity.ok(users);
            
        } catch (Exception e) {
            logStructuredData(request, "ERROR", "/api/users", 500, 
                System.currentTimeMillis() - startTime);
            AWSXRay.getCurrentSegment().putMetadata("error", e.getMessage());
            throw e;
        }
    }
    
    private void publishMetric(String metricName, double value, 
                               String endpoint, String method) {
        PutMetricDataRequest request = new PutMetricDataRequest()
            .withNamespace("MyApplication")
            .withMetricData(new MetricDatum()
                .withMetricName(metricName)
                .withValue(value)
                .withUnit(StandardUnit.Milliseconds)
                .withDimensions(
                    new Dimension().withName("Environment").withValue("production"),
                    new Dimension().withName("Endpoint").withValue(endpoint),
                    new Dimension().withName("Method").withValue(method)
                ));
        
        cloudWatch.putMetricData(request);
    }
    
    private void logStructuredData(HttpServletRequest request, String level,
                                   String endpoint, int statusCode, long duration) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("timestamp", Instant.now().toString());
        logData.put("request_id", request.getHeader("X-Request-Id"));
        logData.put("level", level);
        logData.put("method", request.getMethod());
        logData.put("endpoint", endpoint);
        logData.put("status_code", statusCode);
        logData.put("response_time_ms", duration);
        logData.put("user_id", request.getHeader("X-User-Id"));
        
        System.out.println(new ObjectMapper().writeValueAsString(logData));
    }
}
```

---

## Dashboard & Visualization

### Combined APM Dashboard

Create a master dashboard combining all Phase 6 modules:

```hcl
resource "aws_cloudwatch_dashboard" "apm_master" {
  dashboard_name = "${var.project_name}-${var.environment}-apm-master"

  dashboard_body = jsonencode({
    widgets = [
      # X-Ray Service Map Widget
      {
        type = "trace-overview"
        properties = {
          region = data.aws_region.current.name
          title  = "X-Ray Service Map"
        }
      },
      # Response Time with Anomaly Detection
      {
        type = "metric"
        properties = {
          metrics = [
            [var.application_namespace, "ResponseTime", { stat: "Average" }],
            ["ANOMALY_DETECTION_BAND", ".", { label: "Expected Range" }]
          ]
          title = "Response Time - Anomaly Detection"
        }
      },
      # Container Resource Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", { stat: "Average" }],
            [".", "MemoryUtilized", { stat: "Average", yAxis: "right" }]
          ]
          title = "Container Resources"
        }
      },
      # Lambda Performance
      {
        type = "metric"
        properties = {
          metrics = [
            ["LambdaInsights", "duration_max", { stat: "Maximum" }],
            [".", "memory_utilization", { stat: "Average", yAxis: "right" }]
          ]
          title = "Lambda Performance"
        }
      }
    ]
  })
}
```

### Access URLs

All console URLs are available in module outputs:

```bash
# X-Ray Service Map
terraform output -json xray_console_urls | jq -r '.service_map'

# Container Insights
terraform output -json container_insights_console_urls | jq -r '.ecs_insights'

# Lambda Insights
terraform output -json lambda_insights_console_urls | jq -r '.lambda_insights'

# Application Insights Dashboard
terraform output -json application_insights_console_urls | jq -r '.dashboard'
```

---

## Alerting Strategy

### Alert Severity Levels

| Severity | Response Time | Channels | Escalation |
|----------|--------------|----------|------------|
| **Critical** | Immediate | SNS + Slack + PagerDuty + SMS | 15 min |
| **Warning** | 30 minutes | SNS + Slack | None |
| **Info** | 2 hours | SNS | None |

### Recommended Alarm Thresholds

#### Production Environment

```hcl
# X-Ray
error_rate_threshold     = 1    # 1%
latency_threshold        = 1000 # 1 second

# Container Insights
cpu_utilization_threshold    = 70  # 70%
memory_utilization_threshold = 75  # 75%
container_restart_threshold  = 3   # restarts

# Lambda Insights
duration_threshold_ms        = 5000  # 5 seconds
memory_utilization_threshold = 85    # 85%
error_threshold              = 5     # errors
cold_start_threshold_ms      = 3000  # 3 seconds

# Application Insights
anomaly_detection_band       = 2     # 2 std devs
slow_transaction_threshold_ms = 500  # 500ms
```

#### Development Environment

```hcl
# More relaxed thresholds
error_rate_threshold     = 10   # 10%
latency_threshold        = 5000 # 5 seconds
cpu_utilization_threshold = 90  # 90%
```

---

## Cost Optimization

### APM Cost Breakdown

| Service | Pricing Model | Estimated Cost (Production) |
|---------|--------------|----------------------------|
| **X-Ray** | $5/million traces | $50-100/month (5% sampling) |
| **Container Insights** | $0.30/GB logs | $30-60/month |
| **Lambda Insights** | Included in Lambda pricing | $0 (no additional cost) |
| **CloudWatch Logs** | $0.50/GB ingested | $20-40/month |
| **CloudWatch Metrics** | $0.30/metric/month | $30-50/month |
| **Synthetics** | $0.0012/canary run | $5/month (5 min interval) |
| **Total** | - | **$135-255/month** |

### Cost Optimization Tips

1. **X-Ray Sampling**
   ```hcl
   # Reduce sampling in high-traffic production
   default_sampling_rate = 0.01  # 1% instead of 5%
   
   # Keep 100% sampling for errors
   enable_error_sampling = true
   ```

2. **Container Insights**
   ```hcl
   # Disable Fluent Bit in non-critical environments
   deploy_fluent_bit = var.environment == "production"
   
   # Shorter log retention in dev
   log_retention_days = var.environment == "dev" ? 7 : 30
   ```

3. **Lambda Insights**
   ```hcl
   # Apply Lambda Insights only to critical functions
   lambda_role_names = var.environment == "production" ? 
     [aws_iam_role.api.name, aws_iam_role.worker.name] : []
   ```

4. **Synthetics**
   ```hcl
   # Less frequent checks in dev
   synthetics_schedule = var.environment == "production" ? 
     "rate(5 minutes)" : "rate(30 minutes)"
   ```

5. **CloudWatch Logs**
   ```hcl
   # Aggressive log filtering
   enable_log_sampling = true
   log_sampling_rate   = 10  # Sample 10% of logs
   ```

---

## Troubleshooting

### X-Ray Issues

#### Traces Not Appearing

```bash
# Check X-Ray daemon status (ECS)
aws ecs describe-tasks --cluster my-cluster --tasks <task-id>

# Verify sampling rules
aws xray get-sampling-rules

# Check IAM permissions
aws iam get-role-policy --role-name my-xray-role --policy-name xray-policy

# Test X-Ray daemon connectivity
curl http://localhost:2000/ping
```

#### Missing Service Connections

1. Ensure all services have X-Ray SDK instrumented
2. Verify trace ID propagation in HTTP headers (`X-Amzn-Trace-Id`)
3. Check that downstream services have X-Ray enabled

---

### Container Insights Issues

#### Metrics Not Showing

```bash
# Check Fluent Bit logs
aws logs tail /ecs/my-cluster/fluent-bit --follow

# Verify Container Insights enabled on cluster
aws ecs describe-clusters --clusters my-cluster \
  --query 'clusters[].settings'

# Check IAM permissions
aws iam get-role-policy --role-name fluent-bit-task-role \
  --policy-name fluent-bit-policy
```

---

### Lambda Insights Issues

#### Layer Not Working

```bash
# Verify layer attached
aws lambda get-function --function-name my-function \
  --query 'Configuration.Layers[].Arn'

# Check environment variables
aws lambda get-function-configuration --function-name my-function \
  --query 'Environment.Variables'

# Verify IAM permissions
aws iam list-attached-role-policies --role-name my-lambda-role
```

---

### Application Insights Issues

#### Custom Metrics Not Appearing

```bash
# Check metric filters
aws logs describe-metric-filters --log-group-name /aws/app/production

# Manually test metric filter pattern
aws logs filter-log-events --log-group-name /aws/app/production \
  --filter-pattern '[time, request_id, event=USER_SIGNUP, ...]'

# Verify CloudWatch namespace
aws cloudwatch list-metrics --namespace MyApplication
```

---

## Best Practices

### 1. Structured Logging

**Always use JSON format** for logs to enable automatic metric extraction:

```json
{
  "timestamp": "2024-01-20T10:30:45Z",
  "level": "INFO",
  "message": "User signup successful",
  "user_id": "user-123",
  "endpoint": "/api/signup",
  "duration_ms": 150
}
```

### 2. Correlation IDs

**Propagate request IDs** across all services:

```python
# Generate in API Gateway
request_id = str(uuid.uuid4())
headers = {'X-Request-Id': request_id}

# Include in all logs
log_data = {
    "request_id": request_id,
    # ... other fields
}
```

### 3. Metric Dimensions

**Use consistent dimensions** for all custom metrics:

```python
dimensions = [
    {'Name': 'Environment', 'Value': os.getenv('ENVIRONMENT')},
    {'Name': 'Service', 'Value': 'api-service'},
    {'Name': 'Region', 'Value': os.getenv('AWS_REGION')}
]
```

### 4. Error Handling

**Always capture error context**:

```python
try:
    result = process_request()
except Exception as e:
    # Add X-Ray error
    segment.put_metadata('error', {
        'type': type(e).__name__,
        'message': str(e),
        'traceback': traceback.format_exc()
    })
    
    # Log error
    logger.error(json.dumps({
        'level': 'ERROR',
        'error_type': type(e).__name__,
        'message': str(e)
    }))
    
    raise
```

### 5. Performance Monitoring

**Track key business transactions**:

```python
@app.route('/api/checkout')
def checkout():
    with xray_recorder.capture('checkout_process'):
        # Track sub-segments
        with xray_recorder.capture('validate_cart'):
            validate_cart(cart_id)
        
        with xray_recorder.capture('process_payment'):
            process_payment(payment_info)
        
        with xray_recorder.capture('update_inventory'):
            update_inventory(items)
```

### 6. Sampling Strategy

**Tailor sampling** to your needs:

- **Production**: 1-5% default, 100% errors
- **Staging**: 10-20% default
- **Development**: 50-100%
- **Critical paths**: Always 100%

### 7. Dashboard Organization

**Create role-specific dashboards**:

- **Developers**: Error rates, slow requests, logs
- **DevOps**: Resource utilization, scaling metrics
- **Business**: Transaction counts, user signups, revenue

### 8. Alert Fatigue Prevention

**Use alert aggregation** (from Phase 5):

```hcl
# Aggregate repeated alarms
enable_alert_aggregation = true
alert_aggregation_window = 300  # 5 minutes

# Only alert after threshold
# Example: Alert on 5th occurrence, then every 20th
```

### 9. Security

**Protect sensitive data**:

```python
# Redact PII from logs
def sanitize_log(data):
    sensitive_fields = ['password', 'ssn', 'credit_card']
    for field in sensitive_fields:
        if field in data:
            data[field] = '***REDACTED***'
    return data

log_data = sanitize_log(user_data)
```

### 10. Testing

**Test observability** in CI/CD:

```bash
# Verify X-Ray traces generated
aws xray get-trace-summaries --start-time $(date -u -d '5 minutes ago' +%s) \
  --filter-expression 'service("my-api-service")'

# Check metrics published
aws cloudwatch get-metric-statistics --namespace MyApplication \
  --metric-name ApiResponseTime --start-time $(date -u -d '10 minutes ago' +%s) \
  --end-time $(date -u +%s) --period 300 --statistics Sum
```

---

## Version History

- **v1.6.0** (2024-01-20): Initial APM release
  - AWS X-Ray module
  - Container Insights module
  - Lambda Insights module
  - Application Insights module
  - Complete instrumentation guide

---

## Support

For issues and questions:
- **GitHub**: https://github.com/Botbynetz/Cloud-Infrastructure-Automation
- **Documentation**: https://botbynetz.github.io
- **Email**: support@botbynetz.com

---

## References

- [AWS X-Ray Documentation](https://docs.aws.amazon.com/xray/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)
- [Lambda Insights](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html)
- [CloudWatch Anomaly Detection](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html)
- [CloudWatch Synthetics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
