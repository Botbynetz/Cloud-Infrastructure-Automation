# =============================================================================
# INCIDENT RESPONSE RUNBOOK
# =============================================================================
# Emergency procedures for production incidents
# STEP 8 Enhancement #5: Operational Runbooks

## 🚨 Incident Severity Classification

### Severity 1 (Critical)
- **Impact**: Complete service outage
- **Examples**: All production instances down, database unavailable, complete network failure
- **Response Time**: Immediate (< 5 minutes)
- **Escalation**: On-call engineer → Team Lead → CTO

### Severity 2 (High)
- **Impact**: Major feature degradation
- **Examples**: Partial instance failure, database connection issues, high latency
- **Response Time**: < 15 minutes
- **Escalation**: On-call engineer → Team Lead

### Severity 3 (Medium)
- **Impact**: Minor feature degradation
- **Examples**: Single instance issue, monitoring alerts, non-critical errors
- **Response Time**: < 1 hour
- **Escalation**: On-call engineer

### Severity 4 (Low)
- **Impact**: No customer impact
- **Examples**: Warning logs, informational alerts
- **Response Time**: Next business day
- **Escalation**: None

## 📞 Incident Response Team

### Primary On-Call
- **Name**: Assigned via PagerDuty rotation
- **Contact**: [PagerDuty] -> oncall@example.com
- **Backup**: Secondary on-call engineer

### Escalation Path
1. **L1**: On-Call Engineer (5 min)
2. **L2**: Team Lead (15 min)
3. **L3**: Engineering Manager (30 min)
4. **L4**: CTO (1 hour)

## 🔥 Incident Response Procedure

### Phase 1: Detection & Acknowledgment (0-5 min)

```bash
# 1. Acknowledge alert in PagerDuty
# 2. Check monitoring dashboards
open https://grafana.example.com/d/incident-overview

# 3. Quick health check
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table

# 4. Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table

# 5. Create incident channel
# Slack: /incident create sev1 "Database connection timeout"
```

### Phase 2: Assessment (5-15 min)

```bash
# 1. Check application logs
aws logs tail /aws/application/prod --follow --format short

# 2. Check system metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# 3. Check recent deployments
git log --oneline --since="2 hours ago"

# 4. Check terraform state
cd terraform
terraform workspace select prod
terraform show | grep -A 5 "aws_instance"

# 5. Document timeline
echo "$(date): Incident detected - Database connection timeout" >> incident-timeline.txt
```

### Phase 3: Containment (15-30 min)

#### For Application Crash
```bash
# 1. Stop traffic to affected instances
aws elbv2 deregister-targets \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/prod-app/xxxxx \
  --targets Id=i-xxxxx

# 2. Create instance snapshot
aws ec2 create-snapshot \
  --volume-id vol-xxxxx \
  --description "Incident snapshot $(date +%Y-%m-%d-%H-%M)"

# 3. Isolate affected instance
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxx \
  --groups sg-isolated
```

#### For Database Issue
```bash
# 1. Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier prod-database \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,PendingModifiedValues]'

# 2. Check connection count
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=prod-database \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# 3. Enable read replica if needed
aws rds create-db-instance-read-replica \
  --db-instance-identifier prod-database-emergency-replica \
  --source-db-instance-identifier prod-database
```

#### For Network Issue
```bash
# 1. Check security groups
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --output json

# 2. Check route tables
aws ec2 describe-route-tables \
  --filters "Name=tag:Environment,Values=prod" \
  --output table

# 3. Check VPC flow logs
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --start-time $(($(date +%s) - 3600)) \
  --filter-pattern "[version, account, eni, source, destination, srcport, destport=443, protocol=6, packets, bytes, windowstart, windowend, action=REJECT, flowlogstatus]"
```

### Phase 4: Resolution (30-60 min)

#### Quick Fixes

```bash
# 1. Restart failed service
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "i-xxxxx" \
  --parameters 'commands=["systemctl restart application"]'

# 2. Scale up instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name prod-asg \
  --desired-capacity 6

# 3. Deploy previous stable version
cd terraform
terraform apply -var="app_version=v1.2.3-stable"

# 4. Clear cache
redis-cli -h prod-redis.xxxxx.cache.amazonaws.com FLUSHDB
```

#### Rollback Procedure

```bash
# 1. Identify last stable commit
git log --oneline -10

# 2. Create rollback branch
git checkout -b rollback/incident-$(date +%Y%m%d-%H%M)
git revert HEAD~3..HEAD

# 3. Push and deploy
git push origin rollback/incident-$(date +%Y%m%d-%H%M)

# 4. Trigger emergency deployment
# GitHub Actions will run automatically, or:
cd .github/workflows
act -W terraform-cicd.yml -j deploy --secret-file .secrets
```

### Phase 5: Recovery Verification (60-90 min)

```bash
# 1. Check all instances healthy
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/prod-app/xxxxx

# 2. Verify metrics normalized
# Grafana: Check all dashboards return to normal

# 3. Run smoke tests
curl -f https://api.example.com/health || echo "Health check failed"
curl -f https://app.example.com/ || echo "Frontend failed"

# 4. Check error rates
aws logs filter-log-events \
  --log-group-name /aws/application/prod \
  --start-time $(($(date +%s) - 600)) \
  --filter-pattern "ERROR"

# 5. Notify stakeholders
# Slack: Post update in #incidents and #engineering
```

## 📊 Common Incident Scenarios

