# Build Lambda deployment packages for alerting module
$ErrorActionPreference = "Stop"

Write-Host "Building Lambda deployment packages for alerting module..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lambdaDir = $scriptDir

# Lambda functions to build
$functions = @(
    "slack-notifier",
    "pagerduty-notifier",
    "alert-aggregator"
)

foreach ($function in $functions) {
    Write-Host "`nBuilding $function..." -ForegroundColor Yellow
    
    # Create temporary build directory
    $buildDir = Join-Path $lambdaDir "build"
    if (Test-Path $buildDir) {
        Remove-Item -Path $buildDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    
    # Copy Lambda function
    $sourceFile = Join-Path $lambdaDir "$function.py"
    $targetFile = Join-Path $buildDir "index.py"
    Copy-Item -Path $sourceFile -Destination $targetFile
    
    # Create ZIP file
    $zipPath = Join-Path $lambdaDir "$function.zip"
    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }
    
    # Create ZIP using PowerShell
    Compress-Archive -Path (Join-Path $buildDir "*") -DestinationPath $zipPath -CompressionLevel Optimal
    
    # Clean up build directory
    Remove-Item -Path $buildDir -Recurse -Force
    
    $fileSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
    Write-Host "Package created: $function.zip ($fileSize KB)" -ForegroundColor Green
}

Write-Host "`nAll Lambda packages built successfully!" -ForegroundColor Green
