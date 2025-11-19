# =============================================================================
# DISASTER RECOVERY RUNBOOK
# =============================================================================
# Procedures for disaster recovery scenarios
# STEP 8 Enhancement #5: DR Playbook

## 🎯 Overview

This runbook provides step-by-step procedures for recovering from catastrophic failures:
- Complete region failure
- Data center outage
- Multi-service corruption
- Ransomware attack
- Complete infrastructure loss

## 📊 Recovery Objectives

### RPO (Recovery Point Objective)
- **Database**: 5 minutes (continuous replication)
- **File Storage**: 1 hour (S3 cross-region replication)
- **Configuration**: Real-time (Terraform state in S3)
- **Logs**: 15 minutes (CloudWatch replication)

### RTO (Recovery Time Objective)
- **Critical Services**: 30 minutes
- **Standard Services**: 2 hours
- **Non-Critical Services**: 4 hours
- **Full Environment**: 8 hours

## 🚨 Disaster Scenarios

### Scenario 1: Complete Region Failure

**Detection:**
```bash
# Check region health
aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' || echo "Region unreachable"

# Check AWS Health Dashboard
aws health describe-events \
  --filter eventTypeCategories=issue \
  --region us-east-1
```

**Recovery Steps:**

**Step 1: Activate DR Region (0-10 min)**
```bash
# 1. Switch to DR region
export AWS_DEFAULT_REGION=us-west-2

# 2. Check DR environment status
cd terraform
terraform workspace select dr
terraform show | grep "resource"

# 3. Verify RDS read replica is available
aws rds describe-db-instances \
  --region us-west-2 \
  --db-instance-identifier dr-database-replica \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'
```

**Step 2: Promote DR Database (10-15 min)**
```bash
# 1. Promote read replica to standalone
aws rds promote-read-replica \
  --region us-west-2 \
  --db-instance-identifier dr-database-replica

# 2. Wait for promotion (5-10 min)
aws rds wait db-instance-available \
  --region us-west-2 \
  --db-instance-identifier dr-database-replica

# 3. Update connection string
aws ssm put-parameter \
  --region us-west-2 \
  --name /prod/database/endpoint \
  --value "dr-database-replica.xxxxx.us-west-2.rds.amazonaws.com" \
  --overwrite
```

**Step 3: Activate Compute Resources (15-25 min)**
```bash
# 1. Scale up DR Auto Scaling Group
aws autoscaling update-auto-scaling-group \
  --region us-west-2 \
  --auto-scaling-group-name dr-asg \
  --min-size 2 \
  --desired-capacity 4 \
  --max-size 8

# 2. Verify instances launching
aws ec2 describe-instances \
  --region us-west-2 \
  --filters "Name=tag:Environment,Values=dr" "Name=instance-state-name,Values=running,pending" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]'

# 3. Check load balancer targets
aws elbv2 describe-target-health \
  --region us-west-2 \
  --target-group-arn arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/dr-app/xxxxx
```

**Step 4: Update DNS (25-30 min)**
```bash
# 1. Get DR load balancer DNS
DR_ALB=$(aws elbv2 describe-load-balancers \
  --region us-west-2 \
  --names dr-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# 2. Update Route53 to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"app.example.com\",
        \"Type\": \"CNAME\",
        \"TTL\": 60,
        \"ResourceRecords\": [{\"Value\": \"$DR_ALB\"}]
      }
    }]
  }"

# 3. Verify DNS propagation
dig app.example.com +short
```

**Step 5: Verify Application Health (30+ min)**
```bash
# 1. Run smoke tests
curl -f https://app.example.com/health || echo "Health check failed"

# 2. Check application logs
aws logs tail /aws/application/dr --region us-west-2 --follow --format short

# 3. Monitor error rates
aws cloudwatch get-metric-statistics \
  --region us-west-2 \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/dr-alb/xxxxx \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum

# 4. Verify monitoring
open https://grafana-dr.example.com/d/dr-overview
```

