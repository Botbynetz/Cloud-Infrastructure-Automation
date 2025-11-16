"""
Waste Elimination Lambda - Detect and clean up unused AWS resources
"""
import os, json, boto3
from datetime import datetime, timedelta

ec2 = boto3.client('ec2')
elb = boto3.client('elbv2')
rds = boto3.client('rds')
s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
AUTO_DELETE = os.environ.get('AUTO_DELETE_RESOURCES', 'false').lower() == 'true'
DRY_RUN = os.environ.get('DRY_RUN', 'true').lower() == 'true'
UNUSED_DAYS = int(os.environ.get('UNUSED_DAYS_THRESHOLD', '30'))

def handler(event, context):
    print(f"Starting waste detection for {PROJECT_NAME}-{ENVIRONMENT}")
    
    try:
        waste_resources = {
            'unattached_volumes': find_unattached_volumes(),
            'unused_elastic_ips': find_unused_elastic_ips(),
            'old_snapshots': find_old_snapshots(),
            'unused_load_balancers': find_unused_load_balancers(),
            'idle_rds_instances': find_idle_rds_instances()
        }
        
        total_waste = sum(len(v) for v in waste_resources.values())
        estimated_savings = calculate_savings(waste_resources)
        
        report = {
            'scan_date': str(datetime.now()),
            'project': f"{PROJECT_NAME}-{ENVIRONMENT}",
            'waste_resources': waste_resources,
            'summary': {
                'total_waste_resources': total_waste,
                'estimated_monthly_savings': estimated_savings,
                'dry_run_mode': DRY_RUN,
                'auto_delete_enabled': AUTO_DELETE
            }
        }
        
        # Delete resources if auto-delete enabled and not in dry-run mode
        if AUTO_DELETE and not DRY_RUN:
            cleanup_results = cleanup_waste(waste_resources)
            report['cleanup_results'] = cleanup_results
        
        # Send notification if waste detected
        if total_waste > 0:
            send_notification(report)
        
        return {'statusCode': 200, 'body': json.dumps(report)}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        send_error_notification(str(e))
        raise

def find_unattached_volumes():
    volumes = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])['Volumes']
    waste = []
    for vol in volumes:
        age_days = (datetime.now(vol['CreateTime'].tzinfo) - vol['CreateTime']).days
        if age_days > UNUSED_DAYS:
            waste.append({
                'resource_id': vol['VolumeId'],
                'type': 'EBS Volume',
                'size_gb': vol['Size'],
                'age_days': age_days,
                'estimated_monthly_cost': vol['Size'] * 0.10  # $0.10 per GB-month
            })
    return waste

def find_unused_elastic_ips():
    addresses = ec2.describe_addresses()['Addresses']
    waste = []
    for addr in addresses:
        if 'InstanceId' not in addr:
            waste.append({
                'resource_id': addr['AllocationId'],
                'type': 'Elastic IP',
                'public_ip': addr['PublicIp'],
                'estimated_monthly_cost': 3.60  # $0.005 per hour = ~$3.60/month
            })
    return waste

def find_old_snapshots():
    cutoff_date = datetime.now(datetime.now().astimezone().tzinfo) - timedelta(days=365)
    snapshots = ec2.describe_snapshots(OwnerIds=['self'])['Snapshots']
    waste = []
    for snap in snapshots:
        if snap['StartTime'] < cutoff_date:
            waste.append({
                'resource_id': snap['SnapshotId'],
                'type': 'EBS Snapshot',
                'age_days': (datetime.now(snap['StartTime'].tzinfo) - snap['StartTime']).days,
                'size_gb': snap['VolumeSize'],
                'estimated_monthly_cost': snap['VolumeSize'] * 0.05
            })
    return waste

def find_unused_load_balancers():
    lbs = elb.describe_load_balancers()['LoadBalancers']
    waste = []
    for lb in lbs:
        target_groups = elb.describe_target_groups(LoadBalancerArn=lb['LoadBalancerArn'])['TargetGroups']
        
        has_targets = False
        for tg in target_groups:
            targets = elb.describe_target_health(TargetGroupArn=tg['TargetGroupArn'])['TargetHealthDescriptions']
            if targets:
                has_targets = True
                break
        
        if not has_targets:
            waste.append({
                'resource_id': lb['LoadBalancerName'],
                'type': 'Application Load Balancer',
                'arn': lb['LoadBalancerArn'],
                'estimated_monthly_cost': 22.50  # ~$0.025 per hour
            })
    return waste

