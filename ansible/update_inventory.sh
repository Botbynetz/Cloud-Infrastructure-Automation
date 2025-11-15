#!/bin/bash

# Script to automatically update Ansible inventory from Terraform outputs
# This script reads Terraform outputs and generates inventory files for each environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ansible Inventory Auto-Update Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to update inventory for a specific environment
update_inventory() {
    local env=$1
    local terraform_dir="../terraform"
    local inventory_dir="./inventory/${env}"
    local inventory_file="${inventory_dir}/hosts"

    echo -e "${YELLOW}Processing environment: ${env}${NC}"

    # Check if terraform directory exists
    if [ ! -d "$terraform_dir" ]; then
        echo -e "${RED}Error: Terraform directory not found: ${terraform_dir}${NC}"
        return 1
    fi

    # Initialize terraform with the correct backend
    echo "Initializing Terraform..."
    cd "$terraform_dir"
    terraform init -backend-config="backend/${env}.conf" -reconfigure > /dev/null 2>&1

    # Get outputs from Terraform
    echo "Reading Terraform outputs..."
    
    # Check if state exists
    if ! terraform output > /dev/null 2>&1; then
        echo -e "${RED}Error: No Terraform state found for ${env}. Please apply Terraform first.${NC}"
        cd - > /dev/null
        return 1
    fi

    PUBLIC_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "")
    
    if [ -z "$PUBLIC_IP" ]; then
        echo -e "${RED}Error: Could not retrieve public IP for ${env}${NC}"
        cd - > /dev/null
        return 1
    fi

    # Return to ansible directory
    cd - > /dev/null

    # Create inventory directory if it doesn't exist
    mkdir -p "$inventory_dir"

    # Generate inventory file
    echo "Generating inventory file: ${inventory_file}"
    cat > "$inventory_file" << EOF
# Auto-generated inventory file for ${env} environment
# Generated at: $(date)
# Source: Terraform output

[webservers]
${env}-web-server ansible_host=${PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

    echo -e "${GREEN}✓ Inventory updated successfully for ${env}${NC}"
    echo "  Public IP: ${PUBLIC_IP}"
    echo ""
}

# Main execution
main() {
    # Determine which environments to update
    if [ $# -eq 0 ]; then
        # No arguments, update all environments
        ENVIRONMENTS=("dev" "staging" "prod")
        echo "Updating all environments..."
        echo ""
    else
        # Update specific environment
        ENVIRONMENTS=("$@")
    fi

    # Update each environment
    SUCCESS_COUNT=0
    FAIL_COUNT=0

    for env in "${ENVIRONMENTS[@]}"; do
        if update_inventory "$env"; then
            ((SUCCESS_COUNT++))
        else
            ((FAIL_COUNT++))
        fi
    done

    # Summary
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Success: ${SUCCESS_COUNT}"
    echo -e "Failed: ${FAIL_COUNT}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}All inventories updated successfully!${NC}"
        echo ""
        echo "You can now run Ansible playbook:"
        echo "  ansible-playbook -i inventory/dev/hosts playbook.yml"
        return 0
    else
        echo -e "${YELLOW}Some inventories failed to update. Check the errors above.${NC}"
        return 1
    fi
}

# Run main function
main "$@"
