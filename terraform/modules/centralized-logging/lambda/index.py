import boto3
import os
import json
from datetime import datetime, timedelta
import time

logs_client = boto3.client('logs')

def handler(event, context):
    """
    Lambda function to export CloudWatch Logs to S3
    Triggered daily by EventBridge to export previous day's logs
    """
    
    s3_bucket = os.environ['S3_BUCKET']
    log_groups = [
        os.environ['APPLICATION_LOG_GROUP'],
        os.environ['INFRASTRUCTURE_LOG_GROUP'],
        os.environ['SECURITY_LOG_GROUP'],
        os.environ['AUDIT_LOG_GROUP']
    ]
    
    # Calculate time range (previous day)
    end_time = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    start_time = end_time - timedelta(days=1)
    
    # Convert to milliseconds since epoch
    from_time = int(start_time.timestamp() * 1000)
    to_time = int(end_time.timestamp() * 1000)
    
    results = []
    
    for log_group in log_groups:
        try:
            # Check if log group exists
            try:
                logs_client.describe_log_groups(logGroupNamePrefix=log_group)
            except logs_client.exceptions.ResourceNotFoundException:
                print(f"Log group not found: {log_group}")
                continue
            
            # Create export task
            log_group_name = log_group.split('/')[-1]
            destination_prefix = f"{log_group_name}/{start_time.strftime('%Y/%m/%d')}"
            
            response = logs_client.create_export_task(
                logGroupName=log_group,
                fromTime=from_time,
                to=to_time,
                destination=s3_bucket,
                destinationPrefix=destination_prefix
            )
            
            task_id = response['taskId']
            
            results.append({
                'log_group': log_group,
                'task_id': task_id,
                'status': 'initiated',
                'from_time': start_time.isoformat(),
                'to_time': end_time.isoformat(),
                's3_path': f"s3://{s3_bucket}/{destination_prefix}"
            })
            
            print(f"Export task created for {log_group}: {task_id}")
            
            # Wait a bit between tasks to avoid rate limiting
            time.sleep(1)
            
        except Exception as e:
            print(f"Error exporting {log_group}: {str(e)}")
            results.append({
                'log_group': log_group,
                'status': 'failed',
                'error': str(e)
            })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Exported {len(results)} log groups',
            'results': results
        })
    }