def find_idle_rds_instances():
    instances = rds.describe_db_instances()['DBInstances']
    waste = []
    
    for db in instances:
        if db['DBInstanceStatus'] == 'available':
            # Check connections metric
            try:
                end_time = datetime.now()
                start_time = end_time - timedelta(days=7)
                
                metrics = cloudwatch.get_metric_statistics(
                    Namespace='AWS/RDS',
                    MetricName='DatabaseConnections',
                    Dimensions=[{'Name': 'DBInstanceIdentifier', 'Value': db['DBInstanceIdentifier']}],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=86400,
                    Statistics=['Average']
                )
                
                avg_connections = sum(d['Average'] for d in metrics['Datapoints']) / len(metrics['Datapoints']) if metrics['Datapoints'] else 0
                
                if avg_connections < 1:  # Less than 1 connection per day on average
                    waste.append({
                        'resource_id': db['DBInstanceIdentifier'],
                        'type': 'RDS Instance',
                        'instance_class': db['DBInstanceClass'],
                        'avg_connections': round(avg_connections, 2),
                        'estimated_monthly_cost': 50  # Placeholder
                    })
            except:
                pass
    
    return waste

def calculate_savings(waste_resources):
    total = 0
    for category, resources in waste_resources.items():
        for resource in resources:
            total += resource.get('estimated_monthly_cost', 0)
    return round(total, 2)

def cleanup_waste(waste_resources):
    results = {'deleted': [], 'failed': []}
    
    # Delete unattached volumes
    for vol in waste_resources['unattached_volumes']:
        try:
            ec2.delete_volume(VolumeId=vol['resource_id'])
            results['deleted'].append(vol['resource_id'])
        except Exception as e:
            results['failed'].append({'resource': vol['resource_id'], 'error': str(e)})
    
    # Release unused Elastic IPs
    for eip in waste_resources['unused_elastic_ips']:
        try:
            ec2.release_address(AllocationId=eip['resource_id'])
            results['deleted'].append(eip['resource_id'])
        except Exception as e:
            results['failed'].append({'resource': eip['resource_id'], 'error': str(e)})
    
    # Delete old snapshots
    for snap in waste_resources['old_snapshots']:
        try:
            ec2.delete_snapshot(SnapshotId=snap['resource_id'])
            results['deleted'].append(snap['resource_id'])
        except Exception as e:
            results['failed'].append({'resource': snap['resource_id'], 'error': str(e)})
    
    return results

def send_notification(report):
    total = report['summary']['total_waste_resources']
    savings = report['summary']['estimated_monthly_savings']
    
    message = f"""Waste Detection Report - {datetime.now().strftime('%Y-%m-%d')}
Project: {PROJECT_NAME}-{ENVIRONMENT}

WASTE RESOURCES DETECTED: {total}
Estimated Monthly Savings: ${savings:.2f}

Breakdown:
- Unattached EBS Volumes: {len(report['waste_resources']['unattached_volumes'])}
- Unused Elastic IPs: {len(report['waste_resources']['unused_elastic_ips'])}
- Old Snapshots (>1 year): {len(report['waste_resources']['old_snapshots'])}
- Unused Load Balancers: {len(report['waste_resources']['unused_load_balancers'])}
- Idle RDS Instances: {len(report['waste_resources']['idle_rds_instances'])}

Mode: {'DRY RUN' if DRY_RUN else 'ACTIVE'}
Auto-Delete: {'ENABLED' if AUTO_DELETE else 'DISABLED'}
"""
    
    if 'cleanup_results' in report:
        message += f"\n\nCleanup Results:\n- Deleted: {len(report['cleanup_results']['deleted'])}\n- Failed: {len(report['cleanup_results']['failed'])}"
    
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"Waste Detection: {PROJECT_NAME}", Message=message)

def send_error_notification(error):
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"Waste Detection Error: {PROJECT_NAME}", Message=f"Error: {error}")
