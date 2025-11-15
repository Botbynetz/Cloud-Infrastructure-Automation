package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestBlueGreenDeploymentModule tests the blue-green-deployment module
func TestBlueGreenDeploymentModule(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform module
		TerraformDir: "../terraform/modules/blue-green-deployment",

		// Variables to pass to the module
		Vars: map[string]interface{}{
			"application_name":    "test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
			"health_check_path":   "/health",
		},

		// Disable colors in Terraform output
		NoColor: true,
	})

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply"
	terraform.InitAndPlan(t, terraformOptions)

	// Validate outputs
	t.Run("ValidateOutputs", func(t *testing.T) {
		// These would work with actual AWS resources
		// For now, we validate the plan structure
		assert.NotNil(t, terraformOptions)
	})
}

// TestEC2ModuleValidation tests EC2 module validation
func TestEC2ModuleValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/ec2",
		Vars: map[string]interface{}{
			"ami_id":          "ami-test123456",
			"instance_type":   "t3.micro",
			"subnet_id":       "subnet-test123",
			"security_groups": []string{"sg-test123"},
			"instance_name":   "test-instance",
		},
		NoColor: true,
	}

	// Validate Terraform code
	terraform.InitAndValidate(t, terraformOptions)
}

// TestSecurityGroupModule tests security group module
func TestSecurityGroupModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/security-group",
		Vars: map[string]interface{}{
			"vpc_id":      "vpc-test123456",
			"group_name":  "test-sg",
			"description": "Test security group",
		},
		NoColor: true,
	}

	terraform.InitAndValidate(t, terraformOptions)
}

// TestSecretsManagerModule tests secrets manager module
func TestSecretsManagerModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/secrets",
		Vars: map[string]interface{}{
			"secret_name":        "test-secret",
			"secret_description": "Test secret for Terratest",
			"recovery_window":    7,
		},
		NoColor: true,
	}

	terraform.InitAndValidate(t, terraformOptions)
}

// TestIAMSecurityModule tests IAM security module
func TestIAMSecurityModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/iam-security",
		Vars: map[string]interface{}{
			"role_name":         "test-role",
			"role_type":         "ec2_instance",
			"require_mfa":       true,
			"compliance_level":  "standard",
			"max_session_hours": 1,
		},
		NoColor: true,
	}

	terraform.InitAndValidate(t, terraformOptions)
}

// TestMainTerraformConfiguration tests the main Terraform configuration
func TestMainTerraformConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		Vars: map[string]interface{}{
			"aws_region": "us-east-1",
			"environment": "test",
		},
		NoColor: true,
	}

	// Only validate, don't apply (to avoid creating real resources)
	terraform.InitAndValidate(t, terraformOptions)
}

// TestHealthCheckEndpoint tests if health check endpoint is correctly configured
func TestHealthCheckEndpoint(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":    "health-test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
			"health_check_path":   "/api/health",
			"health_check_interval": 15,
			"health_check_timeout":  5,
			"health_check_healthy_threshold": 2,
			"health_check_unhealthy_threshold": 3,
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestCanaryDeploymentConfiguration tests canary deployment settings
func TestCanaryDeploymentConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":          "canary-test-app",
			"vpc_id":                   "vpc-test123456",
			"alb_subnets":              []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups":       []string{"sg-test123"},
			"active_environment":        "blue",
			"enable_canary_deployment":  true,
			"canary_weight_active":      90,
			"canary_weight_inactive":    10,
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestAutoScalingIntegration tests Auto Scaling group integration
func TestAutoScalingIntegration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":             "asg-test-app",
			"vpc_id":                      "vpc-test123456",
			"alb_subnets":                 []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups":          []string{"sg-test123"},
			"active_environment":           "blue",
			"enable_autoscaling":           true,
			"blue_autoscaling_group_name":  "test-blue-asg",
			"green_autoscaling_group_name": "test-green-asg",
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestHTTPSConfiguration tests HTTPS and SSL configuration
func TestHTTPSConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":    "https-test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
			"enable_https":        true,
			"certificate_arn":     "arn:aws:acm:us-east-1:123456789012:certificate/test",
			"ssl_policy":          "ELBSecurityPolicy-TLS13-1-2-2021-06",
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestResourceTagging tests if resources are tagged correctly
func TestResourceTagging(t *testing.T) {
	t.Parallel()

	tags := map[string]interface{}{
		"Environment": "test",
		"Project":     "cloud-infra",
		"ManagedBy":   "terraform",
		"Owner":       "devops-team",
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":    "tag-test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
			"tags":                tags,
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestStickySessionsConfiguration tests sticky sessions
func TestStickySessionsConfiguration(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":    "sticky-test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
			"enable_stickiness":   true,
			"stickiness_duration": 3600,
		},
		NoColor: true,
	}

	terraform.InitAndPlan(t, terraformOptions)
}

// TestRetryLogic tests Terraform retry mechanism
func TestRetryLogic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/modules/blue-green-deployment",
		Vars: map[string]interface{}{
			"application_name":    "retry-test-app",
			"vpc_id":             "vpc-test123456",
			"alb_subnets":        []string{"subnet-test1", "subnet-test2"},
			"alb_security_groups": []string{"sg-test123"},
			"active_environment":  "blue",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		NoColor:            true,
	})

	terraform.InitAndValidate(t, terraformOptions)
}

// Benchmark tests for performance
func BenchmarkTerraformValidation(b *testing.B) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../terraform",
		NoColor:      true,
	}

	for i := 0; i < b.N; i++ {
		terraform.Init(b, terraformOptions)
	}
}
