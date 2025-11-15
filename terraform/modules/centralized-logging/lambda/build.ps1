# Build Lambda deployment package
$ErrorActionPreference = "Stop"

Write-Host "Building Lambda deployment package..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$lambdaDir = $scriptDir

# Create temporary build directory
$buildDir = Join-Path $lambdaDir "build"
if (Test-Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir | Out-Null

# Copy Lambda function
Copy-Item -Path (Join-Path $lambdaDir "index.py") -Destination $buildDir

# Create ZIP file
$zipPath = Join-Path $lambdaDir "log-export.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

# Create ZIP using PowerShell
Compress-Archive -Path (Join-Path $buildDir "*") -DestinationPath $zipPath -CompressionLevel Optimal

# Clean up build directory
Remove-Item -Path $buildDir -Recurse -Force

$fileSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)

Write-Host "Lambda package created successfully: log-export.zip" -ForegroundColor Green
Write-Host "Package size: $fileSize KB" -ForegroundColor Gray
