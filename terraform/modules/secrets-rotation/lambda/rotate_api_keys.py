"""
API Key Rotation Lambda Function
Rotates API keys and updates Secrets Manager
"""

import json
import boto3
import os
import secrets
import string
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

secrets_client = boto3.client('secretsmanager')

PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
KMS_KEY_ARN = os.environ.get('KMS_KEY_ARN', '')
API_ENDPOINT = os.environ.get('API_ENDPOINT', '')

def lambda_handler(event, context):
    """Main Lambda handler for API key rotation"""
    
    print(f"[INFO] Starting API key rotation for {PROJECT_NAME}/{ENVIRONMENT}")
    
    try:
        # List all secrets for this project/environment
        secret_list = secrets_client.list_secrets(
            Filters=[
                {'Key': 'name', 'Values': [f'{PROJECT_NAME}/{ENVIRONMENT}/api-keys']}
            ]
        )
        
        rotated_count = 0
        failed_count = 0
        
        for secret in secret_list.get('SecretList', []):
            try:
                rotate_api_key(secret['ARN'])
                rotated_count += 1
            except Exception as e:
                print(f"[ERROR] Failed to rotate {secret['Name']}: {str(e)}")
                failed_count += 1
        
        print(f"[INFO] Rotation complete. Success: {rotated_count}, Failed: {failed_count}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'rotated': rotated_count,
                'failed': failed_count
            })
        }
    
    except Exception as e:
        print(f"[ERROR] Rotation failed: {str(e)}")
        raise e


def rotate_api_key(secret_arn):
    """Rotate a single API key"""
    
    # Get current secret
    current_secret = secrets_client.get_secret_value(SecretId=secret_arn)
    current_dict = json.loads(current_secret['SecretString'])
    
    # Check last rotation date
    last_rotated = current_dict.get('last_rotated')
    if last_rotated:
        last_date = datetime.fromisoformat(last_rotated)
        if datetime.now() - last_date < timedelta(days=85):
            print(f"[INFO] Secret {secret_arn} rotated recently, skipping")
            return
    
    # Generate new API key
    new_api_key = generate_api_key()
    
    # Update secret
    current_dict['api_key'] = new_api_key
    current_dict['last_rotated'] = datetime.now().isoformat()
    current_dict['rotation_count'] = current_dict.get('rotation_count', 0) + 1
    
    # Store updated secret
    secrets_client.put_secret_value(
        SecretId=secret_arn,
        SecretString=json.dumps(current_dict)
    )
    
    print(f"[INFO] Successfully rotated API key for {secret_arn}")


def generate_api_key(length=64):
    """Generate a secure API key"""
    
    # Use cryptographically secure random
    alphabet = string.ascii_letters + string.digits
    api_key = ''.join(secrets.choice(alphabet) for _ in range(length))
    
    # Add prefix for identification
    return f"{PROJECT_NAME}_{ENVIRONMENT}_{api_key}"
