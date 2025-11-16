"""
Cost Analyzer Lambda Function
Performs advanced cost analysis, anomaly detection, and waste identification
"""

import os
import json
import boto3
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Initialize AWS clients
ce_client = boto3.client('ce')
s3_client = boto3.client('s3')
athena_client = boto3.client('athena')
sns_client = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

# Environment variables
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'cloud-infra')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')
COST_BUCKET = os.environ.get('COST_BUCKET')
ATHENA_DATABASE = os.environ.get('ATHENA_DATABASE')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
WASTE_THRESHOLD_USD = float(os.environ.get('WASTE_THRESHOLD_USD', '5'))
ANOMALY_THRESHOLD_PCT = float(os.environ.get('ANOMALY_THRESHOLD_PCT', '20'))

def handler(event, context):
    """
    Main Lambda handler for cost analysis
    """
    print(f"Starting cost analysis for {PROJECT_NAME}-{ENVIRONMENT}")
    
    try:
        # Get date range (last 30 days)
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=30)
        
        # Perform cost analysis
        cost_summary = get_cost_and_usage(start_date, end_date)
        cost_forecast = get_cost_forecast(end_date)
        service_breakdown = get_service_breakdown(start_date, end_date)
        anomalies = detect_cost_anomalies(start_date, end_date)
        waste_resources = identify_waste(service_breakdown)
        
        # Calculate savings opportunities
        ri_recommendations = get_ri_recommendations()
        savings_plans_recommendations = get_savings_plans_recommendations()
        
        # Publish custom metrics to CloudWatch
        publish_cost_metrics(cost_summary, cost_forecast, waste_resources)
        
        # Generate analysis report
        report = generate_cost_report(
            cost_summary,
            cost_forecast,
            service_breakdown,
            anomalies,
            waste_resources,
            ri_recommendations,
            savings_plans_recommendations
        )
        
        # Send notification if anomalies or waste detected
        if anomalies or waste_resources:
            send_notification(report, anomalies, waste_resources)
        
        print(f"Cost analysis completed successfully")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost analysis completed',
                'summary': report
            })
        }
        
    except Exception as e:
        print(f"Error in cost analysis: {str(e)}")
        send_error_notification(str(e))
        raise

def get_cost_and_usage(start_date, end_date) -> Dict[str, Any]:
    """Get total cost and usage for date range"""
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': str(start_date),
                'End': str(end_date)
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost', 'UsageQuantity'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ]
        )
        
        total_cost = sum(
            float(result['Total']['UnblendedCost']['Amount'])
            for result in response['ResultsByTime']
        )
        
        return {
            'total_cost': round(total_cost, 2),
            'period': f"{start_date} to {end_date}",
            'currency': 'USD',
            'results': response['ResultsByTime']
        }
    except Exception as e:
        print(f"Error getting cost and usage: {str(e)}")
        return {'total_cost': 0, 'error': str(e)}

def get_cost_forecast(start_date) -> Dict[str, Any]:
    """Get cost forecast for next 30 days"""
    try:
        end_date = start_date + timedelta(days=30)
        
        response = ce_client.get_cost_forecast(
            TimePeriod={
                'Start': str(start_date),
                'End': str(end_date)
            },
            Metric='UNBLENDED_COST',
            Granularity='MONTHLY'
        )
        
        forecast_cost = float(response['Total']['Amount'])
        
        return {
            'forecasted_cost': round(forecast_cost, 2),
            'period': f"{start_date} to {end_date}",
            'currency': 'USD'
        }
    except Exception as e:
        print(f"Error getting cost forecast: {str(e)}")
        return {'forecasted_cost': 0, 'error': str(e)}

def get_service_breakdown(start_date, end_date) -> List[Dict[str, Any]]:
    """Get cost breakdown by AWS service"""
    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': str(start_date),
                'End': str(end_date)
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ]
        )
        
        services = []
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                
                if cost > 0:
                    services.append({
                        'service': service,
                        'cost': round(cost, 2)
                    })
        
        # Sort by cost descending
        services.sort(key=lambda x: x['cost'], reverse=True)
        
        return services
    except Exception as e:
        print(f"Error getting service breakdown: {str(e)}")
        return []

