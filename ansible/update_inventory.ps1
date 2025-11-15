# Script to automatically update Ansible inventory from Terraform outputs
# PowerShell version for Windows users

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Environments = @("dev", "staging", "prod")
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "========================================" "Green"
Write-ColorOutput "Ansible Inventory Auto-Update Script" "Green"
Write-ColorOutput "========================================" "Green"
Write-Host ""

# Function to update inventory for a specific environment
function Update-Inventory {
    param(
        [string]$Environment
    )

    $TerraformDir = "..\terraform"
    $InventoryDir = ".\inventory\$Environment"
    $InventoryFile = "$InventoryDir\hosts"

    Write-ColorOutput "Processing environment: $Environment" "Yellow"

    # Check if terraform directory exists
    if (-not (Test-Path $TerraformDir)) {
        Write-ColorOutput "Error: Terraform directory not found: $TerraformDir" "Red"
        return $false
    }

    # Initialize terraform with the correct backend
    Write-Host "Initializing Terraform..."
    Push-Location $TerraformDir
    
    try {
        terraform init -backend-config="backend\$Environment.conf" -reconfigure | Out-Null
    } catch {
        Write-ColorOutput "Error: Failed to initialize Terraform" "Red"
        Pop-Location
        return $false
    }

    # Get outputs from Terraform
    Write-Host "Reading Terraform outputs..."
    
    try {
        $PublicIP = terraform output -raw ec2_public_ip 2>$null
        
        if ([string]::IsNullOrEmpty($PublicIP)) {
            Write-ColorOutput "Error: Could not retrieve public IP for $Environment" "Red"
            Pop-Location
            return $false
        }
    } catch {
        Write-ColorOutput "Error: No Terraform state found for $Environment. Please apply Terraform first." "Red"
        Pop-Location
        return $false
    }

    # Return to ansible directory
    Pop-Location

    # Create inventory directory if it doesn't exist
    if (-not (Test-Path $InventoryDir)) {
        New-Item -ItemType Directory -Path $InventoryDir -Force | Out-Null
    }

    # Generate inventory file
    Write-Host "Generating inventory file: $InventoryFile"
    
    $InventoryContent = @"
# Auto-generated inventory file for $Environment environment
# Generated at: $(Get-Date)
# Source: Terraform output

[webservers]
$Environment-web-server ansible_host=$PublicIP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
"@

    $InventoryContent | Out-File -FilePath $InventoryFile -Encoding UTF8

    Write-ColorOutput "✓ Inventory updated successfully for $Environment" "Green"
    Write-Host "  Public IP: $PublicIP"
    Write-Host ""

    return $true
}

# Main execution
$SuccessCount = 0
$FailCount = 0

if ($Environments.Count -eq 0) {
    $Environments = @("dev", "staging", "prod")
    Write-Host "Updating all environments..."
    Write-Host ""
}

foreach ($env in $Environments) {
    if (Update-Inventory -Environment $env) {
        $SuccessCount++
    } else {
        $FailCount++
    }
}

# Summary
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "Summary" "Green"
Write-ColorOutput "========================================" "Green"
Write-Host "Success: $SuccessCount"
Write-Host "Failed: $FailCount"
Write-Host ""

if ($FailCount -eq 0) {
    Write-ColorOutput "All inventories updated successfully!" "Green"
    Write-Host ""
    Write-Host "You can now run Ansible playbook:"
    Write-Host "  ansible-playbook -i inventory\dev\hosts playbook.yml"
} else {
    Write-ColorOutput "Some inventories failed to update. Check the errors above." "Yellow"
    exit 1
}
