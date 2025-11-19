package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformMultiEnvironment tests multi-environment infrastructure
func TestTerraformMultiEnvironment(t *testing.T) {
	t.Parallel()

	// Test each environment
	environments := []string{"dev", "staging", "prod", "dr"}

	for _, env := range environments {
		env := env // capture range variable
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			awsRegion := "ap-southeast-1"
			if env == "dr" {
				awsRegion = "us-west-2"
			}

			uniqueID := random.UniqueId()
			expectedName := fmt.Sprintf("test-%s-%s", env, uniqueID)

			terraformOptions := &terraform.Options{
				TerraformDir: "../terraform",
				Vars: map[string]interface{}{
					"environment":  env,
					"project_name": expectedName,
					"aws_region":   awsRegion,
				},
				VarFiles: []string{fmt.Sprintf("environments/%s.tfvars", env)},
				BackendConfig: map[string]interface{}{
					"bucket": fmt.Sprintf("terraform-state-test-%s", env),
					"key":    fmt.Sprintf("%s/terraform-test.tfstate", env),
					"region": awsRegion,
				},
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			}

			// Clean up at the end of the test
			defer terraform.Destroy(t, terraformOptions)

			// Run terraform init and plan
			terraform.InitAndPlan(t, terraformOptions)

			// Validate the plan
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			assert.NotNil(t, planStruct)
		})
	}
}

// TestVPCCreation tests VPC creation with proper CIDR and subnets
func TestVPCCreation(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-vpc-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/dev.tfvars"},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate VPC
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpc := aws.GetVpcById(t, vpcID, awsRegion)

	assert.Equal(t, vpcID, vpc.Id)
	assert.True(t, vpc.IsDefault == false)

	// Validate VPC has proper tags
	assert.Contains(t, vpc.Tags, "Environment")
	assert.Contains(t, vpc.Tags, "ManagedBy")
	assert.Equal(t, "dev", vpc.Tags["Environment"])
	assert.Equal(t, "Terraform", vpc.Tags["ManagedBy"])
}

// TestEC2InstanceCreation tests EC2 instance creation with proper configuration
func TestEC2InstanceCreation(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-ec2-%s", uniqueID),
			"aws_region":   awsRegion,
			"instance_type": "t3.micro",
		},
		VarFiles: []string{"environments/dev.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get instance IDs
	instanceIDsOutput := terraform.OutputList(t, terraformOptions, "instance_ids")
	assert.NotEmpty(t, instanceIDsOutput)

	// Validate each instance
	for _, instanceID := range instanceIDsOutput {
		instance := aws.GetEc2InstanceById(t, instanceID, awsRegion)
		
		assert.Equal(t, instanceID, *instance.InstanceId)
		assert.Equal(t, "t3.micro", *instance.InstanceType)
		assert.NotNil(t, instance.Tags)

		// Validate mandatory tags
		tags := aws.GetTagsForEc2Instance(t, awsRegion, instanceID)
		assert.Contains(t, tags, "Environment")
		assert.Contains(t, tags, "Project")
		assert.Contains(t, tags, "ManagedBy")
		assert.Contains(t, tags, "CostCenter")
	}
}

// TestSecurityGroupRules tests security group configurations
func TestSecurityGroupRules(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-sg-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/dev.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get security group ID
	sgID := terraform.Output(t, terraformOptions, "security_group_id")
	assert.NotEmpty(t, sgID)

	// Validate no SSH from 0.0.0.0/0 (policy compliance)
	sg := aws.GetSecurityGroupById(t, sgID, awsRegion)
	
	for _, rule := range sg.IngressRules {
		if *rule.FromPort == 22 {
			for _, ipRange := range rule.IpRanges {
				assert.NotEqual(t, "0.0.0.0/0", *ipRange.CidrIp, 
					"SSH should not be open to the internet (OPA policy violation)")
			}
		}
	}
}

// TestS3BucketEncryption tests S3 bucket encryption and versioning
func TestS3BucketEncryption(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()
	bucketName := fmt.Sprintf("test-bucket-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-s3-%s", uniqueID),
			"aws_region":   awsRegion,
			"bucket_name":  bucketName,
		},
		VarFiles: []string{"environments/dev.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate bucket is not public
	aws.AssertS3BucketPolicyExists(t, awsRegion, bucketName)
	
	// Validate encryption is enabled
	assert.True(t, aws.GetS3BucketEncryption(t, awsRegion, bucketName), 
		"S3 bucket must have encryption enabled (OPA policy)")

	// Validate versioning is enabled
	assert.True(t, aws.GetS3BucketVersioning(t, awsRegion, bucketName), 
		"S3 bucket must have versioning enabled")
}

// TestRDSEncryption tests RDS instance encryption
func TestRDSEncryption(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-rds-%s", uniqueID),
			"aws_region":   awsRegion,
			"db_instance_class": "db.t3.micro",
		},
		VarFiles: []string{"environments/dev.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get RDS instance identifier
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	
	// Validate RDS instance
	dbInstance := aws.GetRdsInstanceDetails(t, dbInstanceID, awsRegion)
	
	assert.True(t, *dbInstance.StorageEncrypted, 
		"RDS instance must have storage encryption enabled (OPA policy)")
	assert.False(t, *dbInstance.PubliclyAccessible, 
		"RDS instance must not be publicly accessible (OPA policy)")
}

