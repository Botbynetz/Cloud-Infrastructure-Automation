# =============================================================================
# Documentation Generation Script - STEP 8
# =============================================================================
# Automates documentation generation for Cloud Infrastructure Automation
# Generates module docs, diagrams, and API references
# Usage: .\scripts\generate-docs.ps1 [-Type <all|modules|diagrams|api>]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'modules', 'diagrams', 'api')]
    [string]$Type = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$Commit,
    
    [Parameter(Mandatory=$false)]
    [switch]$Push
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TerraformDir = Join-Path $ProjectRoot "terraform"
$ModulesDir = Join-Path $TerraformDir "modules"
$DocsDir = Join-Path $ProjectRoot "docs"
$DiagramsDir = Join-Path $DocsDir "diagrams"

# Colors
$ColorReset = "`e[0m"
$ColorGreen = "`e[32m"
$ColorYellow = "`e[33m"
$ColorBlue = "`e[34m"
$ColorRed = "`e[31m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $ColorReset)
    Write-Host "${Color}${Message}${ColorReset}"
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# =============================================================================
# Module Documentation Generation
# =============================================================================
function Generate-ModuleDocs {
    Write-ColorOutput "🚀 Generating Terraform module documentation..." $ColorBlue
    
    if (-not (Test-CommandExists "terraform-docs")) {
        Write-ColorOutput "⚠️  terraform-docs not found. Installing..." $ColorYellow
        
        # Download and install terraform-docs
        $Version = "v0.16.0"
        $Url = "https://github.com/terraform-docs/terraform-docs/releases/download/$Version/terraform-docs-$Version-windows-amd64.zip"
        $ZipPath = "$env:TEMP\terraform-docs.zip"
        $ExtractPath = "$env:TEMP\terraform-docs"
        
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
        
        $TerraformDocsExe = Join-Path $ExtractPath "terraform-docs.exe"
        $DestPath = "C:\Program Files\terraform-docs"
        
        if (-not (Test-Path $DestPath)) {
            New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
        }
        
        Copy-Item $TerraformDocsExe -Destination $DestPath -Force
        $env:Path += ";$DestPath"
        
        Write-ColorOutput "✅ terraform-docs installed" $ColorGreen
    }
    
    # Generate root module docs
    Write-ColorOutput "📝 Generating root module documentation..." $ColorBlue
    Set-Location $ProjectRoot
    terraform-docs markdown table . > README-TERRAFORM.md
    
    # Generate module-specific docs
    $ModuleCount = 0
    Get-ChildItem -Path $ModulesDir -Directory | ForEach-Object {
        $ModulePath = $_.FullName
        $ModuleName = $_.Name
        
        if (Test-Path (Join-Path $ModulePath "main.tf")) {
            Write-ColorOutput "  📦 Generating docs for: $ModuleName" $ColorBlue
            
            Set-Location $ModulePath
            terraform-docs markdown table . > README.md
            
            $ModuleCount++
        }
    }
    
    Write-ColorOutput "✅ Generated documentation for $ModuleCount modules" $ColorGreen
}

