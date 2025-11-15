#!/usr/bin/env pwsh
# ==============================================================================
# Multi-Cloud Cost Monitoring Dashboard
# ==============================================================================
# Monitor and alert on cloud spending across AWS, Azure, and GCP

param(
    [Parameter(Mandatory=$false)]
    [int]$BudgetThreshold = 100,
    
    [Parameter(Mandatory=$false)]
    [string]$AlertEmail = "admin@example.com",
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport
)

# ==============================================================================
# Configuration
# ==============================================================================

$Script:Config = @{
    BudgetThreshold = $BudgetThreshold
    AlertEmail = $AlertEmail
    AlertThresholds = @{
        Warning = 0.80  # 80% of budget
        Critical = 0.90 # 90% of budget
        Emergency = 1.00 # 100% of budget
    }
}

# ==============================================================================
# AWS Cost Functions
# ==============================================================================

function Get-AWSCosts {
    Write-Host "📊 Fetching AWS costs..." -ForegroundColor Cyan
    
    try {
        # Check if AWS CLI is available
        $awsVersion = aws --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  AWS CLI not found. Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
            return $null
        }
        
        # Get current month costs
        $startDate = (Get-Date -Day 1).ToString("yyyy-MM-dd")
        $endDate = (Get-Date).ToString("yyyy-MM-dd")
        
        $costJson = aws ce get-cost-and-usage `
            --time-period Start=$startDate,End=$endDate `
            --granularity MONTHLY `
            --metrics "UnblendedCost" `
            --output json 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $costData = $costJson | ConvertFrom-Json
            $totalCost = [Math]::Round([decimal]$costData.ResultsByTime[0].Total.UnblendedCost.Amount, 2)
            
            # Get cost by service
            $serviceJson = aws ce get-cost-and-usage `
                --time-period Start=$startDate,End=$endDate `
                --granularity MONTHLY `
                --metrics "UnblendedCost" `
                --group-by Type=DIMENSION,Key=SERVICE `
                --output json 2>$null
            
            $services = @{}
            if ($LASTEXITCODE -eq 0) {
                $serviceData = $serviceJson | ConvertFrom-Json
                foreach ($group in $serviceData.ResultsByTime[0].Groups) {
                    $serviceName = $group.Keys[0]
                    $serviceCost = [Math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                    if ($serviceCost -gt 0.01) {
                        $services[$serviceName] = $serviceCost
                    }
                }
            }
            
            return @{
                Provider = "AWS"
                TotalCost = $totalCost
                Currency = "USD"
                Period = "Month-to-date"
                Services = $services
                Timestamp = Get-Date
            }
        } else {
            Write-Host "⚠️  Unable to fetch AWS costs. Check AWS CLI configuration." -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "❌ Error fetching AWS costs: $_" -ForegroundColor Red
        return $null
    }
}

# ==============================================================================
# Azure Cost Functions
# ==============================================================================

function Get-AzureCosts {
    Write-Host "📊 Fetching Azure costs..." -ForegroundColor Cyan
    
    try {
        # Check if Azure CLI is available
        $azVersion = az version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Azure CLI not found. Install from: https://aka.ms/installazurecli" -ForegroundColor Yellow
            return $null
        }
        
        # Check if logged in
        $account = az account show 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Not logged in to Azure. Run: az login" -ForegroundColor Yellow
            return $null
        }
        
        $accountData = $account | ConvertFrom-Json
        $subscriptionId = $accountData.id
        
        # Get current month costs
        $startDate = (Get-Date -Day 1).ToString("yyyy-MM-dd")
        $endDate = (Get-Date).ToString("yyyy-MM-dd")
        
        # Azure Cost Management API
        $costJson = az consumption usage list `
            --start-date $startDate `
            --end-date $endDate `
            --output json 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $costData = $costJson | ConvertFrom-Json
            $totalCost = ($costData | Measure-Object -Property pretaxCost -Sum).Sum
            $totalCost = [Math]::Round($totalCost, 2)
            
            # Group by service
            $services = @{}
            $costData | Group-Object -Property meterCategory | ForEach-Object {
                $serviceCost = ($_.Group | Measure-Object -Property pretaxCost -Sum).Sum
                if ($serviceCost -gt 0.01) {
                    $services[$_.Name] = [Math]::Round($serviceCost, 2)
                }
            }
            
            return @{
                Provider = "Azure"
                TotalCost = $totalCost
                Currency = "USD"
                Period = "Month-to-date"
                Services = $services
                Timestamp = Get-Date
            }
        } else {
            Write-Host "⚠️  Unable to fetch Azure costs. Check permissions." -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "❌ Error fetching Azure costs: $_" -ForegroundColor Red
        return $null
    }
}

