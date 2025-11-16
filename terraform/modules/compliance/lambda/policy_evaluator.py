"""Policy Evaluator - Daily compliance policy evaluation"""
import os, json, boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
config = boto3.client('config')
s3 = boto3.client('s3')
ec2 = boto3.client('ec2')
rds = boto3.client('rds')

TABLE_NAME = os.environ['EVALUATIONS_TABLE']
BUCKET_NAME = os.environ['EVIDENCE_BUCKET']
evaluations_table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """Evaluate all resources against compliance policies"""
    try:
        timestamp = int(datetime.now().timestamp())
        
        # Evaluate Config rules
        config_compliance = evaluate_config_rules()
        
        # Evaluate custom policies
        ec2_compliance = evaluate_ec2_instances()
        s3_compliance = evaluate_s3_buckets()
        rds_compliance = evaluate_rds_instances()
        
        # Aggregate results
        all_results = config_compliance + ec2_compliance + s3_compliance + rds_compliance
        
        # Store evaluations
        for result in all_results:
            evaluations_table.put_item(Item={
                'resource_arn': result['resource_arn'],
                'timestamp': timestamp,
                'policy_id': result['policy_id'],
                'compliance_status': result['status'],
                'details': json.dumps(result.get('details', {})),
                'ttl': timestamp + (86400 * 365)  # 1 year retention
            })
        
        # Store evidence in S3
        evidence_key = f"evaluations/{datetime.now().strftime('%Y/%m/%d')}/evaluation-{timestamp}.json"
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=evidence_key,
            Body=json.dumps(all_results, indent=2),
            ServerSideEncryption='AES256'
        )
        
        # Calculate compliance score
        compliant = sum(1 for r in all_results if r['status'] == 'COMPLIANT')
        total = len(all_results)
        score = (compliant / total * 100) if total > 0 else 0
        
        print(f"✅ Evaluated {total} resources. Compliance score: {score:.1f}%")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'total_resources': total,
                'compliant': compliant,
                'non_compliant': total - compliant,
                'compliance_score': round(score, 2)
            })
        }
    except Exception as e:
        print(f"❌ Error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def evaluate_config_rules():
    """Get Config rule compliance status"""
    try:
        response = config.describe_compliance_by_config_rule()
        results = []
        for rule in response.get('ComplianceByConfigRules', []):
            results.append({
                'resource_arn': f"config-rule:{rule['ConfigRuleName']}",
                'policy_id': rule['ConfigRuleName'],
                'status': rule['Compliance']['ComplianceType'],
                'details': {'source': 'AWS Config'}
            })
        return results
    except Exception as e:
        print(f"Config rules error: {e}")
        return []

def evaluate_ec2_instances():
    """Evaluate EC2 instances for compliance"""
    try:
        instances = ec2.describe_instances()
        results = []
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                arn = f"arn:aws:ec2:{instance['Placement']['AvailabilityZone'][:-1]}::instance/{instance['InstanceId']}"
                
                # Check encryption
                encrypted = all(
                    bdm.get('Ebs', {}).get('Encrypted', False)
                    for bdm in instance.get('BlockDeviceMappings', [])
                )
                
                results.append({
                    'resource_arn': arn,
                    'policy_id': 'ec2-encryption-required',
                    'status': 'COMPLIANT' if encrypted else 'NON_COMPLIANT',
                    'details': {'instance_id': instance['InstanceId'], 'encrypted': encrypted}
                })
        return results
    except Exception as e:
        print(f"EC2 evaluation error: {e}")
        return []

def evaluate_s3_buckets():
    """Evaluate S3 buckets for compliance"""
    try:
        buckets = s3.list_buckets()
        results = []
        for bucket in buckets.get('Buckets', []):
            bucket_name = bucket['Name']
            
            # Check public access block
            try:
                pub_access = s3.get_public_access_block(Bucket=bucket_name)
                is_private = pub_access['PublicAccessBlockConfiguration']['BlockPublicAcls']
                status = 'COMPLIANT' if is_private else 'NON_COMPLIANT'
            except:
                status = 'NON_COMPLIANT'
            
            results.append({
                'resource_arn': f"arn:aws:s3:::{bucket_name}",
                'policy_id': 's3-public-access-blocked',
                'status': status,
                'details': {'bucket': bucket_name}
            })
        return results
    except Exception as e:
        print(f"S3 evaluation error: {e}")
        return []

def evaluate_rds_instances():
    """Evaluate RDS instances for encryption"""
    try:
        instances = rds.describe_db_instances()
        results = []
        for instance in instances.get('DBInstances', []):
            encrypted = instance.get('StorageEncrypted', False)
            results.append({
                'resource_arn': instance['DBInstanceArn'],
                'policy_id': 'rds-encryption-required',
                'status': 'COMPLIANT' if encrypted else 'NON_COMPLIANT',
                'details': {'db_instance': instance['DBInstanceIdentifier'], 'encrypted': encrypted}
            })
        return results
    except Exception as e:
        print(f"RDS evaluation error: {e}")
        return []
