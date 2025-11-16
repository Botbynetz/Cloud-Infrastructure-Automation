"""
Rightsizing Advisor Lambda - Automated EC2 rightsizing recommendations
"""
import os, json, boto3
from datetime import datetime, timedelta

ec2 = boto3.client('ec2')
cloudwatch = boto3.client('cloudwatch')
ce = boto3.client('ce')
sns = boto3.client('sns')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
CPU_LOW = float(os.environ.get('CPU_THRESHOLD_LOW', '20'))
CPU_HIGH = float(os.environ.get('CPU_THRESHOLD_HIGH', '80'))
AUTO_APPLY = os.environ.get('AUTO_APPLY_RECOMMENDATIONS', 'false').lower() == 'true'
DRY_RUN = os.environ.get('DRY_RUN', 'true').lower() == 'true'

def handler(event, context):
    print(f"Starting rightsizing analysis for {PROJECT_NAME}-{ENVIRONMENT}")
    
    try:
        # Get AWS rightsizing recommendations
        aws_recommendations = get_aws_recommendations()
        
        # Analyze current instances
        instances = get_all_instances()
        custom_recommendations = []
        
        for instance in instances:
            avg_cpu = get_avg_cpu_utilization(instance['InstanceId'])
            recommendation = analyze_instance(instance, avg_cpu)
            
            if recommendation:
                custom_recommendations.append(recommendation)
        
        # Generate report
        report = {
            'analysis_date': str(datetime.now()),
            'project': f"{PROJECT_NAME}-{ENVIRONMENT}",
            'aws_recommendations': aws_recommendations,
            'custom_recommendations': custom_recommendations,
            'summary': {
                'total_instances': len(instances),
                'recommendations_count': len(custom_recommendations),
                'potential_monthly_savings': sum(r.get('estimated_savings', 0) for r in custom_recommendations)
            }
        }
        
        # Send notification if recommendations found
        if custom_recommendations:
            send_notification(report)
        
        return {'statusCode': 200, 'body': json.dumps(report)}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        send_error_notification(str(e))
        raise

def get_aws_recommendations():
    try:
        response = ce.get_rightsizing_recommendation(
            Service='AmazonEC2',
            Configuration={'RecommendationTarget': 'SAME_INSTANCE_FAMILY'}
        )
        return {
            'count': len(response.get('RightsizingRecommendations', [])),
            'recommendations': response.get('RightsizingRecommendations', [])[:10]
        }
    except:
        return {'count': 0, 'recommendations': []}

def get_all_instances():
    response = ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
    instances = []
    for reservation in response['Reservations']:
        instances.extend(reservation['Instances'])
    return instances

def get_avg_cpu_utilization(instance_id):
    try:
        end_time = datetime.now()
        start_time = end_time - timedelta(days=14)
        
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
            StartTime=start_time,
            EndTime=end_time,
            Period=86400,
            Statistics=['Average']
        )
        
        if response['Datapoints']:
            return sum(d['Average'] for d in response['Datapoints']) / len(response['Datapoints'])
        return 0
    except:
        return 0

def analyze_instance(instance, avg_cpu):
    instance_id = instance['InstanceId']
    instance_type = instance['InstanceType']
    
    if avg_cpu < CPU_LOW:
        return {
            'instance_id': instance_id,
            'current_type': instance_type,
            'avg_cpu_utilization': round(avg_cpu, 2),
            'recommendation': 'DOWNSIZE',
            'reason': f'CPU utilization ({avg_cpu:.1f}%) below threshold ({CPU_LOW}%)',
            'suggested_action': 'Consider downsizing to smaller instance type',
            'estimated_savings': 50  # Placeholder
        }
    elif avg_cpu > CPU_HIGH:
        return {
            'instance_id': instance_id,
            'current_type': instance_type,
            'avg_cpu_utilization': round(avg_cpu, 2),
            'recommendation': 'UPSIZE',
            'reason': f'CPU utilization ({avg_cpu:.1f}%) above threshold ({CPU_HIGH}%)',
            'suggested_action': 'Consider upsizing to larger instance type'
        }
    return None

def send_notification(report):
    message = f"""Rightsizing Analysis - {datetime.now().strftime('%Y-%m-%d')}
Project: {PROJECT_NAME}-{ENVIRONMENT}

Total Instances Analyzed: {report['summary']['total_instances']}
Recommendations: {report['summary']['recommendations_count']}
Potential Monthly Savings: ${report['summary']['potential_monthly_savings']:.2f}

Top Recommendations:
"""
    for rec in report['custom_recommendations'][:5]:
        message += f"\n- {rec['instance_id']} ({rec['current_type']}): {rec['recommendation']} - {rec['reason']}"
    
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"Rightsizing Report: {PROJECT_NAME}-{ENVIRONMENT}", Message=message)

def send_error_notification(error):
    sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"Rightsizing Error: {PROJECT_NAME}", Message=f"Error: {error}")
