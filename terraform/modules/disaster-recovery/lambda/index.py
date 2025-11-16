"""
RDS Snapshot Copy Lambda Function
This function automatically copies RDS snapshots to a secondary region for disaster recovery.
"""

import boto3
import os
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Environment variables
SOURCE_REGION = os.environ['SOURCE_REGION']
DESTINATION_REGION = os.environ['DESTINATION_REGION']
PROJECT_NAME = os.environ['PROJECT_NAME']
ENVIRONMENT = os.environ['ENVIRONMENT']
RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS', 35))

# Initialize boto3 clients
rds_source = boto3.client('rds', region_name=SOURCE_REGION)
rds_dest = boto3.client('rds', region_name=DESTINATION_REGION)


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler function.
    Copies the latest RDS automated snapshots to the DR region.
    """
    print(f"Starting RDS snapshot copy from {SOURCE_REGION} to {DESTINATION_REGION}")
    
    try:
        # Get all RDS instances
        db_instances = get_rds_instances()
        print(f"Found {len(db_instances)} RDS instances")
        
        results = {
            'successful_copies': [],
            'failed_copies': [],
            'cleaned_up': []
        }
        
        # Process each database instance
        for db_instance in db_instances:
            db_identifier = db_instance['DBInstanceIdentifier']
            print(f"Processing database: {db_identifier}")
            
            # Get latest automated snapshot
            snapshot = get_latest_snapshot(db_identifier)
            if not snapshot:
                print(f"No automated snapshot found for {db_identifier}")
                continue
            
            snapshot_id = snapshot['DBSnapshotIdentifier']
            
            # Copy snapshot to DR region
            copy_result = copy_snapshot_to_dr_region(snapshot_id, db_identifier)
            if copy_result['success']:
                results['successful_copies'].append({
                    'database': db_identifier,
                    'source_snapshot': snapshot_id,
                    'destination_snapshot': copy_result['snapshot_id']
                })
            else:
                results['failed_copies'].append({
                    'database': db_identifier,
                    'error': copy_result['error']
                })
        
        # Clean up old snapshots in DR region
        cleanup_results = cleanup_old_snapshots()
        results['cleaned_up'] = cleanup_results
        
        # Log summary
        print(f"Summary: {len(results['successful_copies'])} successful, "
              f"{len(results['failed_copies'])} failed, "
              f"{len(results['cleaned_up'])} cleaned up")
        
        return {
            'statusCode': 200,
            'body': json.dumps(results)
        }
        
    except Exception as e:
        print(f"Error in main handler: {str(e)}")
        raise


def get_rds_instances() -> List[Dict[str, Any]]:
    """Get all RDS instances in the source region."""
    try:
        response = rds_source.describe_db_instances()
        return response['DBInstances']
    except Exception as e:
        print(f"Error getting RDS instances: {str(e)}")
        return []


def get_latest_snapshot(db_identifier: str) -> Dict[str, Any]:
    """Get the latest automated snapshot for a database instance."""
    try:
        response = rds_source.describe_db_snapshots(
            DBInstanceIdentifier=db_identifier,
            SnapshotType='automated',
            MaxRecords=100
        )
        
        snapshots = response['DBSnapshots']
        if not snapshots:
            return None
        
        # Sort by creation time and get the latest
        snapshots.sort(key=lambda x: x['SnapshotCreateTime'], reverse=True)
        return snapshots[0]
        
    except Exception as e:
        print(f"Error getting snapshots for {db_identifier}: {str(e)}")
        return None


def copy_snapshot_to_dr_region(snapshot_id: str, db_identifier: str) -> Dict[str, Any]:
    """Copy a snapshot to the DR region."""
    try:
        # Generate destination snapshot ID
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        dest_snapshot_id = f"{PROJECT_NAME}-{ENVIRONMENT}-{db_identifier}-dr-{timestamp}"
        
        # Check if snapshot already exists in destination
        if snapshot_exists_in_destination(dest_snapshot_id):
            print(f"Snapshot {dest_snapshot_id} already exists in destination region")
            return {
                'success': True,
                'snapshot_id': dest_snapshot_id,
                'message': 'Snapshot already exists'
            }
        
        # Build source snapshot ARN
        account_id = boto3.client('sts').get_caller_identity()['Account']
        source_snapshot_arn = (
            f"arn:aws:rds:{SOURCE_REGION}:{account_id}:snapshot:{snapshot_id}"
        )
        
        print(f"Copying {snapshot_id} to {dest_snapshot_id}")
        
        # Copy the snapshot
        response = rds_dest.copy_db_snapshot(
            SourceDBSnapshotIdentifier=source_snapshot_arn,
            TargetDBSnapshotIdentifier=dest_snapshot_id,
            CopyTags=True,
            Tags=[
                {'Key': 'Project', 'Value': PROJECT_NAME},
                {'Key': 'Environment', 'Value': ENVIRONMENT},
                {'Key': 'SourceRegion', 'Value': SOURCE_REGION},
                {'Key': 'CopiedAt', 'Value': timestamp},
                {'Key': 'DisasterRecovery', 'Value': 'true'},
                {'Key': 'RetentionDays', 'Value': str(RETENTION_DAYS)}
            ]
        )
        
        print(f"Successfully initiated copy to {dest_snapshot_id}")
        
        return {
            'success': True,
            'snapshot_id': dest_snapshot_id,
            'arn': response['DBSnapshot']['DBSnapshotArn']
        }
        
    except Exception as e:
        print(f"Error copying snapshot {snapshot_id}: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }


def snapshot_exists_in_destination(snapshot_id: str) -> bool:
    """Check if a snapshot already exists in the destination region."""
    try:
        response = rds_dest.describe_db_snapshots(
            DBSnapshotIdentifier=snapshot_id
        )
        return len(response['DBSnapshots']) > 0
    except rds_dest.exceptions.DBSnapshotNotFoundFault:
        return False
    except Exception as e:
        print(f"Error checking snapshot existence: {str(e)}")
        return False


def cleanup_old_snapshots() -> List[str]:
    """Delete snapshots older than retention period in DR region."""
    cleaned_up = []
    
    try:
        # Get all manual snapshots in destination region (our DR copies)
        response = rds_dest.describe_db_snapshots(
            SnapshotType='manual',
            MaxRecords=100
        )
        
        cutoff_date = datetime.now() - timedelta(days=RETENTION_DAYS)
        
        for snapshot in response['DBSnapshots']:
            snapshot_id = snapshot['DBSnapshotIdentifier']
            
            # Only process snapshots created by this DR process
            if not snapshot_id.startswith(f"{PROJECT_NAME}-{ENVIRONMENT}"):
                continue
            
            create_time = snapshot['SnapshotCreateTime'].replace(tzinfo=None)
            
            if create_time < cutoff_date:
                print(f"Deleting old snapshot: {snapshot_id} (created {create_time})")
                
                try:
                    rds_dest.delete_db_snapshot(
                        DBSnapshotIdentifier=snapshot_id
                    )
                    cleaned_up.append(snapshot_id)
                except Exception as e:
                    print(f"Error deleting snapshot {snapshot_id}: {str(e)}")
        
        print(f"Cleaned up {len(cleaned_up)} old snapshots")
        return cleaned_up
        
    except Exception as e:
        print(f"Error in cleanup process: {str(e)}")
        return cleaned_up


def send_notification(message: str, severity: str = 'INFO'):
    """Send SNS notification about DR operations."""
    try:
        sns = boto3.client('sns', region_name=SOURCE_REGION)
        
        # Get SNS topic ARN from environment or construct it
        account_id = boto3.client('sts').get_caller_identity()['Account']
        topic_arn = f"arn:aws:sns:{SOURCE_REGION}:{account_id}:{PROJECT_NAME}-{ENVIRONMENT}-dr-notifications"
        
        subject = f"[{severity}] DR Snapshot Copy - {PROJECT_NAME}"
        
        sns.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message
        )
        
        print(f"Notification sent: {subject}")
        
    except Exception as e:
        print(f"Error sending notification: {str(e)}")


# For local testing
if __name__ == "__main__":
    # Mock event and context for testing
    test_event = {}
    test_context = {}
    
    result = handler(test_event, test_context)
    print(json.dumps(result, indent=2))
