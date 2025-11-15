#!/usr/bin/env pwsh
# ==============================================================================
# Multi-Cloud Cost Calculator
# ==============================================================================
# Calculate and compare costs across AWS, Azure, and GCP

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('aws', 'azure', 'gcp', 'all')]
    [string]$Provider = 'all',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment = 'production',
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = 'table'
)

# ==============================================================================
# Cost Data (USD per month)
# ==============================================================================

$CostData = @{
    compute = @{
        'micro' = @{
            aws   = 7.50   # t3.micro
            azure = 8.03   # B1s
            gcp   = 6.50   # e2-micro
        }
        'small' = @{
            aws   = 15.18  # t3.small
            azure = 14.60  # B1ms
            gcp   = 13.00  # e2-small
        }
        'medium' = @{
            aws   = 30.37  # t3.medium
            azure = 29.93  # B2ms
            gcp   = 24.27  # e2-medium
        }
        'large' = @{
            aws   = 60.74  # t3.large
            azure = 58.40  # B4ms
            gcp   = 48.54  # e2-standard-2
        }
    }
    storage = @{
        '10GB' = @{
            aws   = 0.23   # S3 Standard
            azure = 0.18   # Blob Hot
            gcp   = 0.20   # Standard
        }
        '100GB' = @{
            aws   = 2.30
            azure = 1.84
            gcp   = 2.00
        }
        '1TB' = @{
            aws   = 23.00
            azure = 18.40
            gcp   = 20.00
        }
    }
    database = @{
        'micro' = @{
            aws   = 12.41  # db.t3.micro
            azure = 14.61  # B_Gen5_1
            gcp   = 9.37   # db-f1-micro
        }
        'small' = @{
            aws   = 49.64  # db.t3.small
            azure = 58.40  # B_Gen5_2
            gcp   = 37.54  # db-g1-small
        }
        'medium' = @{
            aws   = 99.28  # db.t3.medium
            azure = 116.80 # GP_Gen5_2
            gcp   = 75.08  # db-n1-standard-1
        }
    }
    networking = @{
        'load_balancer' = @{
            aws   = 16.20  # ALB
            azure = 18.25  # Standard LB
            gcp   = 18.26  # Standard LB
        }
        'data_transfer_1tb' = @{
            aws   = 90.00
            azure = 87.00
            gcp   = 120.00
        }
    }
    monitoring = @{
        'basic' = @{
            aws   = 5.00   # CloudWatch
            azure = 5.00   # Azure Monitor
            gcp   = 0.00   # Free tier
        }
    }
}

# ==============================================================================
# Configuration Profiles
# ==============================================================================

$Profiles = @{
    dev = @{
        compute_size = 'micro'
        compute_count = 1
        storage_size = '10GB'
        database_enabled = $false
        database_size = 'micro'
        load_balancer = $false
        data_transfer = 0
    }
    staging = @{
        compute_size = 'small'
        compute_count = 2
        storage_size = '100GB'
        database_enabled = $true
        database_size = 'small'
        load_balancer = $true
        data_transfer = 100 # GB
    }
    production = @{
        compute_size = 'medium'
        compute_count = 3
        storage_size = '1TB'
        database_enabled = $true
        database_size = 'medium'
        load_balancer = $true
        data_transfer = 500 # GB
    }
}

# ==============================================================================
# Cost Calculation Functions
# ==============================================================================

function Calculate-ProviderCost {
    param(
        [string]$Provider,
        [hashtable]$Profile
    )
    
    $cost = 0
    
    # Compute cost
    $computeCost = $CostData.compute[$Profile.compute_size][$Provider]
    $cost += $computeCost * $Profile.compute_count
    
    # Storage cost
    $storageCost = $CostData.storage[$Profile.storage_size][$Provider]
    $cost += $storageCost
    
    # Database cost
    if ($Profile.database_enabled) {
        $dbCost = $CostData.database[$Profile.database_size][$Provider]
        $cost += $dbCost
    }
    
    # Load balancer cost
    if ($Profile.load_balancer) {
        $lbCost = $CostData.networking.load_balancer[$Provider]
        $cost += $lbCost
    }
    
    # Data transfer cost
    if ($Profile.data_transfer -gt 0) {
        $dtCost = $CostData.networking.data_transfer_1tb[$Provider]
        $cost += ($dtCost * ($Profile.data_transfer / 1024))
    }
    
    # Monitoring cost
    $monitoringCost = $CostData.monitoring.basic[$Provider]
    $cost += $monitoringCost
    
    return [Math]::Round($cost, 2)
}

