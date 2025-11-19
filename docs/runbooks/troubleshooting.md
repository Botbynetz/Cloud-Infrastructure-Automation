# =============================================================================
# TROUBLESHOOTING GUIDE
# =============================================================================
# Common issues and their solutions
# STEP 8 Enhancement #5: Troubleshooting Runbook

## 🔍 Diagnostic Tools Overview

### Quick Health Check Script
```bash
#!/bin/bash
# save as: scripts/health-check.sh

echo "=== INFRASTRUCTURE HEALTH CHECK ==="
echo ""

# 1. AWS Connectivity
echo "1. Checking AWS connectivity..."
aws sts get-caller-identity && echo "✅ AWS connected" || echo "❌ AWS connection failed"
echo ""

# 2. EC2 Instances
echo "2. Checking EC2 instances..."
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PrivateIpAddress]' \
  --output table
echo ""

# 3. RDS Database
echo "3. Checking RDS database..."
aws rds describe-db-instances \
  --db-instance-identifier prod-database \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,EngineVersion]' \
  --output table
echo ""

# 4. Load Balancer
echo "4. Checking load balancer health..."
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names prod-app --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table
echo ""

# 5. CloudWatch Alarms
echo "5. Checking active alarms..."
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table
echo ""

# 6. Recent Errors
echo "6. Checking recent application errors..."
aws logs filter-log-events \
  --log-group-name /aws/application/prod \
  --start-time $(($(date +%s) - 3600))000 \
  --filter-pattern "ERROR" \
  --query 'events[0:5].[timestamp,message]' \
  --output table
echo ""

echo "=== HEALTH CHECK COMPLETE ==="
```

## 🐛 Common Issues & Solutions

### Issue 1: Terraform Plan Fails

**Symptoms:**
```
Error: Error acquiring the state lock
Error: Backend initialization required
Error: Provider configuration not found
```

**Diagnosis:**
```powershell
# Check Terraform version
terraform version

# Check backend configuration
terraform init -backend-config=backend/prod.conf

# Check state lock
aws dynamodb scan --table-name cloud-infra-terraform-locks
```

**Solutions:**

**A. State Lock Issue**
```powershell
# Check who has the lock
aws dynamodb get-item `
  --table-name cloud-infra-terraform-locks `
  --key '{\"LockID\":{\"S\":\"cloud-infra-prod/terraform.tfstate\"}}' `
  --query 'Item.Info.S' `
  --output text

# Force unlock (ONLY if you're sure no one is running terraform)
terraform force-unlock LOCK_ID

# If stuck, delete lock from DynamoDB
aws dynamodb delete-item `
  --table-name cloud-infra-terraform-locks `
  --key '{\"LockID\":{\"S\":\"cloud-infra-prod/terraform.tfstate\"}}'
```

**B. Backend Not Initialized**
```powershell
# Re-initialize with correct backend
cd terraform
terraform init -backend-config=backend/prod.conf -reconfigure

# If state file is missing, recover from backup
aws s3 ls s3://cloud-infra-terraform-state-prod/ --recursive | grep terraform.tfstate

# Restore from backup
aws s3 cp `
  s3://cloud-infra-terraform-state-prod/terraform.tfstate.backup `
  s3://cloud-infra-terraform-state-prod/terraform.tfstate
```

**C. Provider Version Conflict**
```powershell
# Clear provider cache
Remove-Item -Recurse -Force .terraform
Remove-Item .terraform.lock.hcl

# Re-initialize
terraform init -backend-config=backend/prod.conf
```

### Issue 2: GitHub Actions Workflow Fails

**Symptoms:**
```
Error: AWS credentials not found
Error: Terraform command failed
Error: Unable to connect to AWS
```

**Diagnosis:**
```powershell
# Check GitHub secrets are set
# Go to: GitHub Repo → Settings → Secrets → Actions

# Check workflow syntax
cd .github/workflows
Get-Content terraform-cicd.yml | Select-String "AWS_"
```

**Solutions:**

**A. Missing AWS Credentials**
```yaml
# Verify secrets are defined in workflow:
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_REGION: ${{ secrets.AWS_REGION }}

# If missing, add to GitHub:
# Settings → Secrets and variables → Actions → New repository secret
```

**B. Workflow Syntax Error**
```powershell
# Validate workflow locally with act
act -n  # Dry run