# ==============================================================================
# GCP Cost Functions
# ==============================================================================

function Get-GCPCosts {
    Write-Host "📊 Fetching GCP costs..." -ForegroundColor Cyan
    
    try {
        # Check if gcloud is available
        $gcloudVersion = gcloud version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
            return $null
        }
        
        # Get current project
        $project = gcloud config get-value project 2>$null
        if ([string]::IsNullOrEmpty($project)) {
            Write-Host "⚠️  No GCP project selected. Run: gcloud config set project PROJECT_ID" -ForegroundColor Yellow
            return $null
        }
        
        # Note: GCP billing data requires BigQuery export setup
        Write-Host "ℹ️  GCP cost data requires BigQuery billing export configuration" -ForegroundColor Yellow
        Write-Host "   Setup: https://cloud.google.com/billing/docs/how-to/export-data-bigquery" -ForegroundColor Gray
        
        # Placeholder - actual implementation requires BigQuery
        return @{
            Provider = "GCP"
            TotalCost = 0
            Currency = "USD"
            Period = "Month-to-date"
            Services = @{}
            Timestamp = Get-Date
            Note = "Configure BigQuery billing export for cost data"
        }
    } catch {
        Write-Host "❌ Error fetching GCP costs: $_" -ForegroundColor Red
        return $null
    }
}

# ==============================================================================
# Alert Functions
# ==============================================================================

function Test-BudgetThreshold {
    param(
        [hashtable]$CostData
    )
    
    $totalCost = $CostData.TotalCost
    $budget = $Script:Config.BudgetThreshold
    $usage = $totalCost / $budget
    
    $alert = $null
    
    if ($usage -ge $Script:Config.AlertThresholds.Emergency) {
        $alert = @{
            Level = "EMERGENCY"
            Color = "Red"
            Icon = "🚨"
            Message = "Budget exceeded!"
        }
    } elseif ($usage -ge $Script:Config.AlertThresholds.Critical) {
        $alert = @{
            Level = "CRITICAL"
            Color = "Red"
            Icon = "⚠️"
            Message = "Approaching budget limit"
        }
    } elseif ($usage -ge $Script:Config.AlertThresholds.Warning) {
        $alert = @{
            Level = "WARNING"
            Color = "Yellow"
            Icon = "⚠️"
            Message = "Budget usage high"
        }
    }
    
    return $alert
}

function Send-CostAlert {
    param(
        [hashtable]$Alert,
        [hashtable]$CostData
    )
    
    $subject = "$($Alert.Icon) $($Alert.Level): $($CostData.Provider) Cost Alert"
    $body = @"
Cloud Provider: $($CostData.Provider)
Current Spend: `$$($CostData.TotalCost)
Budget: `$$($Script:Config.BudgetThreshold)
Usage: $([Math]::Round(($CostData.TotalCost / $Script:Config.BudgetThreshold) * 100, 1))%

Status: $($Alert.Message)

Top Services:
$($CostData.Services.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object { "  - $($_.Key): `$$($_.Value)" } | Out-String)

Timestamp: $($CostData.Timestamp)
"@
    
    Write-Host "`n$($Alert.Icon) $($Alert.Level) ALERT: $($CostData.Provider)" -ForegroundColor $Alert.Color
    Write-Host $body -ForegroundColor $Alert.Color
    
    # In production, integrate with email service or webhook
    # Send-MailMessage -To $Script:Config.AlertEmail -Subject $subject -Body $body
}

# ==============================================================================
# Reporting Functions
# ==============================================================================

