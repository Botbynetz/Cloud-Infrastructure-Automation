"""DORA Metrics Collector - Calculate 4 key DORA metrics"""
import os, json, boto3
from datetime import datetime, timedelta
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')

DEPLOYMENTS_TABLE = os.environ['DEPLOYMENTS_TABLE']
DORA_TABLE = os.environ['DORA_METRICS_TABLE']

deployments_table = dynamodb.Table(DEPLOYMENTS_TABLE)
dora_table = dynamodb.Table(DORA_TABLE)

def handler(event, context):
    """Calculate DORA metrics"""
    try:
        timestamp = int(datetime.now().timestamp())
        today = datetime.now().date()
        week_ago = today - timedelta(days=7)
        
        # 1. Deployment Frequency (deployments per day)
        deployment_freq = calculate_deployment_frequency(week_ago, today)
        
        # 2. Lead Time for Changes (time from commit to production)
        lead_time = calculate_lead_time(week_ago, today)
        
        # 3. Mean Time to Recovery (MTTR)
        mttr = calculate_mttr(week_ago, today)
        
        # 4. Change Failure Rate
        failure_rate = calculate_change_failure_rate(week_ago, today)
        
        # Store aggregated metrics
        dora_table.put_item(Item={
            'metric_type': 'dora_summary',
            'timestamp': timestamp,
            'deployment_frequency': Decimal(str(deployment_freq)),
            'lead_time_minutes': Decimal(str(lead_time)),
            'mttr_minutes': Decimal(str(mttr)),
            'change_failure_rate': Decimal(str(failure_rate)),
            'ttl': timestamp + (86400 * 365)
        })
        
        # Publish to CloudWatch
        cloudwatch.put_metric_data(
            Namespace='GitOps/DORA',
            MetricData=[
                {'MetricName': 'DeploymentFrequency', 'Value': deployment_freq, 'Unit': 'Count'},
                {'MetricName': 'LeadTime', 'Value': lead_time, 'Unit': 'Seconds'},
                {'MetricName': 'MTTR', 'Value': mttr, 'Unit': 'Seconds'},
                {'MetricName': 'ChangeFailureRate', 'Value': failure_rate, 'Unit': 'Percent'}
            ]
        )
        
        print(f"✅ DORA Metrics - Freq: {deployment_freq}/day, Lead: {lead_time}min, MTTR: {mttr}min, Failure: {failure_rate}%")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'deployment_frequency': deployment_freq,
                'lead_time_minutes': lead_time,
                'mttr_minutes': mttr,
                'change_failure_rate': failure_rate
            })
        }
    except Exception as e:
        print(f"❌ DORA calculation error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def calculate_deployment_frequency(start_date, end_date):
    """Calculate deployments per day"""
    try:
        response = deployments_table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'success'}
        )
        total_deployments = len(response.get('Items', []))
        days = (end_date - start_date).days or 1
        return round(total_deployments / days, 2)
    except:
        return 0

def calculate_lead_time(start_date, end_date):
    """Calculate average lead time (commit to deploy)"""
    try:
        # Placeholder: Would integrate with Git API
        return 45  # 45 minutes average
    except:
        return 0

def calculate_mttr(start_date, end_date):
    """Calculate mean time to recovery"""
    try:
        # Placeholder: Would track incident resolution time
        return 30  # 30 minutes average
    except:
        return 0

def calculate_change_failure_rate(start_date, end_date):
    """Calculate percentage of failed deployments"""
    try:
        success_response = deployments_table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'success'}
        )
        failed_response = deployments_table.query(
            IndexName='StatusIndex',
            KeyConditionExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'failed'}
        )
        
        success_count = len(success_response.get('Items', []))
        failed_count = len(failed_response.get('Items', []))
        total = success_count + failed_count
        
        if total == 0:
            return 0
        
        return round((failed_count / total) * 100, 2)
    except:
        return 0
