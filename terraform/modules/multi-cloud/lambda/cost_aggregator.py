"""Cost Aggregator - Collect costs from AWS/Azure/GCP"""
import os, json, boto3
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
ce = boto3.client('ce')  # Cost Explorer
cloudwatch = boto3.client('cloudwatch')

COST_TABLE = os.environ['COST_TABLE']
cost_table = dynamodb.Table(COST_TABLE)

def handler(event, context):
    """Aggregate costs from all cloud providers"""
    try:
        today = datetime.now().date()
        yesterday = today - timedelta(days=1)
        date_str = yesterday.strftime('%Y-%m-%d')
        
        # AWS costs
        aws_cost = get_aws_costs(yesterday, today)
        cost_table.put_item(Item={
            'date': date_str,
            'cloud_provider': 'aws',
            'total_cost': aws_cost,
            'currency': 'USD',
            'ttl': int((datetime.now() + timedelta(days=365)).timestamp())
        })
        
        # Azure costs (placeholder)
        cost_table.put_item(Item={
            'date': date_str,
            'cloud_provider': 'azure',
            'total_cost': 0,
            'currency': 'USD',
            'ttl': int((datetime.now() + timedelta(days=365)).timestamp())
        })
        
        # GCP costs (placeholder)
        cost_table.put_item(Item={
            'date': date_str,
            'cloud_provider': 'gcp',
            'total_cost': 0,
            'currency': 'USD',
            'ttl': int((datetime.now() + timedelta(days=365)).timestamp())
        })
        
        total_cost = aws_cost
        
        # Publish to CloudWatch
        cloudwatch.put_metric_data(
            Namespace='MultiCloud/Costs',
            MetricData=[
                {'MetricName': 'TotalDailyCost', 'Value': total_cost, 'Unit': 'None'},
                {'MetricName': 'AWSCost', 'Value': aws_cost, 'Unit': 'None'}
            ]
        )
        
        print(f"✅ Aggregated costs for {date_str}: ${total_cost:.2f}")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'date': date_str,
                'total_cost': total_cost,
                'breakdown': {'aws': aws_cost, 'azure': 0, 'gcp': 0}
            })
        }
    except Exception as e:
        print(f"❌ Error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def get_aws_costs(start_date, end_date):
    """Get AWS costs via Cost Explorer"""
    try:
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost']
        )
        
        if response['ResultsByTime']:
            amount = float(response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])
            return round(amount, 2)
        return 0.0
    except Exception as e:
        print(f"AWS cost error: {e}")
        return 0.0