def detect_cost_anomalies(start_date, end_date) -> List[Dict[str, Any]]:
    """
    Detect cost anomalies using simple statistical analysis
    Compares current period with previous period
    """
    anomalies = []
    
    try:
        # Current period (last 7 days)
        current_end = end_date
        current_start = current_end - timedelta(days=7)
        
        # Previous period (previous 7 days)
        previous_end = current_start
        previous_start = previous_end - timedelta(days=7)
        
        # Get costs for both periods
        current_cost = ce_client.get_cost_and_usage(
            TimePeriod={'Start': str(current_start), 'End': str(current_end)},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
        
        previous_cost = ce_client.get_cost_and_usage(
            TimePeriod={'Start': str(previous_start), 'End': str(previous_end)},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
        
        # Calculate service costs
        current_services = {}
        for result in current_cost['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                current_services[service] = current_services.get(service, 0) + cost
        
        previous_services = {}
        for result in previous_cost['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                previous_services[service] = previous_services.get(service, 0) + cost
        
        # Detect anomalies (> threshold % increase)
        for service, current in current_services.items():
            previous = previous_services.get(service, 0)
            
            if previous > 0:
                change_pct = ((current - previous) / previous) * 100
                
                if abs(change_pct) > ANOMALY_THRESHOLD_PCT:
                    anomalies.append({
                        'service': service,
                        'previous_cost': round(previous, 2),
                        'current_cost': round(current, 2),
                        'change_percentage': round(change_pct, 2),
                        'severity': 'high' if abs(change_pct) > 50 else 'medium'
                    })
        
        return anomalies
    except Exception as e:
        print(f"Error detecting anomalies: {str(e)}")
        return []

def identify_waste(service_breakdown: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Identify potential waste resources
    This is a simple heuristic - real implementation would query CloudWatch metrics
    """
    waste = []
    
    # Services commonly associated with waste
    waste_indicators = {
        'Amazon Elastic Compute Cloud - Compute': 'Idle EC2 instances',
        'Amazon Relational Database Service': 'Unused RDS instances',
        'Amazon Elastic Load Balancing': 'Unused load balancers',
        'Amazon Elastic Block Store': 'Unattached EBS volumes',
        'Amazon Simple Storage Service': 'Old S3 data without lifecycle policies'
    }
    
    for service_cost in service_breakdown:
        service = service_cost['service']
        cost = service_cost['cost']
        
        if service in waste_indicators and cost > WASTE_THRESHOLD_USD:
            waste.append({
                'service': service,
                'monthly_cost': cost,
                'potential_issue': waste_indicators[service],
                'recommendation': f"Review {service} resources for optimization"
            })
    
    return waste

def get_ri_recommendations() -> Dict[str, Any]:
    """Get Reserved Instance purchase recommendations"""
    try:
        response = ce_client.get_reservation_purchase_recommendation(
            Service='Amazon Elastic Compute Cloud - Compute',
            LookbackPeriodInDays='SIXTY_DAYS',
            TermInYears='ONE_YEAR',
            PaymentOption='NO_UPFRONT'
        )
        
        recommendations = []
        if 'Recommendations' in response:
            for rec in response['Recommendations']:
                details = rec.get('RecommendationDetails', {})
                recommendations.append({
                    'instance_type': details.get('InstanceDetails', {}).get('EC2InstanceDetails', {}).get('InstanceType'),
                    'estimated_monthly_savings': details.get('EstimatedMonthlySavingsAmount'),
                    'upfront_cost': details.get('UpfrontCost')
                })
        
        return {
            'count': len(recommendations),
            'recommendations': recommendations[:5]  # Top 5
        }
    except Exception as e:
        print(f"Error getting RI recommendations: {str(e)}")
        return {'count': 0, 'recommendations': []}

def get_savings_plans_recommendations() -> Dict[str, Any]:
    """Get Savings Plans purchase recommendations"""
    try:
        response = ce_client.get_savings_plans_purchase_recommendation(
            LookbackPeriodInDays='SIXTY_DAYS',
            TermInYears='ONE_YEAR',
            PaymentOption='NO_UPFRONT',
            SavingsPlansType='COMPUTE_SP'
        )
        
        recommendations = []
        if 'SavingsPlansPurchaseRecommendation' in response:
            details = response['SavingsPlansPurchaseRecommendation'].get('SavingsPlansPurchaseRecommendationDetails', [])
            for rec in details:
                recommendations.append({
                    'hourly_commitment': rec.get('HourlyCommitmentToPurchase'),
                    'estimated_monthly_savings': rec.get('EstimatedMonthlySavingsAmount'),
                    'estimated_roi': rec.get('EstimatedROI')
                })
        
        return {
            'count': len(recommendations),
            'recommendations': recommendations[:5]  # Top 5
        }
    except Exception as e:
        print(f"Error getting Savings Plans recommendations: {str(e)}")
        return {'count': 0, 'recommendations': []}

def publish_cost_metrics(cost_summary: Dict, forecast: Dict, waste: List):
    """Publish custom cost metrics to CloudWatch"""
    try:
        metrics = [
            {
                'MetricName': 'TotalMonthlyCost',
                'Value': cost_summary.get('total_cost', 0),
                'Unit': 'None',
                'Timestamp': datetime.now()
            },
            {
                'MetricName': 'ForecastedMonthlyCost',
                'Value': forecast.get('forecasted_cost', 0),
                'Unit': 'None',
                'Timestamp': datetime.now()
            },
            {
                'MetricName': 'WasteResourcesCount',
                'Value': len(waste),
                'Unit': 'Count',
                'Timestamp': datetime.now()
            }
        ]
        
        cloudwatch.put_metric_data(
            Namespace=f'{PROJECT_NAME}/{ENVIRONMENT}/FinOps',
            MetricData=metrics
        )
        
        print(f"Published {len(metrics)} metrics to CloudWatch")
    except Exception as e:
        print(f"Error publishing metrics: {str(e)}")

def generate_cost_report(cost_summary, forecast, services, anomalies, waste, ri_recs, sp_recs) -> Dict:
    """Generate comprehensive cost analysis report"""
    return {
        'report_date': str(datetime.now()),
        'project': f"{PROJECT_NAME}-{ENVIRONMENT}",
        
        'cost_summary': cost_summary,
        'forecast': forecast,
        
        'top_services': services[:10],  # Top 10 services by cost
        
        'anomalies': {
            'count': len(anomalies),
            'details': anomalies
        },
        
        'waste_opportunities': {
            'count': len(waste),
            'potential_monthly_savings': sum(w['monthly_cost'] for w in waste),
            'details': waste
        },
        
        'optimization_recommendations': {
            'reserved_instances': ri_recs,
            'savings_plans': sp_recs
        },
        
        'summary': {
            'current_monthly_cost': cost_summary.get('total_cost', 0),
            'forecasted_monthly_cost': forecast.get('forecasted_cost', 0),
            'anomalies_detected': len(anomalies),
            'waste_resources_found': len(waste),
            'optimization_opportunities': ri_recs['count'] + sp_recs['count']
        }
    }

def send_notification(report: Dict, anomalies: List, waste: List):
    """Send SNS notification for cost analysis results"""
    try:
        subject = f"FinOps Alert: Cost Analysis for {PROJECT_NAME}-{ENVIRONMENT}"
        
        message = f"""
Cost Analysis Report - {datetime.now().strftime('%Y-%m-%d %H:%M UTC')}
Project: {PROJECT_NAME}-{ENVIRONMENT}

=== COST SUMMARY ===
Current Monthly Cost: ${report['cost_summary'].get('total_cost', 0):.2f}
Forecasted Monthly Cost: ${report['forecast'].get('forecasted_cost', 0):.2f}

=== ANOMALIES DETECTED ===
Total Anomalies: {len(anomalies)}
"""
        
        for anomaly in anomalies[:5]:  # Top 5 anomalies
            message += f"\n- {anomaly['service']}: {anomaly['change_percentage']:+.1f}% change (${anomaly['current_cost']:.2f})"
        
        message += f"\n\n=== WASTE OPPORTUNITIES ===\nTotal Waste Resources: {len(waste)}\n"
        
        for w in waste[:5]:  # Top 5 waste items
            message += f"\n- {w['service']}: ${w['monthly_cost']:.2f}/month - {w['potential_issue']}"
        
        message += f"\n\n=== OPTIMIZATION RECOMMENDATIONS ===\n"
        message += f"Reserved Instance Opportunities: {report['optimization_recommendations']['reserved_instances']['count']}\n"
        message += f"Savings Plans Opportunities: {report['optimization_recommendations']['savings_plans']['count']}\n"
        
        message += f"\n\nView full dashboard: AWS Console > CloudWatch > Dashboards > {PROJECT_NAME}-{ENVIRONMENT}-finops-dashboard"
        
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        
        print(f"Notification sent to SNS topic: {SNS_TOPIC_ARN}")
    except Exception as e:
        print(f"Error sending notification: {str(e)}")

def send_error_notification(error_message: str):
    """Send error notification"""
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"FinOps Error: Cost Analysis Failed for {PROJECT_NAME}-{ENVIRONMENT}",
            Message=f"Cost analysis failed with error:\n\n{error_message}\n\nPlease check CloudWatch Logs for details."
        )
    except Exception as e:
        print(f"Error sending error notification: {str(e)}")
