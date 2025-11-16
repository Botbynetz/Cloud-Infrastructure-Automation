"""
Zero Trust - Just-in-Time (JIT) Access Manager
Provides temporary network access with automated revocation
"""

import json
import boto3
import os
from datetime import datetime, timedelta
import uuid

ec2 = boto3.client('ec2')
sns = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')

# Environment variables
ADMIN_SG_ID = os.environ['ADMIN_SECURITY_GROUP_ID']
PROJECT = os.environ['PROJECT_NAME']
ENV = os.environ['ENVIRONMENT']
JIT_DURATION = int(os.environ['JIT_DURATION_MINUTES'])
SNS_TOPIC = os.environ['SNS_TOPIC_ARN']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
ALLOWED_PORTS = json.loads(os.environ['ALLOWED_PORTS'])

table = dynamodb.Table(DYNAMODB_TABLE)

def handler(event, context):
    """Main Lambda handler for JIT access management"""
    
    action = event.get('action', 'grant')
    
    if action == 'cleanup':
        return cleanup_expired_rules()
    elif action == 'revoke':
        return revoke_access(event)
    else:
        return grant_access(event)

def grant_access(event):
    """Grant JIT access to a user"""
    
    # Extract parameters
    user_email = event.get('user_email')
    user_ip = event.get('user_ip')
    port = event.get('port', 22)
    reason = event.get('reason', 'Administrative access')
    
    # Validate
    if not user_email or not user_ip:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'user_email and user_ip required'})
        }
    
    if port not in ALLOWED_PORTS:
        return {
            'statusCode': 403,
            'body': json.dumps({'error': f'Port {port} not allowed. Allowed ports: {ALLOWED_PORTS}'})
        }
    
    # Generate access ID
    access_id = str(uuid.uuid4())
    now = datetime.utcnow()
    expiration = now + timedelta(minutes=JIT_DURATION)
    
    try:
        # Add security group rule
        response = ec2.authorize_security_group_ingress(
            GroupId=ADMIN_SG_ID,
            IpPermissions=[{
                'IpProtocol': 'tcp',
                'FromPort': port,
                'ToPort': port,
                'IpRanges': [{
                    'CidrIp': f'{user_ip}/32',
                    'Description': f'JIT-{access_id}-{user_email}-expires-{expiration.isoformat()}'
                }]
            }]
        )
        
        # Log to DynamoDB
        table.put_item(Item={
            'access_id': access_id,
            'timestamp': int(now.timestamp()),
            'user_email': user_email,
            'user_ip': user_ip,
            'port': port,
            'reason': reason,
            'granted_at': now.isoformat(),
            'expires_at': expiration.isoformat(),
            'expiration_time': int(expiration.timestamp()),
            'status': 'ACTIVE',
            'security_group_id': ADMIN_SG_ID
        })
        
        # Send notification
        message = f"""JIT Access Granted
        
Access ID: {access_id}
User: {user_email}
Source IP: {user_ip}
Port: {port}
Reason: {reason}
Duration: {JIT_DURATION} minutes
Expires: {expiration.isoformat()}

This access will be automatically revoked after {JIT_DURATION} minutes.
"""
        
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f'JIT Access Granted - {user_email}',
            Message=message
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'access_id': access_id,
                'granted_at': now.isoformat(),
                'expires_at': expiration.isoformat(),
                'duration_minutes': JIT_DURATION,
                'user_ip': user_ip,
                'port': port
            })
        }
        
    except Exception as e:
        print(f"Error granting access: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def revoke_access(event):
    """Manually revoke JIT access"""
    
    access_id = event.get('access_id')
    
    if not access_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'access_id required'})
        }
    
    try:
        # Get access details from DynamoDB
        response = table.get_item(Key={'access_id': access_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Access ID not found'})
            }
        
        item = response['Item']
        
        if item['status'] != 'ACTIVE':
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Access already revoked'})
            }
        
        # Revoke security group rule
        ec2.revoke_security_group_ingress(
            GroupId=item['security_group_id'],
            IpPermissions=[{
                'IpProtocol': 'tcp',
                'FromPort': item['port'],
                'ToPort': item['port'],
                'IpRanges': [{'CidrIp': f"{item['user_ip']}/32"}]
            }]
        )
        
        # Update DynamoDB
        table.update_item(
            Key={'access_id': access_id},
            UpdateExpression='SET #status = :revoked, revoked_at = :now',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':revoked': 'REVOKED',
                ':now': datetime.utcnow().isoformat()
            }
        )
        
        # Send notification
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f'JIT Access Revoked - {item["user_email"]}',
            Message=f'JIT access {access_id} has been manually revoked.'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Access revoked successfully'})
        }
        
    except Exception as e:
        print(f"Error revoking access: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def cleanup_expired_rules():
    """Cleanup expired JIT access rules (runs every 5 minutes)"""
    
    now = datetime.utcnow()
    now_timestamp = int(now.timestamp())
    
    try:
        # Scan DynamoDB for expired active rules
        response = table.scan(
            FilterExpression='#status = :active AND expiration_time < :now',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':active': 'ACTIVE',
                ':now': now_timestamp
            }
        )
        
        expired_count = 0
        
        for item in response['Items']:
            try:
                # Revoke security group rule
                ec2.revoke_security_group_ingress(
                    GroupId=item['security_group_id'],
                    IpPermissions=[{
                        'IpProtocol': 'tcp',
                        'FromPort': item['port'],
                        'ToPort': item['port'],
                        'IpRanges': [{'CidrIp': f"{item['user_ip']}/32"}]
                    }]
                )
                
                # Update DynamoDB
                table.update_item(
                    Key={
                        'access_id': item['access_id'],
                        'timestamp': item['timestamp']
                    },
                    UpdateExpression='SET #status = :expired, revoked_at = :now',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':expired': 'EXPIRED',
                        ':now': now.isoformat()
                    }
                )
                
                expired_count += 1
                print(f"Revoked expired access: {item['access_id']} for {item['user_email']}")
                
            except ec2.exceptions.ClientError as e:
                if 'InvalidPermission.NotFound' in str(e):
                    # Rule already removed, just update DynamoDB
                    table.update_item(
                        Key={
                            'access_id': item['access_id'],
                            'timestamp': item['timestamp']
                        },
                        UpdateExpression='SET #status = :expired',
                        ExpressionAttributeNames={'#status': 'status'},
                        ExpressionAttributeValues={':expired': 'EXPIRED'}
                    )
                else:
                    raise
        
        print(f"Cleanup complete. Revoked {expired_count} expired access rules.")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cleanup complete',
                'expired_count': expired_count
            })
        }
        
    except Exception as e:
        print(f"Error during cleanup: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