# Or use GitHub API to validate
gh api repos/Botbynetz/Cloud-Infrastructure-Automation/actions/workflows/terraform-cicd.yml
```

**C. Terraform Init Fails in Workflow**
```yaml
# Add backend config to workflow:
- name: Terraform Init
  run: |
    cd terraform
    terraform init \
      -backend-config="bucket=cloud-infra-terraform-state-${{ matrix.environment }}" \
      -backend-config="key=terraform.tfstate" \
      -backend-config="region=us-east-1" \
      -backend-config="dynamodb_table=cloud-infra-terraform-locks"
```

### Issue 3: Application Can't Connect to Database

**Symptoms:**
```
Error: Connection timeout
Error: Access denied for user 'app'@'10.0.1.5'
Error: Unknown database 'production'
```

**Diagnosis:**
```bash
# 1. Check RDS is running
aws rds describe-db-instances \
  --db-instance-identifier prod-database \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,Endpoint.Port]'

# 2. Test connectivity from EC2
aws ssm start-session --target i-xxxxx
# Inside instance:
telnet prod-database.xxxxx.us-east-1.rds.amazonaws.com 3306
# or
nc -zv prod-database.xxxxx.us-east-1.rds.amazonaws.com 3306

# 3. Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].IpPermissions'
```

**Solutions:**

**A. Security Group Issue**
```bash
# Add inbound rule to RDS security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-database \
  --protocol tcp \
  --port 3306 \
  --source-group sg-application

# Verify rule added
aws ec2 describe-security-groups \
  --group-ids sg-database \
  --query 'SecurityGroups[0].IpPermissions[?ToPort==`3306`]'
```

**B. Wrong Database Credentials**
```bash
# Rotate database password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update in RDS
aws rds modify-db-instance \
  --db-instance-identifier prod-database \
  --master-user-password "$NEW_PASSWORD" \
  --apply-immediately

# Update in Secrets Manager
aws secretsmanager update-secret \
  --secret-id prod/database/password \
  --secret-string "$NEW_PASSWORD"

# Restart application to pick up new secret
aws ecs update-service \
  --cluster prod-cluster \
  --service app-service \
  --force-new-deployment
```

**C. Network ACL Blocking Traffic**
```bash
# Check NACL rules
aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'NetworkAcls[*].Entries'

# Add allow rule if needed
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxxxx \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=3306,To=3306 \
  --cidr-block 10.0.1.0/24 \
  --egress \
  --rule-action allow
```

### Issue 4: High CPU/Memory Usage

**Symptoms:**
```
CloudWatch Alarm: CPUUtilization > 80%
CloudWatch Alarm: MemoryUtilization > 90%
Application slow or unresponsive
```

**Diagnosis:**
```bash
# 1. Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# 2. SSH to instance and investigate
aws ssm start-session --target i-xxxxx

# Inside instance:
top -bn1
ps aux --sort=-%cpu | head -20
ps aux --sort=-%mem | head -20

# Check memory details
free -h
vmstat 1 5

# Check disk I/O
iostat -x 1 5
```

**Solutions:**

**A. Memory Leak in Application**
```bash
# 1. Identify problematic process
ps aux --sort=-%mem | head -5

# 2. Get heap dump (for Java apps)
jmap -dump:format=b,file=/tmp/heap.hprof $(pgrep java)

# 3. Restart application
systemctl restart application

# 4. Monitor memory after restart
watch -n 5 'free -h'
```

**B. Database Query Causing High CPU**
```bash
# Connect to RDS and check slow queries
mysql -h prod-database.xxxxx.rds.amazonaws.com -u admin -p

# MySQL:
SHOW FULL PROCESSLIST;
SELECT * FROM information_schema.processlist WHERE time > 10;

# Kill slow query
KILL <query_id>;

# Check slow query log
aws rds download-db-log-file-portion \
  --db-instance-identifier prod-database \
  --log-file-name slowquery/mysql-slowquery.log \
  --output text
```

**C. Scale Infrastructure**
```bash
# Horizontal scaling (add more instances)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name prod-asg \
  --desired-capacity $((current + 2))

# Vertical scaling (larger instance type)
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxx \
  --instance-type "{\"Value\": \"t3.xlarge\"}"
aws ec2 start-instances --instance-ids i-xxxxx
```

### Issue 5: S3 Access Denied

**Symptoms:**
```
Error: Access Denied (Status Code: 403)
Error: The bucket does not allow ACLs
Error: Invalid bucket name
```

**Diagnosis:**
```bash
# 1. Check bucket exists
aws s3 ls s3://cloud-infra-terraform-state-prod/

# 2. Check bucket policy
aws s3api get-bucket-policy \
  --bucket cloud-infra-terraform-state-prod \
  --query Policy \
  --output text | jq .

