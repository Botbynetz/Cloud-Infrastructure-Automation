#!/bin/bash
set -e

# Log output to file and console
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "=========================================="
echo "Starting cloud-infra setup"
echo "Environment: ${environment}"
echo "Project: ${project_name}"
echo "Date: $(date)"
echo "=========================================="

# Update system
echo "Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install and configure CloudWatch agent
echo "Installing CloudWatch agent..."
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || true
rm -f /tmp/amazon-cloudwatch-agent.deb

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/${environment}/syslog",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/${environment}/nginx-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/${environment}/nginx-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CloudInfra/${environment}",
    "metrics_collected": {
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUsedPercent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUsedPercent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPUIdlePercent",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPUIOWaitPercent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      }
    }
  }
}
CWCONFIG

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Stop Nginx to configure it
systemctl stop nginx

# Create website directory
mkdir -p /var/www/cloud-infra

# Create default homepage
cat > /var/www/cloud-infra/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Infrastructure - ${environment}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 50px;
            max-width: 900px;
            width: 100%;
        }
        h1 {
            color: #667eea;
            font-size: 3em;
            margin-bottom: 10px;
            text-align: center;
        }
        .environment-badge {
            background: #764ba2;
            color: white;
            padding: 8px 20px;
            border-radius: 25px;
            font-weight: 600;
            display: inline-block;
            margin-bottom: 30px;
            text-transform: uppercase;
        }
        .center {
            text-align: center;
        }
        .subtitle {
            color: #666;
            font-size: 1.3em;
            margin-bottom: 30px;
            text-align: center;
        }
        .info-box {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 30px;
            margin: 20px 0;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 15px 0;
            border-bottom: 1px solid #dee2e6;
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .label {
            font-weight: bold;
            color: #495057;
        }
        .value {
            color: #667eea;
            font-weight: 600;
        }
        .tech-stack {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin-top: 30px;
            flex-wrap: wrap;
        }
        .tech-badge {
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border-radius: 25px;
            font-weight: 600;
            font-size: 0.9em;
        }
        .status {
            color: #28a745;
            font-size: 1.2em;
            margin-top: 20px;
            font-weight: bold;
        }
        .monitoring {
            background: #e7f3ff;
            border-left: 4px solid #0066cc;
            padding: 15px;
            margin-top: 20px;
            border-radius: 5px;
        }
        .monitoring h3 {
            color: #0066cc;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Cloud Infrastructure</h1>
        <div class="center">
            <span class="environment-badge">${environment} Environment</span>
        </div>
        <p class="subtitle">Automated Deployment with Terraform & Ansible</p>
        
        <div class="info-box">
            <div class="info-item">
                <span class="label">Project:</span>
                <span class="value">${project_name}</span>
            </div>
            <div class="info-item">
                <span class="label">Environment:</span>
                <span class="value">${environment}</span>
            </div>
            <div class="info-item">
                <span class="label">Server:</span>
                <span class="value" id="hostname">Loading...</span>
            </div>
            <div class="info-item">
                <span class="label">Deployment Date:</span>
                <span class="value" id="date">Loading...</span>
            </div>
            <div class="info-item">
                <span class="label">Nginx Status:</span>
                <span class="value">✅ Running</span>
            </div>
        </div>

        <div class="monitoring">
            <h3>📊 Monitoring Enabled</h3>
            <p>CloudWatch agent is collecting metrics and logs from this instance.</p>
            <ul style="margin-top: 10px; margin-left: 20px;">
                <li>CPU, Memory, and Disk metrics</li>
                <li>Nginx access and error logs</li>
                <li>System logs</li>
            </ul>
        </div>

        <div class="tech-stack">
            <span class="tech-badge">Terraform</span>
            <span class="tech-badge">Ansible</span>
            <span class="tech-badge">AWS EC2</span>
            <span class="tech-badge">Nginx</span>
            <span class="tech-badge">CloudWatch</span>
            <span class="tech-badge">GitHub Actions</span>
        </div>

        <p class="status center">✅ Successfully Deployed via User Data!</p>
    </div>

    <script>
        // Set hostname and date
        document.getElementById('hostname').textContent = window.location.hostname;
        document.getElementById('date').textContent = new Date().toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    </script>
</body>
</html>
HTML

# Configure Nginx
cat > /etc/nginx/sites-available/cloud-infra <<'NGINXCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/cloud-infra;
    index index.html;
    
    server_name _;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINXCONF

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Enable our site
ln -sf /etc/nginx/sites-available/cloud-infra /etc/nginx/sites-enabled/

# Set permissions
chown -R www-data:www-data /var/www/cloud-infra
chmod -R 755 /var/www/cloud-infra

# Test Nginx configuration
nginx -t

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Install Docker (optional, for future use)
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
rm -f get-docker.sh

# Clean up
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean

# Create completion marker
touch /var/log/user-data-complete

echo "=========================================="
echo "Setup completed successfully!"
echo "Environment: ${environment}"
echo "Project: ${project_name}"
echo "Nginx status: $(systemctl is-active nginx)"
echo "CloudWatch agent: $(systemctl is-active amazon-cloudwatch-agent)"
echo "=========================================="
