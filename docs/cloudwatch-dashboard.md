# CloudWatch Dashboard Template

This JSON template can be used to create a CloudWatch Dashboard for monitoring your infrastructure.

## How to Use

### Via AWS CLI
```bash
aws cloudwatch put-dashboard --dashboard-name cloud-infra-dev --dashboard-body file://cloudwatch-dashboard.json --region ap-southeast-1
```

### Via AWS Console
1. Go to CloudWatch → Dashboards
2. Click "Create dashboard"
3. Enter name: `cloud-infra-dev`
4. Click "Actions" → "View/edit source"
5. Paste the JSON below
6. Click "Update"

## Dashboard JSON

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/EC2", "CPUUtilization", { "stat": "Average", "label": "CPU Average" } ],
          [ "...", { "stat": "Maximum", "label": "CPU Maximum" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "EC2 CPU Utilization",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      },
      "width": 12,
      "height": 6,
      "x": 0,
      "y": 0
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "CWAgent", "mem_used_percent", { "stat": "Average" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "Memory Utilization",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      },
      "width": 12,
      "height": 6,
      "x": 12,
      "y": 0
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "CWAgent", "disk_used_percent", { "stat": "Average" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "Disk Utilization",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      },
      "width": 12,
      "height": 6,
      "x": 0,
      "y": 6
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/EC2", "StatusCheckFailed", { "stat": "Sum", "label": "Status Check Failed" } ],
          [ ".", "StatusCheckFailed_Instance", { "stat": "Sum", "label": "Instance Check Failed" } ],
          [ ".", "StatusCheckFailed_System", { "stat": "Sum", "label": "System Check Failed" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "EC2 Status Checks",
        "period": 300
      },
      "width": 12,
      "height": 6,
      "x": 12,
      "y": 6
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/ec2/cloud-infra-nginx-access'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
        "region": "ap-southeast-1",
        "title": "Recent Nginx Access Logs",
        "stacked": false
      },
      "width": 24,
      "height": 6,
      "x": 0,
      "y": 12
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/ec2/cloud-infra-nginx-error'\n| fields @timestamp, @message\n| filter @message like /error/\n| sort @timestamp desc\n| limit 50",
        "region": "ap-southeast-1",
        "title": "Nginx Error Logs",
        "stacked": false
      },
      "width": 24,
      "height": 6,
      "x": 0,
      "y": 18
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/EC2", "NetworkIn", { "stat": "Sum", "label": "Network In" } ],
          [ ".", "NetworkOut", { "stat": "Sum", "label": "Network Out" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "Network Traffic",
        "period": 300
      },
      "width": 12,
      "height": 6,
      "x": 0,
      "y": 24
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/EC2", "EBSReadBytes", { "stat": "Sum", "label": "EBS Read" } ],
          [ ".", "EBSWriteBytes", { "stat": "Sum", "label": "EBS Write" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "ap-southeast-1",
        "title": "EBS I/O",
        "period": 300
      },
      "width": 12,
      "height": 6,
      "x": 12,
      "y": 24
    },
    {
      "type": "alarm",
      "properties": {
        "title": "Active Alarms",
        "alarms": [
          "arn:aws:cloudwatch:ap-southeast-1:ACCOUNT_ID:alarm:cloud-infra-high-cpu-dev",
          "arn:aws:cloudwatch:ap-southeast-1:ACCOUNT_ID:alarm:cloud-infra-high-memory-dev",
          "arn:aws:cloudwatch:ap-southeast-1:ACCOUNT_ID:alarm:cloud-infra-high-disk-dev",
          "arn:aws:cloudwatch:ap-southeast-1:ACCOUNT_ID:alarm:cloud-infra-health-check-dev"
        ]
      },
      "width": 24,
      "height": 4,
      "x": 0,
      "y": 30
    }
  ]
}
```

## Dashboard Components

### Metrics Monitored
1. **CPU Utilization** - Average and maximum CPU usage
2. **Memory Utilization** - RAM usage percentage
3. **Disk Utilization** - Disk space usage
4. **Status Checks** - Instance and system health checks
5. **Network Traffic** - Incoming and outgoing network bytes
6. **EBS I/O** - Disk read and write operations

### Logs Displayed
1. **Nginx Access Logs** - Recent HTTP requests (last 100)
2. **Nginx Error Logs** - Error messages (last 50)

### Alarms Panel
Shows status of all configured CloudWatch alarms:
- High CPU alarm
- High memory alarm
- High disk usage alarm
- Health check failures

## Customization

Replace `ACCOUNT_ID` with your AWS account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

For different environments, change:
- Dashboard name: `cloud-infra-dev` → `cloud-infra-staging` or `cloud-infra-prod`
- Log group names in queries
- Alarm ARNs to match your environment

## Creating Dashboards for All Environments

```bash
# Development
aws cloudwatch put-dashboard \
  --dashboard-name cloud-infra-dev \
  --dashboard-body file://cloudwatch-dashboard.json \
  --region ap-southeast-1

# Staging
# (Modify JSON first to use staging resources)
aws cloudwatch put-dashboard \
  --dashboard-name cloud-infra-staging \
  --dashboard-body file://cloudwatch-dashboard-staging.json \
  --region ap-southeast-1

# Production
# (Modify JSON first to use prod resources)
aws cloudwatch put-dashboard \
  --dashboard-name cloud-infra-prod \
  --dashboard-body file://cloudwatch-dashboard-prod.json \
  --region ap-southeast-1
```

## Dashboard URL
After creation, access at:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=cloud-infra-dev
```

## Cost Note
CloudWatch dashboards have no additional cost for the first 3 dashboards and 50 metrics per month. Custom metrics and logs incur charges based on usage.