# 3. Check IAM permissions
aws iam get-user-policy \
  --user-name terraform-automation \
  --policy-name TerraformS3Access
```

**Solutions:**

**A. Fix Bucket Policy**
```bash
# Create policy file: s3-bucket-policy.json
cat > s3-bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/terraform-automation"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::cloud-infra-terraform-state-prod/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/terraform-automation"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::cloud-infra-terraform-state-prod"
    }
  ]
}
EOF

# Apply policy
aws s3api put-bucket-policy \
  --bucket cloud-infra-terraform-state-prod \
  --policy file://s3-bucket-policy.json
```

**B. Fix IAM User Permissions**
```bash
# Create IAM policy
aws iam create-policy \
  --policy-name TerraformS3FullAccess \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::cloud-infra-terraform-state-*",
        "arn:aws:s3:::cloud-infra-terraform-state-*/*"
      ]
    }]
  }'

# Attach to user
aws iam attach-user-policy \
  --user-name terraform-automation \
  --policy-arn arn:aws:iam::123456789012:policy/TerraformS3FullAccess
```

### Issue 6: Prometheus/Grafana Not Collecting Metrics

**Symptoms:**
```
Grafana dashboards empty
Prometheus targets down
No alerts firing despite issues
```

**Diagnosis:**
```bash
# 1. Check Prometheus targets
curl http://prometheus.example.com:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health:.health}'

# 2. Check Prometheus config
aws ssm start-session --target i-prometheus-xxxxx
cat /etc/prometheus/prometheus.yml

# 3. Check Prometheus logs
aws logs tail /aws/ec2/prometheus --follow --format short

# 4. Test metrics endpoint
curl http://10.0.1.10:9090/metrics
```

**Solutions:**

**A. Targets Not Reachable**
```bash
# Check security group allows Prometheus to scrape targets
aws ec2 authorize-security-group-ingress \
  --group-id sg-application \
  --protocol tcp \
  --port 9090 \
  --source-group sg-prometheus

# Verify connectivity
aws ssm start-session --target i-prometheus-xxxxx
# Inside:
telnet application-instance 9090
```

**B. Service Discovery Not Working**
```yaml
# Update Prometheus config for EC2 service discovery
scrape_configs:
  - job_name: 'ec2-nodes'
    ec2_sd_configs:
      - region: us-east-1
        port: 9090
        filters:
          - name: tag:Environment
            values: [prod]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
```

**C. Grafana Can't Connect to Prometheus**
```bash
# SSH to Grafana instance
aws ssm start-session --target i-grafana-xxxxx

# Test connection
curl http://prometheus.example.com:9090/api/v1/query?query=up

# Update Grafana datasource
curl -X PUT http://admin:admin@localhost:3000/api/datasources/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus.example.com:9090",
    "access": "proxy"
  }'
```

## 🔧 Advanced Troubleshooting

### Enable Debug Logging

**Terraform:**
```powershell
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="terraform-debug.log"
terraform apply
```

**AWS CLI:**
```powershell
$env:AWS_DEBUG="true"
aws ec2 describe-instances --debug
```

**Application:**
```bash
# Update environment variable
aws ssm put-parameter \
  --name /prod/app/log_level \
  --value DEBUG \
  --overwrite

# Restart app
aws autoscaling start-instance-refresh --auto-scaling-group-name prod-asg
```

### Network Troubleshooting

```bash
# Trace route to instance
traceroute -n 10.0.1.10

# Check DNS resolution
dig app.example.com

# Check SSL certificate
openssl s_client -connect app.example.com:443 -servername app.example.com

# Packet capture
sudo tcpdump -i eth0 -n port 443 -w capture.pcap
```

### Performance Profiling

```bash
# CPU profiling (Linux perf)
perf record -g -p $(pgrep application)
perf report

# Flame graph
git clone https://github.com/brendangregg/FlameGraph
perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > flame.svg
```

## 📞 Escalation Matrix

| Issue Type | L1 (Self-Service) | L2 (On-Call) | L3 (Team Lead) | L4 (AWS Support) |
|-----------|------------------|--------------|----------------|------------------|
| Terraform error | Docs, logs | 30 min | 2 hours | - |
| Application error | Restart, logs | 15 min | 1 hour | - |
| Database issue | Check status | 15 min | 30 min | 2 hours |
| Network issue | Security groups | 30 min | 1 hour | 4 hours |
| AWS service outage | Health Dashboard | Immediate | Immediate | Immediate |

---

**Remember**: Document everything you try - it helps future debugging! 🔍
