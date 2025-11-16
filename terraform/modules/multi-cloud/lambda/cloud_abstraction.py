"""Cloud Abstraction Layer - Unified API for AWS/Azure/GCP"""
import os, json, boto3, uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')

INVENTORY_TABLE = os.environ['INVENTORY_TABLE']
inventory_table = dynamodb.Table(INVENTORY_TABLE)

def handler(event, context):
    """Handle multi-cloud provisioning requests"""
    try:
        route_key = event.get('routeKey', '')
        
        if route_key == 'POST /provision':
            return provision_resource(event)
        elif route_key == 'GET /resources':
            return list_resources(event)
        else:
            return {'statusCode': 404, 'body': json.dumps({'error': 'Route not found'})}
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def provision_resource(event):
    """Provision resource on specified cloud provider"""
    body = json.loads(event.get('body', '{}'))
    provider = body.get('provider', 'aws')  # aws, azure, gcp
    resource_type = body.get('type')  # compute, storage, database
    config = body.get('config', {})
    
    resource_id = str(uuid.uuid4())
    
    # Route to appropriate cloud provider
    if provider == 'aws':
        result = provision_aws_resource(resource_type, config)
    elif provider == 'azure':
        result = {'message': 'Azure provisioning (placeholder)', 'provider': 'azure'}
    elif provider == 'gcp':
        result = {'message': 'GCP provisioning (placeholder)', 'provider': 'gcp'}
    else:
        return {'statusCode': 400, 'body': json.dumps({'error': 'Unsupported provider'})}
    
    # Store in inventory
    inventory_table.put_item(Item={
        'resource_id': resource_id,
        'cloud_provider': provider,
        'resource_type': resource_type,
        'config': json.dumps(config),
        'result': json.dumps(result),
        'created_at': int(datetime.now().timestamp())
    })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'resource_id': resource_id,
            'provider': provider,
            'result': result
        })
    }

def provision_aws_resource(resource_type, config):
    """Provision AWS resources"""
    if resource_type == 'compute':
        response = ec2.run_instances(
            ImageId=config.get('ami', 'ami-0c55b159cbfafe1f0'),
            InstanceType=config.get('instance_type', 't3.micro'),
            MinCount=1,
            MaxCount=1
        )
        return {'instance_id': response['Instances'][0]['InstanceId'], 'provider': 'aws'}
    elif resource_type == 'storage':
        s3 = boto3.client('s3')
        bucket_name = config.get('bucket_name', f"multi-cloud-{uuid.uuid4().hex[:8]}")
        s3.create_bucket(Bucket=bucket_name)
        return {'bucket_name': bucket_name, 'provider': 'aws'}
    else:
        return {'error': 'Unsupported resource type'}

def list_resources(event):
    """List all multi-cloud resources"""
    try:
        response = inventory_table.scan(Limit=50)
        resources = response.get('Items', [])
        return {
            'statusCode': 200,
            'body': json.dumps({
                'total': len(resources),
                'resources': resources
            }, default=str)
        }
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