### Scenario 2: Database Corruption

**Detection:**
```bash
# Check for data anomalies
aws rds describe-db-log-files \
  --db-instance-identifier prod-database \
  --filename-contains error

# Download and check error logs
aws rds download-db-log-file-portion \
  --db-instance-identifier prod-database \
  --log-file-name error/mysql-error.log \
  --output text
```

**Recovery Steps:**

**Step 1: Stop Application Traffic (0-5 min)**
```bash
# 1. Set ALB to maintenance page
aws elbv2 modify-rule \
  --rule-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:listener-rule/app/prod-alb/xxxxx/yyyyy \
  --actions Type=fixed-response,FixedResponseConfig='{StatusCode=503,ContentType=text/html,MessageBody="Maintenance in progress"}'

# 2. Drain existing connections (wait 5 min)
aws elbv2 modify-target-group-attributes \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/prod-app/xxxxx \
  --attributes Key=deregistration_delay.timeout_seconds,Value=30
```

**Step 2: Identify Last Good Backup (5-10 min)**
```bash
# 1. List automated backups
aws rds describe-db-snapshots \
  --db-instance-identifier prod-database \
  --snapshot-type automated \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output table

# 2. List manual snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier prod-database \
  --snapshot-type manual \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output table

# 3. Select snapshot (example: last night's automated backup)
SNAPSHOT_ID="rds:prod-database-2025-11-19-23-00"
```

**Step 3: Restore Database (10-30 min)**
```bash
# 1. Restore from snapshot to new instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-database-restored \
  --db-snapshot-identifier $SNAPSHOT_ID \
  --db-instance-class db.r5.xlarge \
  --vpc-security-group-ids sg-xxxxx \
  --db-subnet-group-name prod-db-subnet-group \
  --publicly-accessible false \
  --multi-az true \
  --storage-encrypted true \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/xxxxx

# 2. Wait for restoration (15-20 min)
aws rds wait db-instance-available \
  --db-instance-identifier prod-database-restored

# 3. Get new endpoint
NEW_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier prod-database-restored \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "New database endpoint: $NEW_ENDPOINT"
```

**Step 4: Verify Data Integrity (30-40 min)**
```bash
# 1. Connect to restored database
mysql -h $NEW_ENDPOINT -u admin -p

# 2. Run data validation queries
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM orders WHERE created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR);
SELECT MAX(created_at) FROM audit_log;

# 3. Check for consistency
SELECT table_name, table_rows FROM information_schema.tables 
WHERE table_schema = 'production' ORDER BY table_rows DESC;

# Exit MySQL
exit
```

**Step 5: Cutover to Restored Database (40-50 min)**
```bash
# 1. Update application configuration
aws ssm put-parameter \
  --name /prod/database/endpoint \
  --value "$NEW_ENDPOINT" \
  --overwrite

# 2. Restart application instances
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name prod-asg \
  --preferences '{"MinHealthyPercentage": 90}'

# 3. Remove maintenance mode
aws elbv2 modify-rule \
  --rule-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:listener-rule/app/prod-alb/xxxxx/yyyyy \
  --actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/prod-app/xxxxx

# 4. Monitor for errors
aws logs tail /aws/application/prod --follow --format short
```

**Step 6: Cleanup (50-60 min)**
```bash
# 1. Rename instances for clarity
aws rds modify-db-instance \
  --db-instance-identifier prod-database \
  --new-db-instance-identifier prod-database-corrupted \
  --apply-immediately

aws rds modify-db-instance \
  --db-instance-identifier prod-database-restored \
  --new-db-instance-identifier prod-database \
  --apply-immediately

# 2. Take manual backup of restored DB
aws rds create-db-snapshot \
  --db-instance-identifier prod-database \
  --db-snapshot-identifier manual-backup-after-restore-$(date +%Y%m%d-%H%M)

# 3. Keep corrupted DB for investigation (delete after 7 days)
```