# =============================================================================
# Architecture Diagrams Generation
# =============================================================================
function Generate-Diagrams {
    Write-ColorOutput "🎨 Generating architecture diagrams..." $ColorBlue
    
    # Create diagrams directory
    if (-not (Test-Path $DiagramsDir)) {
        New-Item -ItemType Directory -Path $DiagramsDir -Force | Out-Null
    }
    
    # Check for Graphviz
    if (-not (Test-CommandExists "dot")) {
        Write-ColorOutput "⚠️  Graphviz not found. Please install from: https://graphviz.org/download/" $ColorYellow
        Write-ColorOutput "   Skipping diagram generation..." $ColorYellow
        return
    }
    
    # Generate infrastructure diagram
    $InfraDotFile = Join-Path $DiagramsDir "infrastructure.dot"
    @"
digraph infrastructure {
    rankdir=TB;
    node [shape=box, style=rounded, fontname="Arial"];
    edge [fontname="Arial"];
    
    subgraph cluster_users {
        label="Users";
        style=filled;
        color=lightgrey;
        users [label="End Users", shape=ellipse];
    }
    
    subgraph cluster_frontend {
        label="Frontend Layer";
        style=filled;
        color=lightblue;
        cloudfront [label="CloudFront CDN"];
        s3_web [label="S3 Static Website"];
    }
    
    subgraph cluster_application {
        label="Application Layer";
        style=filled;
        color=lightgreen;
        alb [label="Application\nLoad Balancer"];
        asg [label="Auto Scaling\nGroup"];
        ec2_app [label="EC2 Instances"];
    }
    
    subgraph cluster_data {
        label="Data Layer";
        style=filled;
        color=lightyellow;
        rds [label="RDS\nDatabase"];
        elasticache [label="ElastiCache\nRedis"];
        s3_data [label="S3 Data\nStorage"];
    }
    
    subgraph cluster_security {
        label="Security & Compliance";
        style=filled;
        color=lightpink;
        kms [label="KMS\nEncryption"];
        secrets [label="Secrets\nManager"];
        guardduty [label="GuardDuty"];
        config [label="AWS Config"];
    }
    
    subgraph cluster_monitoring {
        label="Observability";
        style=filled;
        color=lightcyan;
        prometheus [label="Prometheus"];
        grafana [label="Grafana"];
        cloudwatch [label="CloudWatch"];
    }
    
    subgraph cluster_cicd {
        label="CI/CD Pipeline";
        style=filled;
        color=lavender;
        github [label="GitHub\nActions"];
        terraform [label="Terraform"];
        opa [label="OPA\nPolicies"];
    }
    
    // Connections
    users -> cloudfront;
    cloudfront -> s3_web;
    cloudfront -> alb;
    alb -> asg;
    asg -> ec2_app;
    ec2_app -> rds;
    ec2_app -> elasticache;
    ec2_app -> s3_data;
    ec2_app -> secrets;
    kms -> rds [style=dashed, label="encrypt"];
    kms -> s3_data [style=dashed, label="encrypt"];
    kms -> secrets [style=dashed, label="encrypt"];
    guardduty -> cloudwatch;
    config -> cloudwatch;
    ec2_app -> cloudwatch [label="logs/metrics"];
    prometheus -> ec2_app [label="scrape"];
    grafana -> prometheus [label="query"];
    github -> terraform [label="deploy"];
    terraform -> opa [label="validate"];
}
"@ | Out-File -FilePath $InfraDotFile -Encoding UTF8
    
    # Generate PNG and SVG
    dot -Tpng $InfraDotFile -o (Join-Path $DiagramsDir "infrastructure.png")
    dot -Tsvg $InfraDotFile -o (Join-Path $DiagramsDir "infrastructure.svg")
    
    Write-ColorOutput "✅ Generated infrastructure diagrams" $ColorGreen
    
    # Generate security diagram
    $SecurityDotFile = Join-Path $DiagramsDir "security.dot"
    @"
digraph security {
    rankdir=LR;
    node [shape=box, style=rounded, fontname="Arial"];
    edge [fontname="Arial"];
    
    internet [label="Internet", shape=ellipse, color=red];
    
    subgraph cluster_perimeter {
        label="Perimeter Security";
        style=filled;
        color=mistyrose;
        waf [label="WAF"];
        shield [label="Shield\nDDoS"];
    }
    
    subgraph cluster_network {
        label="Network Security";
        style=filled;
        color=lightgoldenrodyellow;
        vpc [label="VPC"];
        nacl [label="Network\nACL"];
        sg [label="Security\nGroups"];
    }
    
    subgraph cluster_identity {
        label="Identity & Access";
        style=filled;
        color=lightgreen;
        iam [label="IAM\nRoles"];
        cognito [label="Cognito"];
        sts [label="STS"];
    }
    
    subgraph cluster_data_security {
        label="Data Protection";
        style=filled;
        color=lightblue;
        kms [label="KMS"];
        secrets [label="Secrets\nManager"];
        acm [label="ACM\nCertificates"];
    }
    
    subgraph cluster_monitoring {
        label="Security Monitoring";
        style=filled;
        color=plum;
        guardduty [label="GuardDuty"];
        config [label="Config"];
        cloudtrail [label="CloudTrail"];
        security_hub [label="Security\nHub"];
    }
    
    // Connections
    internet -> waf;
    waf -> shield;
    shield -> vpc;
    vpc -> nacl;
    nacl -> sg;
    sg -> iam;
    iam -> cognito;
    cognito -> sts;
    sts -> kms;
    kms -> secrets;
    secrets -> acm;
    guardduty -> security_hub;
    config -> security_hub;
    cloudtrail -> security_hub;
}
"@ | Out-File -FilePath $SecurityDotFile -Encoding UTF8
    
    dot -Tpng $SecurityDotFile -o (Join-Path $DiagramsDir "security.png")
    dot -Tsvg $SecurityDotFile -o (Join-Path $DiagramsDir "security.svg")
    
    Write-ColorOutput "✅ Generated security diagrams" $ColorGreen
}

