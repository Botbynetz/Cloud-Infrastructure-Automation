# Complete Deployment Guide - Cloud Infrastructure Project

> Step-by-step guide untuk deploy infrastructure ke AWS secara real

## 📋 Prerequisites Checklist

Sebelum mulai, pastikan Anda sudah memiliki:

- [ ] AWS Account (dengan billing enabled)
- [ ] AWS CLI ter install dan dikonfigurasi
- [ ] Terraform >= 1.6.0 ter install
- [ ] Ansible >= 2.15 ter install
- [ ] SSH key pair (private & public key)
- [ ] Git ter install
- [ ] Budget AWS: ~$10-50/bulan (tergantung environment)

## 🚀 Step-by-Step Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/cloud-infra.git
cd cloud-infra
```

### Step 2: Setup AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Masukkan:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: ap-southeast-1
# Default output format: json

# Verifikasi
aws sts get-caller-identity
```

Output yang diharapkan:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Step 3: Generate SSH Key Pair

```bash
# Generate new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cloud-infra-key -C "cloud-infra@example.com"

# Set permissions
chmod 600 ~/.ssh/cloud-infra-key
chmod 644 ~/.ssh/cloud-infra-key.pub

# View public key
cat ~/.ssh/cloud-infra-key.pub
```

Copy output public key untuk digunakan di step berikutnya.

### Step 4: Create S3 Backend Infrastructure

```bash
# Linux/macOS
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh

# Windows PowerShell
.\scripts\setup-backend.ps1
```

Script ini akan membuat:
- S3 bucket: `cloud-infra-terraform-state-ACCOUNT_ID`
- DynamoDB table: `cloud-infra-lock`

### Step 5: Configure Environment Variables

Edit file `terraform/env/dev.tfvars`:

```bash
cd terraform
cp env/dev.tfvars env/dev.tfvars.backup
vim env/dev.tfvars
```

Update dengan nilai Anda:
```hcl
# Required
environment    = "dev"
project_name   = "cloud-infra"
aws_region     = "ap-southeast-1"

# Network
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
availability_zone    = "ap-southeast-1a"

# Instance
instance_type  = "t2.micro"
ami_id         = "ami-0dc2d3e4c0f9ebd18"  # Ubuntu 22.04 LTS

# SSH - PASTE YOUR PUBLIC KEY HERE
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB..."

# Optional Features
enable_monitoring = false  # Set true untuk CloudWatch
enable_bastion    = false  # Set true untuk bastion host
```

### Step 6: Initialize Terraform

```bash
# Masih di folder terraform/
terraform init -backend-config="backend/dev.conf"
```

Output yang diharapkan:
```
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0

Terraform has been successfully initialized!
```

### Step 7: Validate Terraform Configuration

```bash
# Format check
terraform fmt -check -recursive

# Validate syntax
terraform validate
```

Output yang diharapkan:
```
Success! The configuration is valid.
```

### Step 8: Review Terraform Plan

```bash
terraform plan -var-file="env/dev.tfvars" -out=tfplan
```

Review output dengan hati-hati. Pastikan:
- ✅ Resources yang akan dibuat sesuai (VPC, Subnet, EC2, dll)
- ✅ Tidak ada error atau warning
- ✅ Estimated cost masuk budget

### Step 9: Apply Terraform (CREATE INFRASTRUCTURE!)

```bash
terraform apply tfplan
```

Atau dengan confirmation prompt:
```bash
terraform apply -var-file="env/dev.tfvars"
```

Type `yes` untuk konfirmasi.

⏱️ **Waktu estimasi**: 2-3 menit

Output akhir:
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

