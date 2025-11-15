import json
import os
import urllib3
import datetime

http = urllib3.PoolManager()

def handler(event, context):
    """
    Lambda function to send CloudWatch alarm notifications to PagerDuty
    """
    
    integration_key = os.environ['PAGERDUTY_INTEGRATION_KEY']
    project_name = os.environ['PROJECT_NAME']
    environment = os.environ['ENVIRONMENT']
    
    # Parse SNS message
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    
    # Extract alarm details
    alarm_name = sns_message.get('AlarmName', 'Unknown Alarm')
    alarm_description = sns_message.get('AlarmDescription', '')
    new_state = sns_message.get('NewStateValue', 'UNKNOWN')
    reason = sns_message.get('NewStateReason', '')
    timestamp = sns_message.get('StateChangeTime', datetime.datetime.utcnow().isoformat())
    
    # Determine PagerDuty event action
    if new_state == 'ALARM':
        event_action = 'trigger'
        severity = 'critical'
    elif new_state == 'OK':
        event_action = 'resolve'
        severity = 'info'
    else:
        event_action = 'trigger'
        severity = 'warning'
    
    # Build PagerDuty event
    pagerduty_event = {
        'routing_key': integration_key,
        'event_action': event_action,
        'dedup_key': f'{alarm_name}-{environment}',
        'payload': {
            'summary': f'{alarm_name} - {new_state}',
            'source': f'{project_name}-{environment}',
            'severity': severity,
            'timestamp': timestamp,
            'component': 'AWS CloudWatch',
            'group': environment,
            'class': 'alarm',
            'custom_details': {
                'alarm_name': alarm_name,
                'alarm_description': alarm_description,
                'state': new_state,
                'reason': reason,
                'project': project_name,
                'environment': environment,
                'aws_region': os.environ.get('AWS_REGION', 'us-east-1')
            }
        },
        'links': [
            {
                'href': f"https://console.aws.amazon.com/cloudwatch/home?region={os.environ.get('AWS_REGION', 'us-east-1')}#alarmsV2:alarm/{alarm_name}",
                'text': 'View in CloudWatch Console'
            }
        ]
    }
    
    # Send to PagerDuty
    try:
        encoded_event = json.dumps(pagerduty_event).encode('utf-8')
        response = http.request(
            'POST',
            'https://events.pagerduty.com/v2/enqueue',
            body=encoded_event,
            headers={'Content-Type': 'application/json'}
        )
        
        response_data = json.loads(response.data.decode('utf-8'))
        print(f"PagerDuty notification sent. Status: {response.status}, Message: {response_data.get('message', '')}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notification sent to PagerDuty',
                'status': response_data.get('status'),
                'dedup_key': response_data.get('dedup_key')
            })
        }
        
    except Exception as e:
        print(f"Error sending to PagerDuty: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
