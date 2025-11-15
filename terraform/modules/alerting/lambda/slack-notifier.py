import json
import os
import urllib3
import datetime

http = urllib3.PoolManager()

def handler(event, context):
    """
    Lambda function to send CloudWatch alarm notifications to Slack
    """
    
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    channel = os.environ.get('SLACK_CHANNEL', '#alerts')
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
    
    # Determine color based on state
    color_map = {
        'ALARM': '#FF0000',      # Red
        'OK': '#36A64F',         # Green
        'INSUFFICIENT_DATA': '#FFA500'  # Orange
    }
    color = color_map.get(new_state, '#808080')
    
    # Determine icon based on state
    icon_map = {
        'ALARM': ':rotating_light:',
        'OK': ':white_check_mark:',
        'INSUFFICIENT_DATA': ':warning:'
    }
    icon = icon_map.get(new_state, ':question:')
    
    # Build Slack message
    slack_message = {
        'channel': channel,
        'username': f'{project_name} Monitoring',
        'icon_emoji': ':chart_with_upwards_trend:',
        'attachments': [
            {
                'fallback': f'{alarm_name} is in {new_state} state',
                'color': color,
                'pretext': f'{icon} *CloudWatch Alarm Notification*',
                'author_name': f'{project_name} - {environment.upper()}',
                'title': alarm_name,
                'title_link': f"https://console.aws.amazon.com/cloudwatch/home?region={os.environ.get('AWS_REGION', 'us-east-1')}#alarmsV2:alarm/{alarm_name}",
                'text': alarm_description,
                'fields': [
                    {
                        'title': 'State',
                        'value': f'*{new_state}*',
                        'short': True
                    },
                    {
                        'title': 'Environment',
                        'value': environment.upper(),
                        'short': True
                    },
                    {
                        'title': 'Reason',
                        'value': reason,
                        'short': False
                    }
                ],
                'footer': 'AWS CloudWatch',
                'footer_icon': 'https://a0.awsstatic.com/libra-css/images/logos/aws_logo_smile_1200x630.png',
                'ts': int(datetime.datetime.fromisoformat(timestamp.replace('Z', '+00:00')).timestamp())
            }
        ]
    }
    
    # Send to Slack
    try:
        encoded_msg = json.dumps(slack_message).encode('utf-8')
        response = http.request(
            'POST',
            webhook_url,
            body=encoded_msg,
            headers={'Content-Type': 'application/json'}
        )
        
        print(f"Slack notification sent. Status: {response.status}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Notification sent to Slack'})
        }
        
    except Exception as e:
        print(f"Error sending to Slack: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