ec2_instance_id = "i-0a1b2c3d4e5f67890"
ec2_private_ip = "10.0.1.100"
ec2_public_ip = "13.213.45.67"
security_group_id = "sg-0a1b2c3d4e5f67890"
subnet_id = "subnet-0a1b2c3d4e5f67890"
vpc_id = "vpc-0a1b2c3d4e5f67890"
website_url = "http://13.213.45.67"
```

**IMPORTANT**: Save nilai `ec2_public_ip` untuk step berikutnya!

### Step 10: Wait for EC2 to Be Ready

```bash
# Check instance status
aws ec2 describe-instance-status \
  --instance-ids $(terraform output -raw ec2_instance_id) \
  --region ap-southeast-1

# Wait until both checks are "ok"
# atau tunggu 2-3 menit
```

### Step 11: Update Ansible Inventory (OTOMATIS)

```bash
cd ../ansible

# Linux/macOS
chmod +x update_inventory.sh
./update_inventory.sh dev

# Windows PowerShell
.\update_inventory.ps1 -Environments @("dev")
```

Output:
```
✓ Inventory updated successfully for dev
  Public IP: 13.213.45.67
```

### Step 12: Test SSH Connection

```bash
# Gunakan IP dari terraform output
ssh -i ~/.ssh/cloud-infra-key ubuntu@13.213.45.67

# Jika berhasil, Anda akan masuk ke EC2 instance
# Exit dengan: exit
```

**Jika gagal connect**:
- Tunggu 1-2 menit lagi (instance masih booting)
- Check security group: pastikan IP Anda allowed
- Check SSH key: pastikan menggunakan private key yang benar

### Step 13: Run Ansible Playbook

```bash
# Masih di folder ansible/
ansible-playbook -i inventory/dev/hosts playbook.yml
```

⏱️ **Waktu estimasi**: 3-5 menit

Output akhir:
```
PLAY RECAP *********************************************************************
dev-web-server             : ok=11   changed=9    unreachable=0    failed=0
```

### Step 14: VERIFY DEPLOYMENT! 🎉

#### Test Website
```bash
# Get website URL
cd ../terraform
terraform output website_url

# Open in browser atau curl
curl http://13.213.45.67
```

Anda akan melihat halaman web dengan gradient biru (dev environment).

#### Test Health Endpoint
```bash
curl http://13.213.45.67/health
```

Output: `healthy`

#### Access di Browser
1. Buka browser
2. Masuk ke `http://YOUR_EC2_PUBLIC_IP`
3. Anda akan melihat halaman:
   ```
   🚀 Cloud Infrastructure
   Environment: dev
   Region: ap-southeast-1
   Project: cloud-infra
   Deployed with Terraform + Ansible
   ```

## 🎯 Post-Deployment Tasks

### Enable CloudWatch Monitoring (Optional)

1. Edit `terraform/env/dev.tfvars`:
   ```hcl
   enable_monitoring = true
   ```

2. Apply changes:
   ```bash
   cd terraform
   terraform apply -var-file="env/dev.tfvars"
   ```

3. View logs:
   ```bash
   aws logs tail /aws/ec2/cloud-infra-syslog --follow
   ```

### Enable Bastion Host (Optional)

1. Edit `terraform/env/dev.tfvars`:
   ```hcl
   enable_bastion = true
   ```

2. Apply changes:
   ```bash
   terraform apply -var-file="env/dev.tfvars"
   ```

3. Get bastion IP:
   ```bash
   terraform output bastion_public_ip
   ```

4. SSH via bastion:
   ```bash
   # SSH to bastion
   ssh -i ~/.ssh/cloud-infra-key ubuntu@BASTION_IP
   
   # From bastion, SSH to web server
   ssh ubuntu@10.0.1.100
   ```

## 🔄 Deploy to Other Environments

### Staging Environment

```bash
# 1. Edit staging config
vim terraform/env/staging.tfvars

# 2. Initialize with staging backend
cd terraform
terraform init -backend-config="backend/staging.conf" -reconfigure

# 3. Apply
terraform apply -var-file="env/staging.tfvars"

# 4. Update inventory
cd ../ansible
./update_inventory.sh staging

# 5. Run playbook
ansible-playbook -i inventory/staging/hosts playbook.yml
```

### Production Environment