### Scenario 3: Ransomware Attack

**Detection:**
```bash
# Indicators:
# - Encrypted files (.encrypted, .locked extensions)
# - Ransom notes (README.txt, DECRYPT_INSTRUCTIONS.txt)
# - Unusual network traffic
# - Mass file modifications

# Check GuardDuty findings
aws guardduty list-findings \
  --detector-id xxxxx \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'
```

**Response Steps:**

**Step 1: Immediate Isolation (0-5 min)**
```bash
# 1. Isolate ALL affected instances
for instance in $(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' --output text); do
  
  echo "Isolating $instance"
  aws ec2 modify-instance-attribute \
    --instance-id $instance \
    --groups sg-quarantine
done

# 2. Revoke all IAM sessions
aws iam delete-access-key --access-key-id AKIAXXXXXXXXXXXXXXXX --user-name compromised-user

# 3. Rotate ALL secrets immediately
cd scripts
./rotate-all-secrets-emergency.sh

# 4. Enable AWS Config recording
aws configservice start-configuration-recorder --configuration-recorder-name default
```

**Step 2: Assessment (5-15 min)**
```bash
# 1. Check S3 versioning (thank god we enabled this!)
aws s3api list-object-versions \
  --bucket prod-data \
  --prefix sensitive/ \
  --max-items 100

# 2. Check when attack started
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutObject \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --max-results 50

# 3. Identify affected resources
aws config select-aggregate-resource-config \
  --expression "SELECT resourceId WHERE resourceType='AWS::EC2::Instance' AND configuration.state.name='running'" \
  --configuration-aggregator-name prod-aggregator
```

**Step 3: Recovery from Clean Backup (15-60 min)**
```bash
# 1. Provision entirely new VPC (clean environment)
cd terraform
terraform workspace new dr-clean-$(date +%Y%m%d)
terraform apply -var="environment=dr-clean"

# 2. Restore database from pre-attack backup
# (Find last known good backup before attack timestamp)
ATTACK_TIME="2025-11-20T14:00:00Z"
LAST_GOOD_SNAPSHOT=$(aws rds describe-db-snapshots \
  --db-instance-identifier prod-database \
  --query "DBSnapshots[?SnapshotCreateTime<'$ATTACK_TIME'] | [-1].DBSnapshotIdentifier" \
  --output text)

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier clean-database \
  --db-snapshot-identifier $LAST_GOOD_SNAPSHOT \
  --db-subnet-group-name clean-db-subnet-group

# 3. Restore S3 objects to pre-attack version
aws s3api list-object-versions \
  --bucket prod-data \
  --query "Versions[?LastModified<'$ATTACK_TIME'].[Key,VersionId]" \
  --output text | while read key version; do
  aws s3api copy-object \
    --copy-source "prod-data/$key?versionId=$version" \
    --bucket prod-data-clean \
    --key "$key"
done

# 4. Deploy application to clean environment
cd terraform
terraform apply -var="environment=dr-clean" -var="db_endpoint=$CLEAN_DB_ENDPOINT"
```

**Step 4: Forensics & Hardening (Post-Recovery)**
```bash
# 1. Collect evidence (DON'T delete compromised resources yet!)
# Take snapshots of affected volumes
for vol in $(aws ec2 describe-volumes \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Volumes[*].VolumeId' --output text); do
  aws ec2 create-snapshot \
    --volume-id $vol \
    --description "Forensic evidence $(date +%Y-%m-%d)"
done

# 2. Export CloudTrail logs
aws s3 sync s3://cloudtrail-logs-bucket/ ./forensics/cloudtrail-logs/

# 3. Export GuardDuty findings
aws guardduty get-findings \
  --detector-id xxxxx \
  --finding-ids $(aws guardduty list-findings --detector-id xxxxx --query 'FindingIds' --output text) \
  > forensics/guardduty-findings.json

# 4. Contact AWS Support
# Open High Severity ticket: "Security Incident - Ransomware Attack"
```

