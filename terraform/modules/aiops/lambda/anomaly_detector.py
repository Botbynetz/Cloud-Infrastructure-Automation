"""Anomaly Detector - Detect anomalies in real-time metrics using statistical methods"""
import os, json, boto3, base64
from datetime import datetime
from statistics import mean, stdev

sns = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
ANOMALY_THRESHOLD = float(os.environ.get('ANOMALY_THRESHOLD', '0.8'))

# In-memory cache for historical data (simplified)
metrics_history = {}

def handler(event, context):
    """Process Kinesis stream records and detect anomalies"""
    anomalies = []
    
    for record in event['Records']:
        # Decode Kinesis data
        payload = json.loads(base64.b64decode(record['kinesis']['data']))
        
        # Check for anomaly
        if is_anomaly(payload):
            anomalies.append(payload)
            
            # Publish custom metric
            cloudwatch.put_metric_data(
                Namespace=f'{PROJECT_NAME}/{ENVIRONMENT}/AIOps',
                MetricData=[{
                    'MetricName': 'AnomaliesDetected',
                    'Value': 1,
                    'Unit': 'Count',
                    'Timestamp': datetime.now()
                }]
            )
    
    # Send alert if anomalies detected
    if anomalies:
        send_alert(anomalies)
    
    return {'statusCode': 200, 'anomalies_detected': len(anomalies)}

def is_anomaly(metric_data):
    """Simple statistical anomaly detection using Z-score"""
    key = f"{metric_data['instance_id']}_{metric_data['metric_name']}"
    value = metric_data['value']
    
    # Initialize history
    if key not in metrics_history:
        metrics_history[key] = []
    
    # Add to history
    metrics_history[key].append(value)
    
    # Keep last 100 data points
    if len(metrics_history[key]) > 100:
        metrics_history[key].pop(0)
    
    # Need at least 10 data points
    if len(metrics_history[key]) < 10:
        return False
    
    # Calculate Z-score
    hist = metrics_history[key]
    avg = mean(hist)
    std = stdev(hist) if len(hist) > 1 else 0
    
    if std == 0:
        return False
    
    z_score = abs((value - avg) / std)
    
    # Anomaly if Z-score > threshold (default 3 = 99.7% confidence)
    return z_score > (ANOMALY_THRESHOLD * 3)

def send_alert(anomalies):
    """Send SNS notification for detected anomalies"""
    message = f"""AIOps Anomaly Alert - {datetime.now().strftime('%Y-%m-%d %H:%M UTC')}
Project: {PROJECT_NAME}-{ENVIRONMENT}

Anomalies Detected: {len(anomalies)}

Details:
"""
    for a in anomalies[:5]:  # Top 5
        message += f"\n- {a['instance_id']} | {a['metric_name']}: {a['value']:.2f} {a['unit']}"
    
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"AIOps: Anomalies Detected", Message=message)
