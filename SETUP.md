# 🚀 Quick Setup Guide

This guide will help you set up and deploy the cloud infrastructure project in **10 minutes**.

## ✅ Prerequisites Checklist

Before starting, make sure you have:

- [ ] **AWS Account** (Free Tier eligible)
- [ ] **Terraform** >= 1.6.0 installed
- [ ] **Ansible** >= 2.15 installed
- [ ] **AWS CLI** >= 2.0 installed
- [ ] **Git** installed
- [ ] **SSH client** installed

## 📦 Step-by-Step Setup

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/cloud-infra.git
cd cloud-infra
```

### 2. Configure AWS Credentials

```bash
# Run AWS configure
aws configure

# Enter your credentials:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region: ap-southeast-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

**Don't have AWS credentials?** Follow [this guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) to create them.

### 3. Generate SSH Key Pair

```bash
# Linux/macOS
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud-infra-key
chmod 600 ~/.ssh/cloud-infra-key

# View public key (copy this!)
cat ~/.ssh/cloud-infra-key.pub
```

**Windows PowerShell:**
```powershell
# Create .ssh directory if not exists
New-Item -ItemType Directory -Force -Path "$HOME\.ssh"

# Generate key
ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\cloud-infra-key" -N '""'

# View public key
Get-Content "$HOME\.ssh\cloud-infra-key.pub"
```

### 4. Configure Environment Variables

Edit `terraform/env/dev.tfvars`:

```bash
# Open file in editor
vim terraform/env/dev.tfvars
# OR
code terraform/env/dev.tfvars
```

**Update line 16** with your SSH public key:
```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... PASTE_YOUR_KEY_HERE"
```

### 5. Setup Terraform Backend

```bash
# Linux/macOS
cd scripts
chmod +x setup-backend.sh
./setup-backend.sh

# Windows PowerShell
cd scripts
.\setup-backend.ps1
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### 6. Initialize Terraform

```bash
cd ../terraform
terraform init -backend-config="backend/dev.conf"
```

### 7. Review Infrastructure Plan

```bash
terraform plan -var-file="env/dev.tfvars"
```

You should see **8 resources** to be created.

### 8. Deploy Infrastructure

```bash
terraform apply -var-file="env/dev.tfvars"
```

Type `yes` when prompted.

⏱️ **Wait 2-3 minutes** for deployment to complete.

### 9. Configure with Ansible

```bash
cd ../ansible

# Update inventory automatically
# Linux/macOS
chmod +x update_inventory.sh
./update_inventory.sh dev

# Windows PowerShell
.\update_inventory.ps1 dev

# Run Ansible playbook
ansible-playbook -i inventory/dev/hosts playbook.yml
```

⏱️ **Wait 3-5 minutes** for configuration.

### 10. Verify Deployment! 🎉

```bash
cd ../terraform

# Get public IP
terraform output ec2_public_ip

# Test with curl
curl http://$(terraform output -raw ec2_public_ip)

# Test health endpoint
curl http://$(terraform output -raw ec2_public_ip)/health
```

**Open in browser**: `http://YOUR_EC2_PUBLIC_IP`

You should see a beautiful gradient website! 🌈

## 🧹 Cleanup (When Done)

```bash
cd terraform
terraform destroy -var-file="env/dev.tfvars"
```

Type `yes` to confirm.

## ❓ Troubleshooting

### "AWS credentials not configured"
```bash
aws configure
# Enter your Access Key ID and Secret Access Key
```

### "Permission denied (publickey)"
```bash
# Check SSH key exists
ls -la ~/.ssh/cloud-infra-key*

# Verify public key is in dev.tfvars
cat terraform/env/dev.tfvars | grep ssh_public_key
```

### "Backend initialization failed"
```bash
# Re-run backend setup
cd scripts
./setup-backend.sh  # or setup-backend.ps1 on Windows
```

### "Instance failed to start"
```bash
# Check AWS quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A
```

### "Ansible unreachable"
```bash
# Wait 2-3 minutes for EC2 to fully boot
# Check instance status
aws ec2 describe-instance-status \
  --instance-ids $(terraform output -raw ec2_instance_id)

# Test SSH manually
ssh -i ~/.ssh/cloud-infra-key ubuntu@$(terraform output -raw ec2_public_ip)
```

## 📚 Next Steps

- Read [DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) for detailed instructions
- Check [README.md](README.md) for complete documentation
- Explore [Architecture](docs/architecture.md)
- Run [Tests](tests/README.md)

## 💰 Cost Warning

This deployment creates **real AWS resources** with costs:
- **Development**: ~$10/month
- Can be **FREE** with AWS Free Tier (first 12 months)
- **Always destroy** resources when not in use!

Set up billing alarm:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name billing-alarm \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## 🆘 Need Help?

- 📖 [Full Documentation](README.md)
- 🐛 [Report Issues](https://github.com/YOUR_USERNAME/cloud-infra/issues)
- 💬 [Discussions](https://github.com/YOUR_USERNAME/cloud-infra/discussions)

---

**Happy Deploying!** 🚀☁️
