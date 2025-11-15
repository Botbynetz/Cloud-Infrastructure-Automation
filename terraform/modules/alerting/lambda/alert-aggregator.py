import boto3
import json
import os
import time
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

def handler(event, context):
    """
    Lambda function to aggregate alerts and prevent alert fatigue
    Deduplicates similar alerts within a time window
    """
    
    table_name = os.environ['ALERT_STATE_TABLE']
    aggregation_window = int(os.environ['AGGREGATION_WINDOW'])  # seconds
    
    table = dynamodb.Table(table_name)
    
    # Parse incoming alarm
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    
    alarm_name = sns_message.get('AlarmName', 'Unknown')
    alarm_state = sns_message.get('NewStateValue', 'UNKNOWN')
    timestamp = int(time.time())
    
    # Check if similar alert exists in recent window
    try:
        response = table.get_item(
            Key={
                'AlertId': alarm_name,
                'Timestamp': timestamp
            }
        )
        
        # If alert exists and is recent, aggregate it
        if 'Item' in response:
            existing_item = response['Item']
            last_timestamp = int(existing_item['Timestamp'])
            
            if (timestamp - last_timestamp) < aggregation_window:
                # Update count
                count = existing_item.get('Count', 1) + 1
                
                table.update_item(
                    Key={
                        'AlertId': alarm_name,
                        'Timestamp': last_timestamp
                    },
                    UpdateExpression='SET #count = :count, LastUpdated = :timestamp',
                    ExpressionAttributeNames={
                        '#count': 'Count'
                    },
                    ExpressionAttributeValues={
                        ':count': count,
                        ':timestamp': timestamp
                    }
                )
                
                print(f"Aggregated alert {alarm_name}. Count: {count}")
                
                # Only send notification if count crosses threshold
                if count == 5 or count == 10 or count % 20 == 0:
                    send_aggregated_notification(alarm_name, count, sns_message)
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Alert aggregated',
                        'count': count
                    })
                }
        
        # New alert - store it
        table.put_item(
            Item={
                'AlertId': alarm_name,
                'Timestamp': timestamp,
                'State': alarm_state,
                'Count': 1,
                'LastUpdated': timestamp,
                'ExpirationTime': timestamp + 86400,  # 24 hour TTL
                'Message': json.dumps(sns_message),
                'Acknowledged': False
            }
        )
        
        # Forward to appropriate SNS topic
        topic_arn = determine_topic(sns_message)
        if topic_arn:
            sns.publish(
                TopicArn=topic_arn,
                Message=json.dumps(sns_message),
                Subject=f"CloudWatch Alarm: {alarm_name}"
            )
        
        print(f"New alert {alarm_name} stored and forwarded")
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'New alert processed'})
        }
        
    except Exception as e:
        print(f"Error processing alert: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def determine_topic(sns_message):
    """
    Determine which SNS topic to use based on alarm severity
    """
    alarm_name = sns_message.get('AlarmName', '').lower()
    
    # Critical alarms
    if any(keyword in alarm_name for keyword in ['critical', 'disk_full', 'high_error_rate']):
        return os.environ.get('CRITICAL_TOPIC_ARN')
    
    # Warning alarms
    if any(keyword in alarm_name for keyword in ['warning', 'high_cpu', 'high_memory']):
        return os.environ.get('WARNING_TOPIC_ARN')
    
    # Default to info
    return os.environ.get('INFO_TOPIC_ARN')

def send_aggregated_notification(alarm_name, count, original_message):
    """
    Send aggregated notification when count threshold is reached
    """
    aggregated_message = {
        'AlarmName': f"AGGREGATED: {alarm_name}",
        'AlarmDescription': f"This alarm has triggered {count} times in the aggregation window",
        'NewStateValue': 'ALARM',
        'NewStateReason': f"Alert aggregated. Original count: {count}",
        'OriginalMessage': original_message
    }
    
    topic_arn = os.environ.get('CRITICAL_TOPIC_ARN')
    if topic_arn:
        sns.publish(
            TopicArn=topic_arn,
            Message=json.dumps(aggregated_message),
            Subject=f"AGGREGATED ALERT: {alarm_name} ({count} occurrences)"
        )
