# Cloud Infrastructure Architecture

## Architecture Diagram

```mermaid
graph TB
    subgraph "AWS Cloud - ap-southeast-1"
        subgraph "VPC - 10.0.0.0/16"
            subgraph "Public Subnet - 10.0.1.0/24"
                IGW[Internet Gateway]
                
                subgraph "Compute Resources"
                    EC2[EC2 Instance<br/>Ubuntu 22.04<br/>Nginx + Docker]
                    Bastion[Bastion Host<br/>Optional<br/>t2.micro]
                end
                
                subgraph "Security"
                    SG[Security Group<br/>SSH: 22<br/>HTTP: 80<br/>HTTPS: 443]
                end
            end
            
            RT[Route Table<br/>0.0.0.0/0 → IGW]
        end
        
        subgraph "Monitoring"
            CW[CloudWatch<br/>Logs & Alarms]
            CWLogs[Log Groups<br/>- syslog<br/>- nginx-access<br/>- nginx-error]
            CWAlarms[Alarms<br/>- CPU > 80%<br/>- Memory > 80%<br/>- Disk > 85%<br/>- Health Check]
        end
        
        subgraph "State Management"
            S3[S3 Bucket<br/>Terraform State<br/>Versioned + Encrypted]
            DDB[DynamoDB<br/>State Locking<br/>LockID]
        end
    end
    
    subgraph "Configuration Management"
        Ansible[Ansible<br/>Webserver Role<br/>Templates & Handlers]
    end
    
    subgraph "CI/CD"
        GHA[GitHub Actions<br/>- Terraform Plan/Apply<br/>- Ansible Lint<br/>- Ansible Deploy]
    end
    
    subgraph "Testing"
        Terratest[Terratest<br/>Go Tests<br/>Infrastructure Validation]
    end
    
    Users[Users] -->|HTTPS/HTTP| IGW
    IGW --> RT
    RT --> EC2
    SG -.->|Protects| EC2
    SG -.->|Protects| Bastion
    
    EC2 -->|Push Logs| CW
    CW --> CWLogs
    CW --> CWAlarms
    
    GHA -->|Provision| EC2
    GHA -->|Read/Write| S3
    GHA -->|Lock State| DDB
    
    Ansible -->|Configure| EC2
    GHA -->|Trigger| Ansible
    
    Terratest -->|Validate| EC2
    Terratest -->|Test| S3
    
    Admin[Admin] -->|SSH| Bastion
    Bastion -.->|SSH Jump| EC2
    
    style EC2 fill:#3498db,stroke:#2980b9,color:#fff
    style Bastion fill:#95a5a6,stroke:#7f8c8d,color:#fff
    style S3 fill:#f39c12,stroke:#e67e22,color:#fff
    style DDB fill:#f39c12,stroke:#e67e22,color:#fff
    style CW fill:#e74c3c,stroke:#c0392b,color:#fff
    style GHA fill:#27ae60,stroke:#229954,color:#fff
    style Ansible fill:#9b59b6,stroke:#8e44ad,color:#fff
    style Terratest fill:#16a085,stroke:#138d75,color:#fff
```

## Architecture Components

### 1. Networking Layer
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 for internet-accessible resources
- **Internet Gateway**: Provides internet connectivity
- **Route Table**: Routes traffic to internet via IGW

### 2. Compute Layer
- **EC2 Instances**: Application servers with auto-configured web stack
  - Ubuntu 22.04 LTS
  - Nginx web server
  - Docker runtime
  - CloudWatch agent
- **Bastion Host** (Optional): Secure SSH access point
  - Minimal t2.micro instance
  - Jump host for private instances

### 3. Security Layer
- **Security Groups**: Stateful firewall rules
  - Port 22 (SSH): Administration access
  - Port 80 (HTTP): Web traffic
  - Port 443 (HTTPS): Secure web traffic
- **Encrypted Storage**: EBS volumes with encryption enabled
- **IAM Roles**: CloudWatch agent permissions

### 4. Monitoring & Observability
- **CloudWatch Logs**:
  - System logs (syslog)
  - Nginx access logs
  - Nginx error logs
- **CloudWatch Alarms**:
  - High CPU utilization (> 80%)
  - High memory usage (> 80%)
  - Disk space critical (> 85%)
  - Instance health check failures

### 5. State Management
- **S3 Backend**: Centralized Terraform state storage
  - Versioning enabled
  - Server-side encryption
  - Per-environment state files
- **DynamoDB**: State locking mechanism
  - Prevents concurrent modifications
  - Pay-per-request billing

### 6. Configuration Management
- **Ansible**: Automated configuration
  - Role-based structure
  - Environment-specific variables
  - Jinja2 templates
  - Service handlers

### 7. CI/CD Pipeline
- **GitHub Actions**:
  - Automated validation
  - Terraform planning and deployment
  - Ansible linting and execution
  - Caching for performance
  - PR plan comments

### 8. Testing Framework
- **Terratest**: Infrastructure validation
  - Go-based testing
  - VPC validation
  - EC2 instance checks
  - Security group verification
  - Web server health checks

## Data Flow

1. **Deployment Flow**:
   - Developer pushes code → GitHub Actions triggered
   - Terraform validates configuration
   - Terraform plans infrastructure changes
   - Manual approval (production)
   - Terraform applies changes
   - Ansible configures instances
   - Monitoring activated

2. **Traffic Flow**:
   - User request → Internet Gateway
   - Route table forwards to EC2
   - Security group validates
   - Nginx handles request
   - Response returned to user

3. **Monitoring Flow**:
   - EC2 generates logs
   - CloudWatch agent ships logs
   - Alarms evaluate metrics
   - Notifications on threshold breach

4. **Admin Access Flow**:
   - Admin connects to Bastion
   - SSH jump to target EC2
   - Secure administration

## Environment Strategy

| Environment | Instance Type | Monitoring | Bastion | Purpose |
|-------------|---------------|------------|---------|---------|
| Dev | t2.micro | Optional | No | Development testing |
| Staging | t3.micro | Enabled | Optional | Pre-production validation |
| Production | t3.medium | Enabled | Enabled | Live workloads |

## High Availability Considerations

Current architecture is single-AZ. For production HA:
- Deploy across multiple Availability Zones
- Implement Auto Scaling Groups
- Add Application Load Balancer
- Use RDS Multi-AZ for databases
- Implement backup and disaster recovery

## Cost Optimization

- Right-sizing instances per environment
- S3 lifecycle policies for old state files
- CloudWatch log retention policies
- Pay-per-request DynamoDB billing
- Scheduled stop/start for dev environments

## Security Best Practices

✅ Implemented:
- Encrypted EBS volumes
- Security groups with minimal ports
- IAM roles instead of access keys
- State file encryption
- Optional bastion for SSH access

🔄 Recommended additions:
- VPC Flow Logs
- AWS Systems Manager Session Manager
- Secrets Manager for sensitive data
- WAF for web application firewall
- GuardDuty for threat detection
