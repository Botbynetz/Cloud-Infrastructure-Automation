"""Auto-Remediation - Automatically fix non-compliant resources"""
import os, json, boto3

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')

TABLE_NAME = os.environ['EVALUATIONS_TABLE']
SNS_TOPIC = os.environ['SNS_TOPIC_ARN']
AUTO_REMEDIATE = os.environ.get('AUTO_REMEDIATE', 'false').lower() == 'true'

def handler(event, context):
    """Handle Config compliance change events"""
    try:
        detail = event.get('detail', {})
        config_rule = detail.get('configRuleName')
        resource_type = detail.get('resourceType')
        resource_id = detail.get('resourceId')
        compliance_type = detail.get('newEvaluationResult', {}).get('complianceType')
        
        if compliance_type != 'NON_COMPLIANT':
            return {'statusCode': 200, 'body': 'Resource is compliant'}
        
        print(f"⚠️ Non-compliant resource: {resource_id} ({config_rule})")
        
        remediated = False
        if AUTO_REMEDIATE:
            # Attempt remediation
            if 's3-bucket-public' in config_rule.lower():
                remediated = remediate_s3_public_access(resource_id)
            elif 'encrypted-volumes' in config_rule.lower():
                remediated = remediate_unencrypted_volume(resource_id)
        
        # Send notification
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f"⚠️ Compliance Alert: {config_rule}",
            Message=f"""Non-compliant resource detected:

Rule: {config_rule}
Resource: {resource_id} ({resource_type})
Status: {'REMEDIATED ✅' if remediated else 'REQUIRES MANUAL INTERVENTION ⚠️'}

Action Required: {'None - auto-remediated' if remediated else 'Manual review and remediation needed'}
"""
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'resource_id': resource_id,
                'rule': config_rule,
                'remediated': remediated
            })
        }
    except Exception as e:
        print(f"❌ Remediation error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def remediate_s3_public_access(bucket_name):
    """Block public access on S3 bucket"""
    try:
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        print(f"✅ Blocked public access on bucket: {bucket_name}")
        return True
    except Exception as e:
        print(f"❌ Failed to remediate S3 bucket {bucket_name}: {e}")
        return False

def remediate_unencrypted_volume(volume_id):
    """Tag unencrypted volume for remediation (encryption requires snapshot)"""
    try:
        ec2 = boto3.client('ec2')
        ec2.create_tags(
            Resources=[volume_id],
            Tags=[
                {'Key': 'ComplianceStatus', 'Value': 'NonCompliant'},
                {'Key': 'RemediationRequired', 'Value': 'Encryption'}
            ]
        )
        print(f"⚠️ Tagged unencrypted volume {volume_id} for manual remediation")
        return False  # Encryption requires manual snapshot/restore
    except Exception as e:
        print(f"❌ Failed to tag volume {volume_id}: {e}")
        return False
