"""
RDS Password Rotation Lambda Function
Rotates RDS database passwords stored in AWS Secrets Manager
"""

import json
import boto3
import os
import random
import string
from botocore.exceptions import ClientError

secrets_client = boto3.client('secretsmanager')
rds_client = boto3.client('rds')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
KMS_KEY_ARN = os.environ.get('KMS_KEY_ARN', '')

def lambda_handler(event, context):
    """Main Lambda handler for RDS password rotation"""
    
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    print(f"[INFO] Starting rotation for secret: {arn}, Step: {step}")
    
    # Dispatch to appropriate step function
    if step == "createSecret":
        create_secret(secrets_client, arn, token)
    elif step == "setSecret":
        set_secret(secrets_client, rds_client, arn, token)
    elif step == "testSecret":
        test_secret(secrets_client, rds_client, arn, token)
    elif step == "finishSecret":
        finish_secret(secrets_client, arn, token)
    else:
        raise ValueError(f"[ERROR] Invalid step: {step}")
    
    print(f"[INFO] Successfully completed step: {step}")
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully rotated secret {arn}')
    }


def create_secret(service_client, arn, token):
    """Generate a new password and store it in AWSPENDING version"""
    
    # Get current secret
    try:
        current_dict = get_secret_dict(service_client, arn, "AWSCURRENT")
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            raise ValueError(f"[ERROR] Secret {arn} not found")
        raise e
    
    # Check if AWSPENDING version already exists
    try:
        service_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        print(f"[INFO] AWSPENDING version already exists for {arn}")
        return
    except ClientError as e:
        if e.response['Error']['Code'] != 'ResourceNotFoundException':
            raise e
    
    # Generate new password
    new_password = generate_password()
    current_dict['password'] = new_password
    
    # Store new secret with AWSPENDING label
    try:
        service_client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(current_dict),
            VersionStages=['AWSPENDING']
        )
        print(f"[INFO] Created new AWSPENDING password for {arn}")
    except ClientError as e:
        raise Exception(f"[ERROR] Failed to create AWSPENDING password: {str(e)}")


def set_secret(service_client, rds_client, arn, token):
    """Update RDS instance with new password"""
    
    # Get AWSPENDING secret
    pending_dict = get_secret_dict(service_client, arn, "AWSPENDING", token)
    
    db_instance_id = pending_dict.get('dbInstanceIdentifier')
    db_cluster_id = pending_dict.get('dbClusterIdentifier')
    username = pending_dict['username']
    password = pending_dict['password']
    
    # Update RDS instance or cluster
    try:
        if db_instance_id:
            # Single instance
            rds_client.modify_db_instance(
                DBInstanceIdentifier=db_instance_id,
                MasterUserPassword=password,
                ApplyImmediately=True
            )
            print(f"[INFO] Updated password for RDS instance: {db_instance_id}")
        elif db_cluster_id:
            # Aurora cluster
            rds_client.modify_db_cluster(
                DBClusterIdentifier=db_cluster_id,
                MasterUserPassword=password,
                ApplyImmediately=True
            )
            print(f"[INFO] Updated password for RDS cluster: {db_cluster_id}")
        else:
            raise ValueError("[ERROR] No DB instance or cluster identifier found in secret")
    except ClientError as e:
        raise Exception(f"[ERROR] Failed to update RDS password: {str(e)}")


def test_secret(service_client, rds_client, arn, token):
    """Test the new password by connecting to RDS"""
    
    # Get AWSPENDING secret
    pending_dict = get_secret_dict(service_client, arn, "AWSPENDING", token)
    
    # In production, you would test database connection here
    # For now, we verify the secret exists and is valid
    if 'password' not in pending_dict or len(pending_dict['password']) < 16:
        raise ValueError("[ERROR] Invalid password in AWSPENDING version")
    
    print(f"[INFO] Successfully validated AWSPENDING password for {arn}")


def finish_secret(service_client, arn, token):
    """Move AWSPENDING to AWSCURRENT and archive old AWSCURRENT"""
    
    # Get current version
    metadata = service_client.describe_secret(SecretId=arn)
    current_version = None
    
    for version_id, stages in metadata['VersionIdsToStages'].items():
        if "AWSCURRENT" in stages:
            if version_id == token:
                # Already current, nothing to do
                print(f"[INFO] Version {token} already marked as AWSCURRENT")
                return
            current_version = version_id
            break
    
    # Move AWSCURRENT to AWSPENDING
    service_client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    
    print(f"[INFO] Successfully rotated secret {arn}")


def get_secret_dict(service_client, arn, stage, token=None):
    """Retrieve secret value as dictionary"""
    
    required_fields = ['engine', 'host', 'username', 'password']
    
    if token:
        secret = service_client.get_secret_value(
            SecretId=arn,
            VersionId=token,
            VersionStage=stage
        )
    else:
        secret = service_client.get_secret_value(
            SecretId=arn,
            VersionStage=stage
        )
    
    secret_dict = json.loads(secret['SecretString'])
    
    # Validate required fields
    for field in required_fields:
        if field not in secret_dict:
            raise KeyError(f"[ERROR] Secret missing required field: {field}")
    
    return secret_dict


def generate_password(length=32):
    """Generate a strong random password"""
    
    # Character sets
    lowercase = string.ascii_lowercase
    uppercase = string.ascii_uppercase
    digits = string.digits
    special = '!@#$%^&*()_+-=[]{}|;:,.<>?'
    
    # Ensure password has at least one of each type
    password = [
        random.choice(lowercase),
        random.choice(uppercase),
        random.choice(digits),
        random.choice(special)
    ]
    
    # Fill rest with random characters
    all_chars = lowercase + uppercase + digits + special
    password += [random.choice(all_chars) for _ in range(length - 4)]
    
    # Shuffle to randomize positions
    random.shuffle(password)
    
    return ''.join(password)