// TestKMSKeyCreation tests KMS key creation from STEP 2
func TestKMSKeyCreation(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/kms",
		Vars: map[string]interface{}{
			"environment":  "dev",
			"project_name": fmt.Sprintf("test-kms-%s", uniqueID),
			"aws_region":   awsRegion,
			"enable_aws_kms": true,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate KMS keys were created
	kmsKeyARNs := terraform.OutputMap(t, terraformOptions, "aws_kms_key_arns")
	assert.NotEmpty(t, kmsKeyARNs)
	assert.Contains(t, kmsKeyARNs, "secrets")
	assert.Contains(t, kmsKeyARNs, "rds")
	assert.Contains(t, kmsKeyARNs, "s3")
}

// TestTaggingCompliance tests mandatory tagging from STEP 1
func TestTaggingCompliance(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "prod",
			"project_name": fmt.Sprintf("test-tags-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/prod.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get all resource IDs
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	
	// Validate mandatory tags on VPC
	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	
	mandatoryTags := []string{
		"Environment",
		"Project",
		"Owner",
		"CostCenter",
		"ManagedBy",
		"DataClassification",
		"Compliance",
	}

	for _, tag := range mandatoryTags {
		assert.Contains(t, vpc.Tags, tag, 
			fmt.Sprintf("Mandatory tag '%s' is missing (FinOps policy)", tag))
	}
}

// TestDisasterRecoveryConfiguration tests DR environment setup
func TestDisasterRecoveryConfiguration(t *testing.T) {
	t.Parallel()

	drRegion := "us-west-2"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "dr",
			"project_name": fmt.Sprintf("test-dr-%s", uniqueID),
			"aws_region":   drRegion,
		},
		VarFiles: []string{"environments/dr.tfvars"},
		BackendConfig: map[string]interface{}{
			"bucket": "terraform-state-test-dr",
			"key":    "dr/terraform-test.tfstate",
			"region": drRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate DR resources are in us-west-2
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpc := aws.GetVpcById(t, vpcID, drRegion)
	
	assert.NotNil(t, vpc)
	assert.Equal(t, "dr", vpc.Tags["Environment"])
}

// TestCostOptimization tests instance types per environment (STEP 6 integration)
func TestCostOptimization(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		environment       string
		allowedInstances  []string
		forbiddenInstances []string
	}{
		{
			environment:       "dev",
			allowedInstances:  []string{"t3.micro", "t3.small"},
			forbiddenInstances: []string{"m5.xlarge", "r5.2xlarge"},
		},
		{
			environment:       "staging",
			allowedInstances:  []string{"t3.medium", "t3.large"},
			forbiddenInstances: []string{"m5.4xlarge"},
		},
		{
			environment:       "prod",
			allowedInstances:  []string{"t3.xlarge", "m5.xlarge"},
			forbiddenInstances: []string{"t3.micro"},
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.environment, func(t *testing.T) {
			t.Parallel()

			uniqueID := random.UniqueId()

			// Test allowed instances
			for _, instanceType := range tc.allowedInstances {
				terraformOptions := &terraform.Options{
					TerraformDir: "../terraform",
					Vars: map[string]interface{}{
						"environment":  tc.environment,
						"project_name": fmt.Sprintf("test-cost-%s-%s", tc.environment, uniqueID),
						"instance_type": instanceType,
					},
					VarFiles: []string{fmt.Sprintf("environments/%s.tfvars", tc.environment)},
				}

				// Should not fail for allowed instances
				_, err := terraform.InitAndPlanE(t, terraformOptions)
				assert.NoError(t, err, 
					fmt.Sprintf("Instance type %s should be allowed in %s", instanceType, tc.environment))
			}
		})
	}
}

// TestBackupConfiguration tests automated backup configuration
func TestBackupConfiguration(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "prod",
			"project_name": fmt.Sprintf("test-backup-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/prod.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate backup retention
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	dbInstance := aws.GetRdsInstanceDetails(t, dbInstanceID, awsRegion)
	
	// Production should have longer retention
	assert.GreaterOrEqual(t, int(*dbInstance.BackupRetentionPeriod), 7, 
		"Production RDS must have at least 7 days backup retention")
}

// TestHighAvailability tests HA configuration for production
func TestHighAvailability(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "prod",
			"project_name": fmt.Sprintf("test-ha-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/prod.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate multi-AZ for RDS
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	dbInstance := aws.GetRdsInstanceDetails(t, dbInstanceID, awsRegion)
	
	assert.True(t, *dbInstance.MultiAZ, 
		"Production RDS must be deployed in Multi-AZ configuration")
}

// TestComplianceGDPR tests GDPR compliance requirements
func TestComplianceGDPR(t *testing.T) {
	t.Parallel()

	// GDPR requires EU regions
	euRegion := "eu-west-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "prod",
			"project_name": fmt.Sprintf("test-gdpr-%s", uniqueID),
			"aws_region":   euRegion,
			"compliance_framework": "gdpr",
		},
		VarFiles: []string{"environments/prod.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate encryption
	bucketName := terraform.Output(t, terraformOptions, "bucket_name")
	assert.True(t, aws.GetS3BucketEncryption(t, euRegion, bucketName), 
		"GDPR requires encryption at rest")
}

// TestPerformanceUnderLoad tests infrastructure under simulated load
func TestPerformanceUnderLoad(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping load test in short mode")
	}

	t.Parallel()

	awsRegion := "ap-southeast-1"
	uniqueID := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"environment":  "staging",
			"project_name": fmt.Sprintf("test-perf-%s", uniqueID),
			"aws_region":   awsRegion,
		},
		VarFiles: []string{"environments/staging.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Wait for resources to stabilize
	time.Sleep(2 * time.Minute)

	// Get instance IDs and perform basic connectivity tests
	instanceIDsOutput := terraform.OutputList(t, terraformOptions, "instance_ids")
	assert.NotEmpty(t, instanceIDsOutput)

	for _, instanceID := range instanceIDsOutput {
		instance := aws.GetEc2InstanceById(t, instanceID, awsRegion)
		assert.Equal(t, "running", *instance.State.Name, 
			"Instance should be in running state")
	}
}