## 🧪 DR Testing Procedures

### Quarterly DR Drill

**Schedule**: First Saturday of each quarter (minimal impact)

**Procedure**:
```bash
# 1. Announce drill
# Slack: "🔥 DR DRILL starting in 30 minutes - This is a TEST"

# 2. Simulate primary region failure
cd terraform
terraform workspace select dr
terraform apply -auto-approve

# 3. Promote DR database
aws rds promote-read-replica \
  --region us-west-2 \
  --db-instance-identifier dr-database-replica-test

# 4. Scale DR infrastructure
aws autoscaling update-auto-scaling-group \
  --region us-west-2 \
  --auto-scaling-group-name dr-asg \
  --desired-capacity 2

# 5. Update DNS to point to DR (test subdomain only!)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://dr-test-dns.json

# 6. Run smoke tests
./scripts/smoke-test-dr.sh

# 7. Measure RTO/RPO
DRILL_START=$(date +%s)
# ... recovery steps ...
DRILL_END=$(date +%s)
RTO=$((DRILL_END - DRILL_START))
echo "Actual RTO: $RTO seconds (Target: 1800 seconds)"

# 8. Revert to primary
terraform workspace select prod
aws route53 change-resource-record-sets --hosted-zone-id Z1234567890ABC --change-batch file://prod-dns.json
aws rds delete-db-instance --db-instance-identifier dr-database-replica-test --skip-final-snapshot

# 9. Document results
echo "DR Drill Results: RTO=$RTO, Issues=<list any>, Improvements=<list>" >> dr-drill-log.txt
```

## 📋 Recovery Checklist

### Pre-Recovery
- [ ] Declare disaster (Severity 1 incident)
- [ ] Notify stakeholders (CEO, CTO, customers)
- [ ] Assemble DR team (on-call, DBA, network, security)
- [ ] Document start time
- [ ] Create incident channel (#incident-dr)

### During Recovery
- [ ] Switch to DR region/environment
- [ ] Promote DR database
- [ ] Scale compute resources
- [ ] Update DNS
- [ ] Verify application health
- [ ] Run smoke tests
- [ ] Monitor error rates
- [ ] Update stakeholders every 15 min

### Post-Recovery
- [ ] Verify all services operational
- [ ] Monitor for 2 hours
- [ ] Collect metrics (RTO, RPO, data loss)
- [ ] Schedule post-mortem
- [ ] Write RCA document
- [ ] Update DR procedures
- [ ] Plan primary region restoration

## 🔄 Failback to Primary Region

```bash
# 1. Verify primary region recovered
aws health describe-events \
  --filter eventTypeCategories=issue \
  --region us-east-1

# 2. Provision fresh primary infrastructure
cd terraform
terraform workspace select prod
terraform apply

# 3. Replicate data from DR to primary
aws rds create-db-instance-read-replica \
  --db-instance-identifier prod-database-new \
  --source-db-instance-identifier dr-database \
  --source-region us-west-2 \
  --region us-east-1

# 4. Wait for replication to catch up
aws rds describe-db-instances \
  --db-instance-identifier prod-database-new \
  --query 'DBInstances[0].StatusInfos'

# 5. Cutover during maintenance window
# (Repeat Steps 4-5 from Region Failure but in reverse)
```

## 📞 Emergency Contacts

| Role | Name | Primary | Secondary |
|------|------|---------|-----------|
| Incident Commander | DevOps Lead | +1-555-0101 | Slack DM |
| Database Admin | DBA Team | +1-555-0102 | db-oncall@example.com |
| Network Engineer | NetOps | +1-555-0103 | netops@example.com |
| Security Lead | InfoSec | +1-555-0104 | security@example.com |
| AWS Support | TAM | +1-800-xxx-xxxx | Case Portal |

---

**Remember**: Practice makes perfect - run DR drills regularly! 🚀