```bash
# 1. Edit production config
vim terraform/env/prod.tfvars

# Recommended production settings:
enable_monitoring = true
enable_bastion = true
instance_type = "t3.medium"

# 2. Initialize with prod backend
cd terraform
terraform init -backend-config="backend/prod.conf" -reconfigure

# 3. Apply
terraform apply -var-file="env/prod.tfvars"

# 4. Update inventory
cd ../ansible
./update_inventory.sh prod

# 5. Run playbook
ansible-playbook -i inventory/prod/hosts playbook.yml
```

## 🧹 Cleanup / Destroy Infrastructure

### Destroy Single Environment

```bash
cd terraform
terraform destroy -var-file="env/dev.tfvars"
```

Type `yes` untuk konfirmasi.

### Destroy ALL Environments

```bash
# Linux/macOS
./scripts/destroy-all.sh

# Windows PowerShell
.\scripts\destroy-all.ps1
```

Akan ada **double confirmation** untuk safety.

## 💰 Cost Estimation

### Development Environment
- **EC2 t2.micro**: ~$7/month
- **EBS 20GB**: ~$2/month
- **Data Transfer**: ~$1/month (light usage)
- **Total**: ~$10/month

### Staging Environment
- **EC2 t3.micro**: ~$8/month
- **EBS 20GB**: ~$2/month
- **CloudWatch**: ~$3/month (if enabled)
- **Total**: ~$13/month

### Production Environment
- **EC2 t3.medium**: ~$30/month
- **EBS 20GB**: ~$2/month
- **Bastion t2.micro**: ~$7/month
- **CloudWatch**: ~$5/month
- **Data Transfer**: ~$5/month
- **Total**: ~$49/month

**IMPORTANT**: 
- Costs vary by usage
- Hentikan instance saat tidak digunakan untuk save cost
- Delete unused resources
- Monitor AWS Cost Explorer

## 🛟 Troubleshooting

### Problem: "Error locking state"
**Solution**:
```bash
terraform force-unlock LOCK_ID
```

### Problem: "Error: creating EC2 Instance: VcpuLimitExceeded"
**Solution**: Request vCPU limit increase di AWS Service Quotas

### Problem: Ansible "Host unreachable"
**Solution**: 
1. Wait 2-3 minutes for EC2 to fully boot
2. Check security group allows SSH from your IP
3. Verify SSH key path is correct

### Problem: Website tidak bisa diakses
**Solution**:
1. Check EC2 instance running: `aws ec2 describe-instances`
2. Check nginx status: `ssh ubuntu@IP "sudo systemctl status nginx"`
3. Check security group allows HTTP (port 80)

## 📞 Need Help?

1. Check logs:
   ```bash
   # Terraform
   TF_LOG=DEBUG terraform apply
   
   # Ansible
   ansible-playbook -vvv -i inventory/dev/hosts playbook.yml
   ```

2. View CloudWatch logs (if enabled)
3. SSH to instance and check:
   ```bash
   sudo tail -f /var/log/syslog
   sudo tail -f /var/log/nginx/error.log
   ```

## ✅ Deployment Checklist

- [ ] AWS credentials configured
- [ ] SSH key pair generated
- [ ] S3 backend created
- [ ] Terraform variables configured (tfvars)
- [ ] Terraform init successful
- [ ] Terraform plan reviewed
- [ ] Terraform apply successful (infrastructure created)
- [ ] EC2 instance status checks passed
- [ ] Ansible inventory updated
- [ ] SSH connection tested
- [ ] Ansible playbook executed successfully
- [ ] Website accessible in browser
- [ ] Health endpoint responding
- [ ] (Optional) CloudWatch monitoring enabled
- [ ] (Optional) Bastion host configured
- [ ] Costs monitored in AWS Cost Explorer

---

**Congratulations! 🎉** 

Infrastructure Anda sudah berjalan di AWS!

Jangan lupa:
- Monitor costs di AWS Console
- Backup terraform state regularly
- Update security groups as needed
- Keep software updated
