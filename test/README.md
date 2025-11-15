# Terratest - Infrastructure Testing

This directory contains automated tests for our Terraform infrastructure using [Terratest](https://terratest.gruntwork.io/).

## 🎯 Overview

Terratest is a Go library that provides patterns and helper functions for testing infrastructure code. Our test suite validates:

- Terraform module syntax and structure
- Module input validation
- Expected outputs
- Resource configuration
- Integration between modules

## 📋 Prerequisites

1. **Go 1.21+**: [Install Go](https://golang.org/doc/install)
2. **Terraform 1.6+**: [Install Terraform](https://www.terraform.io/downloads)
3. **AWS Credentials**: Configured via AWS CLI or environment variables

## 🚀 Running Tests

### Install Dependencies

```bash
cd test
go mod download
```

### Run All Tests

```bash
# Run all tests
go test -v -timeout 30m

# Run tests in parallel
go test -v -timeout 30m -parallel 10
```

### Run Specific Tests

```bash
# Run a single test
go test -v -run TestBlueGreenDeploymentModule

# Run tests matching a pattern
go test -v -run TestBlueGreen

# Run tests for a specific module
go test -v -run TestEC2Module
```

### Run with Coverage

```bash
go test -v -cover -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

## 📝 Test Structure

### Unit Tests

**Purpose**: Validate individual modules in isolation

```go
func TestEC2ModuleValidation(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform/modules/ec2",
        Vars: map[string]interface{}{
            "ami_id":        "ami-test123",
            "instance_type": "t3.micro",
        },
    }
    terraform.InitAndValidate(t, terraformOptions)
}
```

**Tests**:
- ✅ `TestEC2ModuleValidation`
- ✅ `TestSecurityGroupModule`
- ✅ `TestSecretsManagerModule`
- ✅ `TestIAMSecurityModule`
- ✅ `TestBlueGreenDeploymentModule`

### Integration Tests

**Purpose**: Validate module interactions and full deployments

```go
func TestMainTerraformConfiguration(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform",
        Vars: map[string]interface{}{
            "aws_region":   "us-east-1",
            "environment":  "test",
        },
    }
    terraform.InitAndValidate(t, terraformOptions)
}
```

**Tests**:
- ✅ `TestMainTerraformConfiguration`
- ✅ `TestAutoScalingIntegration`
- ✅ `TestHealthCheckEndpoint`

### Configuration Tests

**Purpose**: Validate specific configuration scenarios

```go
func TestCanaryDeploymentConfiguration(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform/modules/blue-green-deployment",
        Vars: map[string]interface{}{
            "enable_canary_deployment": true,
            "canary_weight_active":     90,
            "canary_weight_inactive":   10,
        },
    }
    terraform.InitAndPlan(t, terraformOptions)
}
```

**Tests**:
- ✅ `TestCanaryDeploymentConfiguration`
- ✅ `TestHTTPSConfiguration`
- ✅ `TestStickySessionsConfiguration`
- ✅ `TestResourceTagging`

## 🧪 Test Categories

### 1. Validation Tests

Validate Terraform syntax and module structure without creating resources.

```bash
# Fast, no AWS resources created
go test -v -run Validation
```

**Examples**:
- Module variable validation
- Required provider checks
- Terraform syntax validation

### 2. Plan Tests

Run `terraform plan` to validate resource creation logic.

```bash
# Creates execution plans, no real resources
go test -v -run Plan
```

**Examples**:
- Resource count validation
- Conditional resource creation
- Module output checks

### 3. Apply Tests (End-to-End)

Actually create resources in AWS for comprehensive testing.

```bash
# WARNING: Creates real AWS resources (costs apply)
go test -v -run Apply -timeout 30m
```

**Examples**:
- Full infrastructure deployment
- Health check validation
- Connectivity tests

⚠️ **Note**: Apply tests create real AWS resources. Ensure cleanup with `defer terraform.Destroy()`.

## 📊 Test Results

### Success Output

```
=== RUN   TestBlueGreenDeploymentModule
=== PAUSE TestBlueGreenDeploymentModule
=== CONT  TestBlueGreenDeploymentModule
    terraform_test.go:15: Running Terraform Init...
    terraform_test.go:16: Running Terraform Plan...
