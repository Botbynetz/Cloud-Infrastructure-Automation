# OPA Policy Tests
# Test security, cost, and compliance policies

package terraform_test

import future.keywords

# ============================================
# SECURITY POLICY TESTS
# ============================================

# Test: Block public S3 bucket
test_deny_public_s3_bucket {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_s3_bucket.public_bucket",
            "type": "aws_s3_bucket",
            "change": {
                "after": {
                    "acl": "public-read",
                    "tags": {"Environment": "dev"}
                }
            }
        }]
    }
    
    count(result) > 0
    result[_] == "SECURITY VIOLATION: S3 bucket 'aws_s3_bucket.public_bucket' has public-read ACL. Use private ACL only."
}

# Test: Allow private S3 bucket
test_allow_private_s3_bucket {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_s3_bucket.private_bucket",
            "type": "aws_s3_bucket",
            "change": {
                "after": {
                    "acl": "private",
                    "server_side_encryption_configuration": {},
                    "tags": {
                        "Environment": "prod",
                        "Project": "test",
                        "Owner": "admin",
                        "CostCenter": "CC-001",
                        "ManagedBy": "Terraform"
                    }
                }
            }
        }]
    }
    
    count(result) == 0
}

# Test: Block unencrypted EBS volume
test_deny_unencrypted_ebs {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_ebs_volume.unencrypted",
            "type": "aws_ebs_volume",
            "change": {
                "after": {
                    "encrypted": false,
                    "size": 100
                }
            }
        }]
    }
    
    count(result) > 0
}

# Test: Block SSH from 0.0.0.0/0
test_deny_ssh_from_internet {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_security_group_rule.allow_ssh",
            "type": "aws_security_group_rule",
            "change": {
                "after": {
                    "type": "ingress",
                    "from_port": 22,
                    "to_port": 22,
                    "protocol": "tcp",
                    "cidr_blocks": ["0.0.0.0/0"]
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "SSH (port 22) from 0.0.0.0/0")
}

# Test: Allow SSH from specific CIDR
test_allow_ssh_from_specific_cidr {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_security_group_rule.allow_ssh_vpn",
            "type": "aws_security_group_rule",
            "change": {
                "after": {
                    "type": "ingress",
                    "from_port": 22,
                    "to_port": 22,
                    "protocol": "tcp",
                    "cidr_blocks": ["10.0.0.0/8"]
                }
            }
        }]
    }
    
    # Should not have SSH violation for private CIDR
    not contains(result[_], "SSH (port 22)")
}

# Test: Enforce IMDSv2 for EC2
test_enforce_imdsv2 {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_instance.web",
            "type": "aws_instance",
            "change": {
                "after": {
                    "instance_type": "t3.micro",
                    "metadata_options": {
                        "http_tokens": "optional"
                    },
                    "tags": {
                        "Environment": "dev",
                        "Project": "test",
                        "Owner": "admin",
                        "CostCenter": "CC-001",
                        "ManagedBy": "Terraform"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "IMDSv2")
}

# ============================================
# COST POLICY TESTS
# ============================================

# Test: Block expensive instance in dev
test_deny_expensive_instance_in_dev {
    result := terraform.cost.deny with input as {
        "resource_changes": [{
            "address": "aws_instance.expensive",
            "type": "aws_instance",
            "change": {
                "after": {
                    "instance_type": "m5.8xlarge",
                    "tags": {
                        "Environment": "dev"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "COST VIOLATION")
}

# Test: Allow appropriate instance in dev
test_allow_small_instance_in_dev {
    result := terraform.cost.deny with input as {
        "resource_changes": [{
            "address": "aws_instance.small",
            "type": "aws_instance",
            "change": {
                "after": {
                    "instance_type": "t3.micro",
                    "tags": {
                        "Environment": "dev"
                    }
                }
            }
        }]
    }
    
    count(result) == 0
}

# Test: Block multi-AZ RDS in dev
test_deny_multi_az_rds_in_dev {
    result := terraform.cost.deny with input as {
        "resource_changes": [{
            "address": "aws_db_instance.dev_db",
            "type": "aws_db_instance",
            "change": {
                "after": {
                    "multi_az": true,
                    "tags": {
                        "Environment": "dev"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "multi-AZ")
}

# Test: Block oversized EBS in dev
test_deny_large_ebs_in_dev {
    result := terraform.cost.deny with input as {
        "resource_changes": [{
            "address": "aws_ebs_volume.large",
            "type": "aws_ebs_volume",
            "change": {
                "after": {
                    "size": 500,
                    "tags": {
                        "Environment": "dev"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "exceeds dev/staging limit")
}

# ============================================
# COMPLIANCE POLICY TESTS
# ============================================

# Test: Missing mandatory tags
test_deny_missing_mandatory_tags {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_instance.no_tags",
            "type": "aws_instance",
            "change": {
                "after": {
                    "instance_type": "t3.micro",
                    "tags": {
                        "Environment": "dev"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "missing mandatory tags")
}

# Test: GDPR encryption enforcement
test_gdpr_encryption_required {
    result := terraform.compliance.deny with input as {
        "resource_changes": [{
            "address": "aws_s3_bucket.gdpr_data",
            "type": "aws_s3_bucket",
            "change": {
                "after": {
                    "tags": {
                        "DataClassification": "confidential",
                        "Compliance": "GDPR"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "GDPR VIOLATION")
}

# Test: HIPAA public access denied
test_hipaa_no_public_access {
    result := terraform.compliance.deny with input as {
        "resource_changes": [{
            "address": "aws_db_instance.hipaa_db",
            "type": "aws_db_instance",
            "change": {
                "after": {
                    "publicly_accessible": true,
                    "storage_encrypted": true,
                    "tags": {
                        "DataClassification": "restricted",
                        "Compliance": "HIPAA"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "HIPAA VIOLATION")
    contains(result[_], "publicly accessible")
}

# Test: Production backup retention
test_production_backup_retention {
    result := deny with input as {
        "resource_changes": [{
            "address": "aws_db_instance.prod_db",
            "type": "aws_db_instance",
            "change": {
                "after": {
                    "backup_retention_period": 3,
                    "storage_encrypted": true,
                    "tags": {
                        "Environment": "prod",
                        "Project": "test",
                        "Owner": "admin",
                        "CostCenter": "CC-001",
                        "ManagedBy": "Terraform",
                        "BackupPolicy": "daily"
                    }
                }
            }
        }]
    }
    
    count(result) > 0
    contains(result[_], "backup retention >= 7 days")
}
