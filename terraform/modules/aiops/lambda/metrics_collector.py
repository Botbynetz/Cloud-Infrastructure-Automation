"""Metrics Collector - Collect CloudWatch metrics for ML training"""
import os, json, boto3
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch')
kinesis = boto3.client('kinesis')
s3 = boto3.client('s3')
ec2 = boto3.client('ec2')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
KINESIS_STREAM = os.environ['KINESIS_STREAM']
S3_BUCKET = os.environ['S3_BUCKET']

def handler(event, context):
    """Collect metrics from CloudWatch and send to Kinesis + S3"""
    print(f"Collecting metrics for {PROJECT_NAME}-{ENVIRONMENT}")
    
    try:
        # Get EC2 instances
        instances = ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])['Reservations']
        
        metrics_data = []
        
        for reservation in instances:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                
                # Collect CPU, Network, Disk metrics
                for metric_name in ['CPUUtilization', 'NetworkIn', 'NetworkOut', 'DiskReadBytes', 'DiskWriteBytes']:
                    metric_value = get_metric(instance_id, metric_name)
                    
                    if metric_value is not None:
                        metrics_data.append({
                            'timestamp': datetime.now().isoformat(),
                            'instance_id': instance_id,
                            'metric_name': metric_name,
                            'value': metric_value,
                            'unit': get_metric_unit(metric_name)
                        })
        
        # Send to Kinesis
        for metric in metrics_data:
            kinesis.put_record(
                StreamName=KINESIS_STREAM,
                Data=json.dumps(metric),
                PartitionKey=metric['instance_id']
            )
        
        # Save to S3 for ML training
        s3_key = f"metrics/{datetime.now().strftime('%Y/%m/%d/%H%M%S')}.json"
        s3.put_object(Bucket=S3_BUCKET, Key=s3_key, Body=json.dumps(metrics_data))
        
        print(f"Collected {len(metrics_data)} metrics")
        return {'statusCode': 200, 'metrics_collected': len(metrics_data)}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        raise

def get_metric(instance_id, metric_name):
    try:
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName=metric_name,
            Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
            StartTime=datetime.now() - timedelta(minutes=10),
            EndTime=datetime.now(),
            Period=300,
            Statistics=['Average']
        )
        if response['Datapoints']:
            return response['Datapoints'][0]['Average']
    except:
        pass
    return None

def get_metric_unit(metric_name):
    units = {
        'CPUUtilization': 'Percent',
        'NetworkIn': 'Bytes',
        'NetworkOut': 'Bytes',
        'DiskReadBytes': 'Bytes',
        'DiskWriteBytes': 'Bytes'
    }
    return units.get(metric_name, 'None')