### Scenario 1: High CPU Utilization

**Symptoms**:
- CloudWatch alarm: CPUUtilization > 80%
- Application slow response times
- Increased latency

**Diagnosis**:
```bash
# 1. Check current CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# 2. SSH to instance
aws ssm start-session --target i-xxxxx

# 3. Check processes
top -bn1 | head -20
ps aux --sort=-%cpu | head -10
```

**Resolution**:
```bash
# Option 1: Scale horizontally
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name prod-asg \
  --desired-capacity $((current + 2))

# Option 2: Scale vertically (requires downtime)
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxx \
  --instance-type "{\"Value\": \"t3.xlarge\"}"
aws ec2 start-instances --instance-ids i-xxxxx

# Option 3: Kill problematic process
kill -9 $(ps aux | grep 'problematic-process' | awk '{print $2}')
```

### Scenario 2: Database Connection Pool Exhausted

**Symptoms**:
- "Too many connections" errors
- Application timeouts
- Database connection refused

**Diagnosis**:
```bash
# 1. Check active connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=prod-database \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# 2. Check RDS parameters
aws rds describe-db-parameters \
  --db-parameter-group-name prod-params \
  --query 'Parameters[?ParameterName==`max_connections`]'
```

**Resolution**:
```bash
# Option 1: Increase max_connections
aws rds modify-db-parameter-group \
  --db-parameter-group-name prod-params \
  --parameters "ParameterName=max_connections,ParameterValue=500,ApplyMethod=immediate"

# Option 2: Restart application to reset connections
aws ecs update-service \
  --cluster prod-cluster \
  --service app-service \
  --force-new-deployment

# Option 3: Scale RDS instance
aws rds modify-db-instance \
  --db-instance-identifier prod-database \
  --db-instance-class db.r5.xlarge \
  --apply-immediately
```

### Scenario 3: Disk Space Full

**Symptoms**:
- "No space left on device" errors
- Application crashes
- Log writing failures

**Diagnosis**:
```bash
# 1. Check disk usage
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "i-xxxxx" \
  --parameters 'commands=["df -h"]'

# 2. Find large files
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "i-xxxxx" \
  --parameters 'commands=["du -ah /var/log | sort -rh | head -20"]'
```

**Resolution**:
```bash
# Option 1: Clean logs
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "i-xxxxx" \
  --parameters 'commands=["find /var/log -type f -name \"*.log\" -mtime +7 -delete"]'

# Option 2: Expand volume
aws ec2 modify-volume \
  --volume-id vol-xxxxx \
  --size 100

# Then extend filesystem
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "i-xxxxx" \
  --parameters 'commands=["growpart /dev/xvda 1", "resize2fs /dev/xvda1"]'
```

## 🔍 Investigation Tools

### Log Analysis
```bash
# Search for errors in last hour
aws logs filter-log-events \
  --log-group-name /aws/application/prod \
  --start-time $(($(date +%s) - 3600000)) \
  --filter-pattern "ERROR"

# Get recent 500 errors
aws logs filter-log-events \
  --log-group-name /aws/application/prod \
  --start-time $(($(date +%s) - 3600000)) \
  --filter-pattern "status=500"
```

### Performance Analysis
```bash
# Check request latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/prod-alb/xxxxx \
  --start-time $(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

## 📝 Post-Incident Activities

### 1. Update Incident Timeline
```markdown
## Incident Timeline

- **14:30 UTC**: Alert triggered - High error rate
- **14:32 UTC**: Engineer acknowledged
- **14:35 UTC**: Root cause identified - Database connection pool exhausted
- **14:40 UTC**: Mitigation applied - Increased max_connections
- **14:50 UTC**: Service restored
- **15:00 UTC**: Monitoring confirmed stable
```

### 2. Root Cause Analysis (RCA)
- Write detailed RCA document
- Share with team for review
- Schedule post-mortem meeting

### 3. Create Jira Tickets
- Bug fixes required
- Monitoring improvements
- Documentation updates
- Preventive measures

### 4. Update Runbooks
- Document new learnings
- Update procedures
- Add new scenarios

## 📞 Communication Templates

### Initial Alert
```
🚨 INCIDENT: Severity 2 - Database Connection Issues
STATUS: Investigating
IMPACT: API latency increased, some requests timing out
ENGINEER: @oncall
STARTED: 2025-11-20 14:30 UTC
```

### Update
```
🔄 UPDATE: Incident #1234
Root cause identified: Connection pool exhausted
Mitigation in progress: Scaling database connections
ETA to resolution: 15 minutes
```

### Resolution
```
✅ RESOLVED: Incident #1234
Duration: 45 minutes
Impact: 5% of API requests affected
Root Cause: Database connection pool exhausted under load
Fix: Increased max_connections from 200 to 500
Next Steps: RCA scheduled for tomorrow
```

## ⚡ Quick Reference

| Alert | Likely Cause | First Action |
|-------|-------------|--------------|
| High CPU | Process spike, infinite loop | Check `top`, scale ASG |
| Memory high | Memory leak, cache buildup | Restart service, check logs |
| Disk full | Log accumulation, large files | Clean logs, expand volume |
| 5xx errors | Application crash, DB issue | Check logs, rollback if recent deploy |
| High latency | Network issue, DB slow query | Check CloudWatch, optimize queries |
| DB connection | Pool exhausted | Increase connections, restart app |

---

**Remember**: Stay calm, follow procedures, communicate frequently! 🚀
