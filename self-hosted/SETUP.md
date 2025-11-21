# Self-Hosted Cloud Platform Setup Guide

## 🚀 Transform Your Server into a Cloud Provider

This guide will help you run **UnivAI Cloud** on your own infrastructure, becoming your own AWS/Cloudflare competitor!

---

## 📋 Requirements

### Hardware (Minimum)
- **CPU:** 4 cores (8+ recommended)
- **RAM:** 8GB (16GB+ recommended)
- **Storage:** 100GB SSD (500GB+ recommended)
- **Network:** 100Mbps+ (1Gbps recommended)
- **Static IP:** Required for public access

### Software
- **OS:** Ubuntu 22.04 LTS or Debian 12
- **Docker:** 24.0+
- **Docker Compose:** 2.20+
- **Domain:** Optional but recommended (univai.cloud)

---

## 🛠️ Installation Steps

### Step 1: Prepare Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### Step 2: Clone Project

```bash
cd /opt
git clone https://github.com/Botbynetz/Cloud-Infrastructure-Automation.git
cd Cloud-Infrastructure-Automation/self-hosted
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Configure these variables:**
```env
# Domain Configuration
DOMAIN=univai.cloud
EMAIL=admin@univai.cloud

# Database
POSTGRES_PASSWORD=change-this-strong-password
REDIS_PASSWORD=change-this-redis-password

# API Keys
JWT_SECRET=generate-strong-random-secret-key
STRIPE_SECRET_KEY=sk_live_xxx  # Your Stripe key
STRIPE_WEBHOOK_SECRET=whsec_xxx

# MinIO (S3 Storage)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=change-this-minio-password

# Monitoring
GRAFANA_ADMIN_PASSWORD=change-this-grafana-password
```

### Step 4: Setup SSL Certificate (Production)

**Option A: Cloudflare Tunnel (Recommended for Home)**
```bash
# Install Cloudflare Tunnel
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create univai-cloud

# Configure tunnel
cat > ~/.cloudflared/config.yml <<EOF
tunnel: univai-cloud
credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: univai.cloud
    service: http://localhost:80
  - hostname: api.univai.cloud
    service: http://localhost:3000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run univai-cloud
```

**Option B: Let's Encrypt (VPS with Public IP)**
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d univai.cloud -d www.univai.cloud -d api.univai.cloud
```

### Step 5: Launch Cloud Platform

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Services will be available at:**
- **Frontend:** http://localhost:80
- **API:** http://localhost:3000
- **MinIO Console:** http://localhost:9001
- **Portainer:** http://localhost:9443
- **Grafana:** http://localhost:3001
- **Prometheus:** http://localhost:9090

---

## 🔐 Security Hardening

### Firewall Setup
```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### Fail2Ban (Brute Force Protection)
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

### Regular Backups
```bash
# Create backup script
cat > /opt/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup database
docker exec postgres pg_dump -U postgres univai > $BACKUP_DIR/database.sql

# Backup volumes
docker run --rm -v postgres-data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres.tar.gz /data
docker run --rm -v minio-data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/minio.tar.gz /data

# Upload to S3 (optional)
# aws s3 sync $BACKUP_DIR s3://your-backup-bucket/
EOF

chmod +x /opt/backup.sh

# Schedule daily backup
echo "0 2 * * * /opt/backup.sh" | sudo crontab -
```

---

## 📊 Monitoring & Maintenance

### Check System Health
```bash
# Container status
docker compose ps

# Resource usage
docker stats

# Logs
docker compose logs -f api
docker compose logs -f postgres
```

### Access Grafana Dashboard
1. Open http://your-domain:3001
2. Login: admin / (password from .env)
3. Import dashboards:
   - Node Exporter (ID: 1860)
   - Docker (ID: 893)
   - PostgreSQL (ID: 9628)

### Prometheus Metrics
- Access: http://your-domain:9090
- View metrics: `up`, `container_cpu_usage_seconds_total`, `http_requests_total`

---

## 💰 Cost Breakdown

### Self-Hosted Options:

**Home Server:**
- Hardware: $500-1000 one-time
- Electricity: ~$10/month
- Internet: $50-100/month (business line recommended)
- **Total: ~$60-110/month** after hardware paid off

**VPS (Hetzner/OVH):**
- Dedicated Server: $50-200/month
- No hardware costs
- Guaranteed uptime
- **Total: $50-200/month**

**Compare to SaaS:**
- AWS/Azure similar setup: $500-1000/month
- **Your Savings: 80-95%!**

---

## 🚀 Scaling Your Cloud

### Horizontal Scaling (Multiple Servers)
```yaml
# Add more API nodes
docker service scale api=3

# Add database replica
# (Configure PostgreSQL replication)

# Add storage nodes
# (MinIO distributed mode)
```

### Geographic Distribution
- Deploy in multiple regions (US, EU, Asia)
- Use DNS load balancing (GeoDNS)
- Sync data between regions

---

## 🆘 Troubleshooting

### Service won't start
```bash
# Check logs
docker compose logs <service-name>

# Restart service
docker compose restart <service-name>
```

### Database connection errors
```bash
# Check PostgreSQL logs
docker compose logs postgres

# Connect manually
docker exec -it postgres psql -U postgres -d univai
```

### Out of disk space
```bash
# Clean Docker
docker system prune -a --volumes

# Check disk usage
df -h
du -sh /var/lib/docker
```

---

## 📚 Next Steps

1. ✅ Setup domain DNS (point to your IP)
2. ✅ Configure SSL certificates
3. ✅ Setup Stripe payment webhooks
4. ✅ Integrate AWS SDK for Terraform execution
5. ✅ Configure email service (SMTP)
6. ✅ Setup monitoring alerts (Grafana)
7. ✅ Create backup strategy
8. ✅ Load test your infrastructure

---

## 🎯 You're Now Running Your Own Cloud!

**Congratulations!** You just became a cloud provider like AWS/Cloudflare! 🎉

Your platform can now:
- ✅ Host multiple users
- ✅ Process payments
- ✅ Deploy infrastructure
- ✅ Monitor everything
- ✅ Scale on demand

**Keep building and growing! 🚀**
