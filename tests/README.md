# Terratest for Cloud Infrastructure

This directory contains automated tests for the Terraform infrastructure using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21 or higher
- AWS credentials configured
- Terraform installed

## Setup

Install Go dependencies:

```bash
cd tests
go mod download
```

## Running Tests

### Run all tests

```bash
go test -v -timeout 30m
```

### Run specific test

```bash
go test -v -timeout 30m -run TestTerraformInfrastructure
```

### Run tests in parallel

```bash
go test -v -timeout 30m -parallel 10
```

## Test Structure

### TestTerraformInfrastructure

This is the main integration test that:
1. Deploys the infrastructure using Terraform
2. Validates VPC creation
3. Validates EC2 instance is running
4. Validates Security Group configuration
5. Validates web server is responding
6. Destroys all resources after testing

### TestTerraformOutputs

This test validates Terraform outputs format without deploying resources.

## Test Coverage

The tests validate:
- ✅ VPC exists and is properly configured
- ✅ EC2 instance is running
- ✅ Security groups have correct ingress rules (SSH, HTTP, HTTPS)
- ✅ Web server is accessible and returns expected content
- ✅ Health check endpoint is working
- ✅ Output formats are correct

## CI/CD Integration

These tests can be integrated into your CI/CD pipeline:

```yaml
- name: Run Terratest
  run: |
    cd tests
    go test -v -timeout 30m
```

## Important Notes

1. **Cost Warning**: Running these tests will create real AWS resources and incur costs
2. **Cleanup**: Tests automatically destroy resources, but ensure manual cleanup if tests fail
3. **Timeout**: Tests can take 10-20 minutes to complete
4. **Parallel Testing**: Use `-parallel` flag carefully to avoid AWS rate limits

## Troubleshooting

### Test times out
- Increase timeout: `-timeout 60m`
- Check AWS credentials
- Verify security group rules

### Resources not destroyed
Run manual cleanup:
```bash
cd ../terraform
terraform destroy -var-file="env/dev.tfvars"
```

### Import errors
```bash
go mod tidy
go mod download
```

## Best Practices

1. Run tests in a separate AWS account or environment
2. Use unique environment names to avoid conflicts
3. Monitor AWS costs during test runs
4. Always verify resource cleanup after tests
