package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformInfrastructure(t *testing.T) {
	t.Parallel()

	// Pick a random AWS region to test
	awsRegion := "ap-southeast-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../terraform",

		// Variables to pass to Terraform
		VarFiles: []string{"env/dev.tfvars"},

		Vars: map[string]interface{}{
			"environment": "test",
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	// Run validations
	testVPCExists(t, terraformOptions, awsRegion)
	testEC2InstanceExists(t, terraformOptions, awsRegion)
	testSecurityGroupConfiguration(t, terraformOptions, awsRegion)
	testWebServerResponding(t, terraformOptions)
}

func testVPCExists(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	assert.NotNil(t, vpc, "VPC should exist")
}

func testEC2InstanceExists(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	instanceID := terraform.Output(t, terraformOptions, "ec2_instance_id")
	assert.NotEmpty(t, instanceID, "EC2 Instance ID should not be empty")

	instance := aws.GetEc2InstanceById(t, instanceID, awsRegion)
	assert.NotNil(t, instance, "EC2 Instance should exist")
	assert.Equal(t, "running", *instance.State.Name, "Instance should be running")
}

func testSecurityGroupConfiguration(t *testing.T, terraformOptions *terraform.Options, awsRegion string) {
	sgID := terraform.Output(t, terraformOptions, "security_group_id")
	assert.NotEmpty(t, sgID, "Security Group ID should not be empty")

	// Get security group details
	sg := aws.GetSecurityGroupById(t, sgID, awsRegion)
	assert.NotNil(t, sg, "Security Group should exist")

	// Check that SSH (22), HTTP (80), and HTTPS (443) are open
	hasSSH := false
	hasHTTP := false
	hasHTTPS := false

	for _, rule := range sg.IpPermissions {
		if rule.FromPort != nil {
			switch *rule.FromPort {
			case 22:
				hasSSH = true
			case 80:
				hasHTTP = true
			case 443:
				hasHTTPS = true
			}
		}
	}

	assert.True(t, hasSSH, "Security group should allow SSH on port 22")
	assert.True(t, hasHTTP, "Security group should allow HTTP on port 80")
	assert.True(t, hasHTTPS, "Security group should allow HTTPS on port 443")
}

func testWebServerResponding(t *testing.T, terraformOptions *terraform.Options) {
	publicIP := terraform.Output(t, terraformOptions, "ec2_public_ip")
	assert.NotEmpty(t, publicIP, "Public IP should not be empty")

	url := fmt.Sprintf("http://%s", publicIP)
	
	// Wait for the web server to be ready (up to 5 minutes with 5 second intervals)
	maxRetries := 60
	sleepBetweenRetries := 5 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		url,
		nil,
		200,
		"Cloud Infrastructure",
		maxRetries,
		sleepBetweenRetries,
	)

	// Test health endpoint
	healthURL := fmt.Sprintf("%s/health", url)
	http_helper.HttpGetWithRetry(
		t,
		healthURL,
		nil,
		200,
		"healthy",
		10,
		2*time.Second,
	)
}

func TestTerraformOutputs(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform",
		VarFiles:     []string{"env/dev.tfvars"},
	})

	// This test assumes infrastructure is already deployed
	// It only validates the outputs without creating/destroying resources

	// Validate VPC ID format
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.Regexp(t, "^vpc-[a-z0-9]+$", vpcID, "VPC ID should match AWS format")

	// Validate EC2 Instance ID format
	instanceID := terraform.Output(t, terraformOptions, "ec2_instance_id")
	assert.Regexp(t, "^i-[a-z0-9]+$", instanceID, "Instance ID should match AWS format")

	// Validate Public IP format
	publicIP := terraform.Output(t, terraformOptions, "ec2_public_ip")
	assert.Regexp(t, "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", publicIP, "Public IP should be valid IPv4")

	// Validate website URL
	websiteURL := terraform.Output(t, terraformOptions, "website_url")
	assert.Contains(t, websiteURL, "http://", "Website URL should start with http://")
	assert.Contains(t, websiteURL, publicIP, "Website URL should contain the public IP")
}
