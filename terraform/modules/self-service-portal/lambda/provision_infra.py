"""Provision Infrastructure - Self-service infrastructure provisioning"""
import os, json, boto3, uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')

TABLE_NAME = os.environ['REQUESTS_TABLE']
requests_table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """Handle infrastructure provisioning requests"""
    try:
        body = json.loads(event['body'])
        request_type = body.get('type')  # 'ec2', 'rds', 's3', etc.
        config = body.get('config', {})
        user_email = event['requestContext']['authorizer']['claims']['email']
        
        request_id = str(uuid.uuid4())
        timestamp = int(datetime.now().timestamp())
        
        # Save request
        requests_table.put_item(Item={
            'request_id': request_id,
            'timestamp': timestamp,
            'user_email': user_email,
            'type': request_type,
            'config': json.dumps(config),
            'status': 'pending',
            'ttl': timestamp + (86400 * 90)  # 90 days
        })
        
        # Provision based on type (simplified)
        if request_type == 'ec2':
            result = provision_ec2(config, request_id)
        elif request_type == 's3':
            result = provision_s3(config, request_id)
        else:
            result = {'error': 'Unsupported type'}
        
        # Update request
        requests_table.update_item(
            Key={'request_id': request_id, 'timestamp': timestamp},
            UpdateExpression='SET #status = :status, result = :result',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'completed', ':result': json.dumps(result)}
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'request_id': request_id, 'result': result})
        }
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def provision_ec2(config, request_id):
    """Provision EC2 instance"""
    try:
        response = ec2.run_instances(
            ImageId=config.get('ami', 'ami-0c55b159cbfafe1f0'),
            InstanceType=config.get('instance_type', 't3.micro'),
            MinCount=1,
            MaxCount=1,
            TagSpecifications=[{
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Name', 'Value': config.get('name', f'portal-instance-{request_id[:8]}')},
                    {'Key': 'ManagedBy', 'Value': 'SelfServicePortal'},
                    {'Key': 'RequestId', 'Value': request_id}
                ]
            }]
        )
        return {'instance_id': response['Instances'][0]['InstanceId']}
    except Exception as e:
        return {'error': str(e)}

def provision_s3(config, request_id):
    """Provision S3 bucket"""
    try:
        s3 = boto3.client('s3')
        bucket_name = config.get('bucket_name', f"portal-bucket-{request_id[:8]}")
        s3.create_bucket(Bucket=bucket_name)
        return {'bucket_name': bucket_name}
    except Exception as e:
        return {'error': str(e)}