function Show-CostDashboard {
    param(
        [array]$AllCosts
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            Multi-Cloud Cost Monitoring Dashboard            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $totalSpend = ($AllCosts | Measure-Object -Property TotalCost -Sum).Sum
    $budget = $Script:Config.BudgetThreshold
    $remaining = $budget - $totalSpend
    $usagePercent = [Math]::Round(($totalSpend / $budget) * 100, 1)
    
    Write-Host "Budget Overview:" -ForegroundColor Yellow
    Write-Host "  Total Budget:  `$$budget" -ForegroundColor Gray
    Write-Host "  Total Spend:   `$$([Math]::Round($totalSpend, 2))" -ForegroundColor Gray
    Write-Host "  Remaining:     `$$([Math]::Round($remaining, 2))" -ForegroundColor $(if ($remaining -lt 0) { "Red" } else { "Green" })
    Write-Host "  Usage:         $usagePercent%" -ForegroundColor $(if ($usagePercent -gt 90) { "Red" } elseif ($usagePercent -gt 80) { "Yellow" } else { "Green" })
    
    # Progress bar
    $barLength = 50
    $filled = [Math]::Floor($barLength * ($totalSpend / $budget))
    $bar = "█" * $filled + "░" * ($barLength - $filled)
    Write-Host "`n  [$bar] $usagePercent%`n" -ForegroundColor Cyan
    
    # Per-provider costs
    Write-Host "Provider Breakdown:" -ForegroundColor Yellow
    foreach ($cost in $AllCosts) {
        $percent = [Math]::Round(($cost.TotalCost / $totalSpend) * 100, 1)
        Write-Host ("  {0,-10} : `${1,8:N2}  ({2,5}%)" -f $cost.Provider, $cost.TotalCost, $percent) -ForegroundColor Cyan
        
        # Top services
        $topServices = $cost.Services.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 3
        foreach ($service in $topServices) {
            Write-Host ("    └─ {0,-25} : `${1,6:N2}" -f $service.Key, $service.Value) -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Export-CostReport {
    param(
        [array]$AllCosts
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $filename = "cost-monitoring-report-$timestamp.json"
    
    $report = @{
        Timestamp = Get-Date
        Budget = $Script:Config.BudgetThreshold
        TotalSpend = ($AllCosts | Measure-Object -Property TotalCost -Sum).Sum
        Providers = $AllCosts
    }
    
    $report | ConvertTo-Json -Depth 10 | Out-File $filename
    Write-Host "✅ Report exported to: $filename`n" -ForegroundColor Green
}

# ==============================================================================
# Main Execution
# ==============================================================================

Write-Host "`n💰 Multi-Cloud Cost Monitoring Dashboard`n" -ForegroundColor Cyan

# Collect costs from all providers
$allCosts = @()

$awsCost = Get-AWSCosts
if ($awsCost) { $allCosts += $awsCost }

$azureCost = Get-AzureCosts
if ($azureCost) { $allCosts += $azureCost }

$gcpCost = Get-GCPCosts
if ($gcpCost) { $allCosts += $gcpCost }

if ($allCosts.Count -eq 0) {
    Write-Host "❌ No cost data available. Ensure cloud CLIs are configured.`n" -ForegroundColor Red
    exit 1
}

# Display dashboard
Show-CostDashboard -AllCosts $allCosts

# Check for alerts
foreach ($cost in $allCosts) {
    $alert = Test-BudgetThreshold -CostData $cost
    if ($alert) {
        Send-CostAlert -Alert $alert -CostData $cost
    }
}

# Generate report if requested
if ($GenerateReport) {
    Export-CostReport -AllCosts $allCosts
}

Write-Host "💡 Cost Optimization Tips:" -ForegroundColor Cyan
Write-Host "   1. Review and terminate unused resources" -ForegroundColor Gray
Write-Host "   2. Enable auto-scaling to match demand" -ForegroundColor Gray
Write-Host "   3. Use Reserved Instances for predictable workloads" -ForegroundColor Gray
Write-Host "   4. Implement resource tagging for cost allocation" -ForegroundColor Gray
Write-Host "   5. Set up budget alerts in each cloud console`n" -ForegroundColor Gray
