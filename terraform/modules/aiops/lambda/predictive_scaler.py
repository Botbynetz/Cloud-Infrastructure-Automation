"""Predictive Scaler - ML-based predictive auto-scaling"""
import os, json, boto3
from datetime import datetime, timedelta

s3 = boto3.client('s3')
autoscaling = boto3.client('autoscaling')
sns = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
S3_BUCKET = os.environ['S3_BUCKET']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
PREDICTION_WINDOW = int(os.environ.get('PREDICTION_WINDOW', '4'))
ENABLE_SCALING = os.environ.get('ENABLE_AUTO_SCALING', 'false').lower() == 'true'

def handler(event, context):
    """Predict future load and adjust auto-scaling"""
    print(f"Running predictive scaling for {PROJECT_NAME}-{ENVIRONMENT}")
    
    try:
        # Get Auto Scaling Groups
        asgs = autoscaling.describe_auto_scaling_groups()['AutoScalingGroups']
        
        scaling_actions = []
        
        for asg in asgs:
            asg_name = asg['AutoScalingGroupName']
            current_capacity = asg['DesiredCapacity']
            
            # Predict future load (simplified linear regression)
            predicted_load = predict_load(asg_name)
            
            # Calculate recommended capacity
            recommended_capacity = calculate_capacity(predicted_load, asg)
            
            if recommended_capacity != current_capacity:
                scaling_actions.append({
                    'asg_name': asg_name,
                    'current_capacity': current_capacity,
                    'recommended_capacity': recommended_capacity,
                    'predicted_load': predicted_load
                })
                
                # Apply scaling if enabled
                if ENABLE_SCALING:
                    autoscaling.set_desired_capacity(
                        AutoScalingGroupName=asg_name,
                        DesiredCapacity=recommended_capacity
                    )
                    
                    # Publish metric
                    cloudwatch.put_metric_data(
                        Namespace=f'{PROJECT_NAME}/{ENVIRONMENT}/AIOps',
                        MetricData=[{
                            'MetricName': 'PredictiveScalingActions',
                            'Value': 1,
                            'Unit': 'Count',
                            'Timestamp': datetime.now()
                        }]
                    )
        
        # Send notification if actions taken
        if scaling_actions:
            send_notification(scaling_actions)
        
        return {'statusCode': 200, 'scaling_actions': len(scaling_actions)}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        raise

def predict_load(asg_name):
    """Predict future CPU load using simple trend analysis"""
    try:
        # Get historical CPU metrics
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[{'Name': 'AutoScalingGroupName', 'Value': asg_name}],
            StartTime=datetime.now() - timedelta(hours=24),
            EndTime=datetime.now(),
            Period=3600,
            Statistics=['Average']
        )
        
        if len(response['Datapoints']) < 3:
            return 50.0  # Default
        
        # Sort by timestamp
        datapoints = sorted(response['Datapoints'], key=lambda x: x['Timestamp'])
        values = [d['Average'] for d in datapoints]
        
        # Simple linear trend
        n = len(values)
        x_mean = n / 2
        y_mean = sum(values) / n
        
        numerator = sum((i - x_mean) * (values[i] - y_mean) for i in range(n))
        denominator = sum((i - x_mean) ** 2 for i in range(n))
        
        if denominator == 0:
            return values[-1]
        
        slope = numerator / denominator
        
        # Predict PREDICTION_WINDOW hours ahead
        predicted = values[-1] + (slope * PREDICTION_WINDOW)
        
        return max(0, min(100, predicted))  # Clamp to 0-100%
    
    except:
        return 50.0

def calculate_capacity(predicted_load, asg):
    """Calculate recommended capacity based on predicted load"""
    min_size = asg['MinSize']
    max_size = asg['MaxSize']
    
    # Scale up if predicted load > 70%
    if predicted_load > 70:
        return min(max_size, asg['DesiredCapacity'] + 1)
    
    # Scale down if predicted load < 30%
    elif predicted_load < 30:
        return max(min_size, asg['DesiredCapacity'] - 1)
    
    return asg['DesiredCapacity']

def send_notification(actions):
    """Send notification for scaling actions"""
    message = f"""Predictive Scaling - {datetime.now().strftime('%Y-%m-%d %H:%M UTC')}
Project: {PROJECT_NAME}-{ENVIRONMENT}

Scaling Actions: {len(actions)}
Mode: {'ACTIVE' if ENABLE_SCALING else 'DRY RUN'}

Details:
"""
    for action in actions:
        message += f"\n- {action['asg_name']}: {action['current_capacity']} → {action['recommended_capacity']} (predicted load: {action['predicted_load']:.1f}%)"
    
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"Predictive Scaling: {PROJECT_NAME}", Message=message)