# =============================================================================
# API Documentation Generation
# =============================================================================
function Generate-ApiDocs {
    Write-ColorOutput "📋 Generating API documentation..." $ColorBlue
    
    # Generate outputs reference
    $OutputsDoc = Join-Path $DocsDir "TERRAFORM-OUTPUTS.md"
    @"
# Terraform Outputs Reference

Complete reference of all Terraform outputs.

## Core Infrastructure

### VPC Outputs
- **vpc_id**: VPC identifier
- **private_subnet_ids**: List of private subnet IDs
- **public_subnet_ids**: List of public subnet IDs

### EC2 Outputs
- **instance_ids**: EC2 instance identifiers
- **instance_private_ips**: Private IP addresses
- **autoscaling_group_name**: Auto Scaling group name

## Security

### KMS Outputs
- **kms_key_id**: KMS key identifier (sensitive)
- **kms_key_arn**: KMS key ARN

### Secrets Manager
- **secret_arns**: Map of secret ARNs

## Monitoring

### Observability
- **prometheus_endpoint**: Prometheus server URL
- **grafana_endpoint**: Grafana dashboard URL
- **alertmanager_endpoint**: Alertmanager URL

---
*Generated by STEP 8: Documentation Automation*
"@ | Out-File -FilePath $OutputsDoc -Encoding UTF8
    
    Write-ColorOutput "✅ Generated API documentation" $ColorGreen
}

# =============================================================================
# Main Execution
# =============================================================================
Write-ColorOutput "`n========================================" $ColorBlue
Write-ColorOutput "Documentation Generator - STEP 8" $ColorBlue
Write-ColorOutput "========================================`n" $ColorBlue

switch ($Type) {
    'all' {
        Generate-ModuleDocs
        Generate-Diagrams
        Generate-ApiDocs
    }
    'modules' {
        Generate-ModuleDocs
    }
    'diagrams' {
        Generate-Diagrams
    }
    'api' {
        Generate-ApiDocs
    }
}

# Commit and push if requested
if ($Commit) {
    Write-ColorOutput "`n📦 Committing documentation changes..." $ColorBlue
    
    Set-Location $ProjectRoot
    git add docs/ terraform/modules/*/README.md README-TERRAFORM.md
    
    $status = git status --porcelain
    if ($status) {
        git commit -m "docs: auto-generate documentation [STEP 8]"
        Write-ColorOutput "✅ Documentation committed" $ColorGreen
        
        if ($Push) {
            git push
            Write-ColorOutput "✅ Documentation pushed to remote" $ColorGreen
        }
    } else {
        Write-ColorOutput "📝 No documentation changes to commit" $ColorYellow
    }
}

Write-ColorOutput "`n========================================" $ColorGreen
Write-ColorOutput "✅ Documentation generation complete!" $ColorGreen
Write-ColorOutput "========================================`n" $ColorGreen

# Summary
Write-ColorOutput "📊 Summary:" $ColorBlue
Write-ColorOutput "  - Module documentation: terraform/modules/*/README.md" $ColorReset
Write-ColorOutput "  - Architecture diagrams: docs/diagrams/" $ColorReset
Write-ColorOutput "  - API documentation: docs/TERRAFORM-*.md" $ColorReset
Write-ColorOutput "  - Documentation index: docs/DOCUMENTATION-INDEX.md`n" $ColorReset
