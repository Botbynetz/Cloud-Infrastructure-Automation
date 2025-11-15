# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of our cloud infrastructure project seriously. If you have discovered a security vulnerability, we appreciate your help in disclosing it to us in a responsible manner.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **GitHub Security Advisories** (Preferred)
   - Navigate to the repository
   - Click on "Security" tab
   - Click "Report a vulnerability"
   - Fill in the details

2. **Email** (Alternative)
   - Send details to the project maintainers
   - Use subject line: `[SECURITY] Brief description`
   - Include steps to reproduce

### What to Include

Please include the following information in your report:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Assessment**: We will assess the vulnerability and determine its impact and severity
- **Fix Development**: We will work on a fix and keep you informed of progress
- **Disclosure**: We will publicly disclose the vulnerability after a fix is available
- **Credit**: We will credit you for the discovery (unless you prefer to remain anonymous)

### Response Timeline

- **48 hours**: Initial response acknowledging the report
- **7 days**: Assessment and severity classification
- **30 days**: Fix development and testing
- **Public disclosure**: After fix is released and users have had time to update

## Security Best Practices

### For Users

When deploying this infrastructure:

1. **AWS Credentials**
   - Never commit AWS credentials to version control
   - Use AWS IAM roles instead of access keys when possible
   - Rotate access keys regularly (every 90 days)
   - Enable MFA for AWS account

2. **SSH Keys**
   - Use strong SSH keys (RSA 4096-bit or Ed25519)
   - Never commit private keys to version control
   - Restrict SSH access to specific IP addresses
   - Rotate SSH keys regularly

3. **Terraform State**
   - Always use remote state with encryption
   - Enable state locking with DynamoDB
   - Enable S3 bucket versioning for state recovery
   - Restrict access to state bucket using IAM policies

4. **Secrets Management**
   - Use AWS Secrets Manager or Parameter Store
   - Never hardcode secrets in code
   - Use environment variables for sensitive data
   - Encrypt all sensitive data at rest and in transit

5. **Network Security**
   - Use security groups with minimal required rules
   - Enable VPC Flow Logs for audit
   - Use bastion host for production environments
   - Implement network segmentation

6. **Monitoring & Logging**
   - Enable CloudTrail for API audit logs
   - Enable CloudWatch Logs for application logs
   - Set up alerts for suspicious activities
   - Regularly review security logs

### For Contributors

1. **Code Review**
   - All changes must go through pull request review
   - Security-sensitive changes require additional review
   - Run security scanning tools before committing

2. **Dependencies**
   - Keep all dependencies up to date
   - Review dependency security advisories
   - Use dependency scanning tools (Dependabot)

3. **Testing**
   - Include security tests in test suite
   - Test with least privilege IAM policies
   - Validate input sanitization

## Known Security Considerations

### Terraform State

- Contains sensitive information (resource IDs, configurations)
- Solution: Use encrypted S3 backend with restricted access
- Documented in: `docs/terraform-state-structure.md`

### SSH Access

- EC2 instances accept SSH connections
- Solution: Use bastion host, restrict IPs, rotate keys
- Documented in: `README.md` security section

### AWS Credentials

- Required for Terraform and AWS CLI operations
- Solution: Use IAM roles, MFA, credential rotation
- Documented in: `SETUP.md` prerequisites

## Security Updates

We will announce security updates through:

- GitHub Security Advisories
- Release notes in CHANGELOG.md
- Repository notifications

## Compliance

This project follows security best practices from:

- [AWS Well-Architected Framework - Security Pillar](https://aws.amazon.com/architecture/well-architected/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Questions?

If you have questions about security but don't have a vulnerability to report:

- Check [docs/BEST_PRACTICES.md](docs/BEST_PRACTICES.md)
- Review [docs/FAQ.md](docs/FAQ.md)
- Open a [Discussion](../../discussions)

## Acknowledgments

We would like to thank the following individuals for responsibly disclosing security issues:

- (List will be updated as vulnerabilities are reported and fixed)

---

**Last Updated**: 2025-11-15  
**Version**: 1.0.0