function Get-CostBreakdown {
    param(
        [string]$Provider,
        [hashtable]$Profile
    )
    
    $breakdown = @{
        Compute = [Math]::Round($CostData.compute[$Profile.compute_size][$Provider] * $Profile.compute_count, 2)
        Storage = [Math]::Round($CostData.storage[$Profile.storage_size][$Provider], 2)
        Database = if ($Profile.database_enabled) { 
            [Math]::Round($CostData.database[$Profile.database_size][$Provider], 2) 
        } else { 0 }
        LoadBalancer = if ($Profile.load_balancer) { 
            [Math]::Round($CostData.networking.load_balancer[$Provider], 2) 
        } else { 0 }
        DataTransfer = if ($Profile.data_transfer -gt 0) { 
            [Math]::Round($CostData.networking.data_transfer_1tb[$Provider] * ($Profile.data_transfer / 1024), 2) 
        } else { 0 }
        Monitoring = [Math]::Round($CostData.monitoring.basic[$Provider], 2)
    }
    
    return $breakdown
}

# ==============================================================================
# Display Functions
# ==============================================================================

function Show-CostTable {
    param(
        [hashtable]$Results
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       Multi-Cloud Cost Comparison - $Environment Environment       ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    # Summary table
    $summaryData = @()
    foreach ($prov in $Results.Keys) {
        $summaryData += [PSCustomObject]@{
            Provider = $prov.ToUpper()
            'Monthly Cost' = "`$$($Results[$prov].Total)"
            'Annual Cost' = "`$$([Math]::Round($Results[$prov].Total * 12, 2))"
            'Compute' = "`$$($Results[$prov].Breakdown.Compute)"
            'Storage' = "`$$($Results[$prov].Breakdown.Storage)"
            'Database' = "`$$($Results[$prov].Breakdown.Database)"
        }
    }
    
    $summaryData | Format-Table -AutoSize
    
    # Cost savings
    if ($Results.Count -gt 1) {
        $costs = $Results.Values.Total
        $minCost = ($costs | Measure-Object -Minimum).Minimum
        $maxCost = ($costs | Measure-Object -Maximum).Maximum
        $savings = $maxCost - $minCost
        $savingsPercent = [Math]::Round(($savings / $maxCost) * 100, 1)
        
        $cheapestProvider = ($Results.GetEnumerator() | Where-Object { $_.Value.Total -eq $minCost }).Key
        
        Write-Host "💰 Cost Savings:" -ForegroundColor Green
        Write-Host "   Cheapest: $($cheapestProvider.ToUpper()) at `$$minCost/month" -ForegroundColor Green
        Write-Host "   Potential savings: `$$savings/month ($savingsPercent%) vs most expensive" -ForegroundColor Yellow
        Write-Host "   Annual savings: `$$([Math]::Round($savings * 12, 2))`n" -ForegroundColor Yellow
    }
}

function Show-DetailedBreakdown {
    param(
        [string]$Provider,
        [hashtable]$Result
    )
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              $($Provider.ToUpper()) Detailed Cost Breakdown               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $breakdown = $Result.Breakdown
    $total = $Result.Total
    
    foreach ($category in $breakdown.Keys | Sort-Object) {
        $cost = $breakdown[$category]
        if ($cost -gt 0) {
            $percent = [Math]::Round(($cost / $total) * 100, 1)
            $bar = "█" * [Math]::Floor($percent / 2)
            Write-Host ("{0,-15} : `${1,8:N2}  {2,5}%  {3}" -f $category, $cost, $percent, $bar) -ForegroundColor Cyan
        }
    }
    
    Write-Host ("{0,-15} : `${1,8:N2}" -f "`nTOTAL", $total) -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host ""
}

function Export-CostReport {
    param(
        [hashtable]$Results,
        [string]$Format = 'json'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $filename = "cost-report-$Environment-$timestamp.$Format"
    
    if ($Format -eq 'json') {
        $Results | ConvertTo-Json -Depth 10 | Out-File $filename
    } elseif ($Format -eq 'csv') {
        $csvData = @()
        foreach ($prov in $Results.Keys) {
            $csvData += [PSCustomObject]@{
                Provider = $prov
                Environment = $Environment
                MonthlyCost = $Results[$prov].Total
                AnnualCost = $Results[$prov].Total * 12
                Compute = $Results[$prov].Breakdown.Compute
                Storage = $Results[$prov].Breakdown.Storage
                Database = $Results[$prov].Breakdown.Database
                LoadBalancer = $Results[$prov].Breakdown.LoadBalancer
                DataTransfer = $Results[$prov].Breakdown.DataTransfer
                Monitoring = $Results[$prov].Breakdown.Monitoring
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
        }
        $csvData | Export-Csv -Path $filename -NoTypeInformation
    }
    
    Write-Host "✅ Cost report exported to: $filename`n" -ForegroundColor Green
}

# ==============================================================================
# Main Execution
# ==============================================================================

Write-Host "`n🔍 Multi-Cloud Cost Calculator`n" -ForegroundColor Cyan

# Get configuration profile
$profile = $Profiles[$Environment]

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Environment: $Environment" -ForegroundColor Gray
Write-Host "  Compute: $($profile.compute_count)x $($profile.compute_size)" -ForegroundColor Gray
Write-Host "  Storage: $($profile.storage_size)" -ForegroundColor Gray
Write-Host "  Database: $(if ($profile.database_enabled) { $profile.database_size } else { 'Disabled' })" -ForegroundColor Gray
Write-Host "  Load Balancer: $(if ($profile.load_balancer) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Gray
Write-Host "  Data Transfer: $($profile.data_transfer) GB/month`n" -ForegroundColor Gray

# Calculate costs
$results = @{}

$providers = if ($Provider -eq 'all') { @('aws', 'azure', 'gcp') } else { @($Provider) }

foreach ($prov in $providers) {
    $total = Calculate-ProviderCost -Provider $prov -Profile $profile
    $breakdown = Get-CostBreakdown -Provider $prov -Profile $profile
    
    $results[$prov] = @{
        Total = $total
        Breakdown = $breakdown
    }
}

# Display results
if ($OutputFormat -eq 'table' -or $OutputFormat -eq 'all') {
    Show-CostTable -Results $results
}

if ($OutputFormat -eq 'detailed' -or $OutputFormat -eq 'all') {
    foreach ($prov in $results.Keys) {
        Show-DetailedBreakdown -Provider $prov -Result $results[$prov]
    }
}

# Export report
if ($OutputFormat -eq 'json' -or $OutputFormat -eq 'csv') {
    Export-CostReport -Results $results -Format $OutputFormat
}

# Recommendations
Write-Host "💡 Recommendations:" -ForegroundColor Cyan
$cheapest = ($results.GetEnumerator() | Sort-Object { $_.Value.Total } | Select-Object -First 1).Key
Write-Host "   1. Use $($cheapest.ToUpper()) for lowest cost" -ForegroundColor Gray
Write-Host "   2. Consider Reserved Instances/Committed Use for 30-70% savings" -ForegroundColor Gray
Write-Host "   3. Enable auto-scaling to optimize costs during low usage" -ForegroundColor Gray
Write-Host "   4. Use lifecycle policies to move old data to cheaper storage tiers" -ForegroundColor Gray
Write-Host "   5. Review and right-size instances monthly`n" -ForegroundColor Gray

Write-Host "📊 Use these calculators for detailed estimates:" -ForegroundColor Yellow
Write-Host "   AWS: https://calculator.aws/" -ForegroundColor Gray
Write-Host "   Azure: https://azure.microsoft.com/en-us/pricing/calculator/" -ForegroundColor Gray
Write-Host "   GCP: https://cloud.google.com/products/calculator`n" -ForegroundColor Gray