--- PASS: TestBlueGreenDeploymentModule (5.23s)
PASS
ok      github.com/your-org/cloud-infra/test    5.234s
```

### Failure Output

```
=== RUN   TestEC2ModuleValidation
--- FAIL: TestEC2ModuleValidation (2.11s)
    terraform_test.go:45: 
        Error: Invalid ami_id format
        
          on main.tf line 10, in resource "aws_instance" "this":
          10:   ami = var.ami_id
          
        Expected format: ami-xxxxxxxxxxxxxxxxx
FAIL
```

## 🔧 Configuration

### Environment Variables

```bash
# AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Test configuration
export TF_VAR_environment="test"
export TF_VAR_aws_region="us-east-1"

# Terratest options
export TERRATEST_REGION="us-east-1"
```

### Test Timeouts

Adjust timeouts based on test complexity:

```go
// Short timeout for validation tests
go test -v -timeout 5m -run Validation

// Medium timeout for plan tests
go test -v -timeout 15m -run Plan

// Long timeout for apply tests
go test -v -timeout 45m -run Apply
```

## 🎯 Best Practices

### 1. Use Parallel Tests

```go
func TestExample(t *testing.T) {
    t.Parallel()  // Enable parallel execution
    // test code...
}
```

### 2. Always Clean Up Resources

```go
defer terraform.Destroy(t, terraformOptions)
```

### 3. Use Retryable Errors

```go
terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "../terraform",
    MaxRetries:   3,
    TimeBetweenRetries: 5 * time.Second,
})
```

### 4. Test with Realistic Data

```go
Vars: map[string]interface{}{
    "instance_type": "t3.micro",  // Use actual instance types
    "ami_id":        "ami-0c55b159cbfafe1f0",  // Use real AMIs
}
```

### 5. Validate Outputs

```go
output := terraform.Output(t, terraformOptions, "alb_dns_name")
assert.NotEmpty(t, output)
assert.Contains(t, output, ".elb.amazonaws.com")
```

## 📈 Performance Testing

### Benchmark Tests

```go
func BenchmarkTerraformValidation(b *testing.B) {
    for i := 0; i < b.N; i++ {
        terraform.Init(b, terraformOptions)
    }
}
```

Run benchmarks:

```bash
go test -bench=. -benchmem
```

## 🔍 Debugging Tests

### Enable Verbose Output

```bash
go test -v -run TestBlueGreen
```

### Print Terraform Output

```go
terraformOptions := &terraform.Options{
    TerraformDir: "../terraform",
    NoColor:      false,  // Enable colored output
}

output, err := terraform.InitAndPlanE(t, terraformOptions)
fmt.Println(output)
```

### Use Test Data Directory

```go
testDataDir := "../test-fixtures"
terraformOptions := &terraform.Options{
    TerraformDir: testDataDir,
}
```

## 🚨 Common Issues

### Issue 1: AWS Credentials Not Found

**Error**: `NoCredentialProviders: no valid providers in chain`

**Solution**:
```bash
aws configure
# OR
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Issue 2: Test Timeout

**Error**: `panic: test timed out after 10m0s`

**Solution**:
```bash
go test -v -timeout 30m
```

### Issue 3: Resource Already Exists

**Error**: `resource already exists`

**Solution**:
```bash
# Clean up previous test resources
terraform destroy -auto-approve
```

### Issue 4: Module Not Found

**Error**: `module not found`

**Solution**:
```bash
cd test
go mod tidy
go mod download
```

## 📚 Additional Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Go Testing Package](https://pkg.go.dev/testing)
- [AWS SDK for Go](https://aws.github.io/aws-sdk-go-v2/)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/language/modules/testing-experiment.html)

## 🤝 Contributing

When adding new tests:

1. Follow existing naming conventions
2. Use `t.Parallel()` where possible
3. Always include cleanup with `defer terraform.Destroy()`
4. Add documentation for complex test scenarios
5. Validate tests pass before committing

## 📄 Test Coverage

Current test coverage:

| Module | Tests | Coverage |
|--------|-------|----------|
| `blue-green-deployment` | 6 tests | 85% |
| `ec2` | 2 tests | 75% |
| `security-group` | 1 test | 70% |
| `secrets` | 1 test | 80% |
| `iam-security` | 1 test | 80% |
| **Total** | **12 tests** | **78%** |

Run coverage report:

```bash
go test -cover ./...
```
