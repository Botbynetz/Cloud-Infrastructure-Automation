# Makefile for Cloud Infrastructure Project
# Provides convenient shortcuts for common operations

.PHONY: help init plan apply destroy fmt validate test clean check lint security all

# Default target
.DEFAULT_GOAL := help

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[1;32m
RED := \033[1;31m
NC := \033[0m # No Color

# Variables
TERRAFORM_DIR := terraform
ANSIBLE_DIR := ansible
ENV ?= dev
TFVARS_FILE := $(TERRAFORM_DIR)/env/$(ENV).tfvars

##@ Help

help: ## Display this help message
	@echo "$(GREEN)Cloud Infrastructure Automation$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> [ENV=dev|staging|prod]"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Terraform Operations

init: ## Initialize Terraform (ENV=dev)
	@echo "$(YELLOW)Initializing Terraform for $(ENV) environment...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init
	cd $(TERRAFORM_DIR) && terraform workspace select $(ENV) || terraform workspace new $(ENV)

plan: ## Run Terraform plan (ENV=dev)
	@echo "$(YELLOW)Planning infrastructure for $(ENV) environment...$(NC)"
	cd $(TERRAFORM_DIR) && terraform plan -var-file="$(notdir $(TFVARS_FILE))"

apply: ## Apply Terraform changes (ENV=dev)
	@echo "$(YELLOW)Applying infrastructure for $(ENV) environment...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -var-file="$(notdir $(TFVARS_FILE))"

destroy: ## Destroy Terraform infrastructure (ENV=dev)
	@echo "$(RED)WARNING: This will destroy all resources in $(ENV) environment!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(TERRAFORM_DIR) && terraform destroy -var-file="$(notdir $(TFVARS_FILE))"; \
	else \
		echo "Cancelled."; \
	fi

output: ## Show Terraform outputs (ENV=dev)
	@echo "$(YELLOW)Showing outputs for $(ENV) environment...$(NC)"
	cd $(TERRAFORM_DIR) && terraform output

##@ Code Quality

fmt: ## Format Terraform code
	@echo "$(YELLOW)Formatting Terraform code...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	cd $(TERRAFORM_DIR) && terraform validate

lint: ## Lint Ansible playbooks
	@echo "$(YELLOW)Linting Ansible playbooks...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-lint playbooks/

check: fmt validate lint ## Run all code quality checks
	@echo "$(GREEN)All checks passed!$(NC)"

##@ Security

security: ## Run security scanning (tfsec)
	@echo "$(YELLOW)Running security scan...$(NC)"
	@command -v tfsec >/dev/null 2>&1 || { echo "$(RED)tfsec not installed. Install: https://github.com/aquasecurity/tfsec$(NC)"; exit 1; }
	tfsec $(TERRAFORM_DIR)

##@ Ansible Operations

ansible-syntax: ## Check Ansible syntax
	@echo "$(YELLOW)Checking Ansible syntax...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook --syntax-check playbooks/main.yml

ansible-run: ## Run Ansible playbook (ENV=dev)
	@echo "$(YELLOW)Running Ansible playbook for $(ENV) environment...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/aws_ec2.yml playbooks/main.yml -l $(ENV)

ansible-check: ## Dry run Ansible playbook (ENV=dev)
	@echo "$(YELLOW)Dry run Ansible playbook for $(ENV) environment...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/aws_ec2.yml playbooks/main.yml -l $(ENV) --check

##@ Testing

test: ## Run Terratest tests
	@echo "$(YELLOW)Running Terratest...$(NC)"
	@command -v go >/dev/null 2>&1 || { echo "$(RED)Go not installed$(NC)"; exit 1; }
	cd tests && go test -v -timeout 30m

test-unit: ## Run unit tests only
	@echo "$(YELLOW)Running unit tests...$(NC)"
	cd tests && go test -v -timeout 10m -run TestUnit

##@ Setup & Clean

setup: ## Initial project setup
	@echo "$(YELLOW)Setting up project...$(NC)"
	@test -f .env || cp .env.example .env
	@echo "$(GREEN)Created .env file. Please configure your AWS credentials.$(NC)"
	@echo "$(YELLOW)Run 'make init' next.$(NC)"

clean: ## Clean temporary files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	find . -type f -name "*.tfstate.backup" -delete
	find . -type f -name ".terraform.lock.hcl" -delete
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

##@ Complete Workflows

deploy-dev: init plan ## Deploy to dev environment
	@echo "$(YELLOW)Deploying to dev environment...$(NC)"
	$(MAKE) apply ENV=dev
	$(MAKE) ansible-run ENV=dev
	@echo "$(GREEN)Dev environment deployed!$(NC)"

deploy-staging: ## Deploy to staging environment
	@echo "$(YELLOW)Deploying to staging environment...$(NC)"
	$(MAKE) init ENV=staging
	$(MAKE) plan ENV=staging
	$(MAKE) apply ENV=staging
	$(MAKE) ansible-run ENV=staging
	@echo "$(GREEN)Staging environment deployed!$(NC)"

deploy-prod: ## Deploy to production environment (requires confirmation)
	@echo "$(RED)WARNING: Deploying to PRODUCTION!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(MAKE) init ENV=prod; \
		$(MAKE) plan ENV=prod; \
		$(MAKE) apply ENV=prod; \
		$(MAKE) ansible-run ENV=prod; \
		echo "$(GREEN)Production environment deployed!$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

all: check security test ## Run all checks, security scans, and tests
	@echo "$(GREEN)All validations passed!$(NC)"

##@ Utilities

docs: ## Generate Terraform documentation
	@echo "$(YELLOW)Generating Terraform documentation...$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 || { echo "$(RED)terraform-docs not installed$(NC)"; exit 1; }
	cd $(TERRAFORM_DIR) && terraform-docs markdown table . > TERRAFORM.md
	@echo "$(GREEN)Documentation generated!$(NC)"

cost: ## Estimate infrastructure cost (requires infracost)
	@echo "$(YELLOW)Estimating infrastructure cost for $(ENV)...$(NC)"
	@command -v infracost >/dev/null 2>&1 || { echo "$(RED)infracost not installed. Install: https://www.infracost.io/$(NC)"; exit 1; }
	cd $(TERRAFORM_DIR) && infracost breakdown --path . --terraform-var-file="$(notdir $(TFVARS_FILE))"

graph: ## Generate Terraform dependency graph
	@echo "$(YELLOW)Generating Terraform graph...$(NC)"
	cd $(TERRAFORM_DIR) && terraform graph | dot -Tpng > graph.png
	@echo "$(GREEN)Graph saved to terraform/graph.png$(NC)"

ssh: ## SSH into EC2 instance (requires INSTANCE_IP)
	@test -n "$(INSTANCE_IP)" || { echo "$(RED)Usage: make ssh INSTANCE_IP=<ip>$(NC)"; exit 1; }
	ssh -i ~/.ssh/cloud-infra.pem ubuntu@$(INSTANCE_IP)

##@ Information

version: ## Show tool versions
	@echo "$(YELLOW)Tool Versions:$(NC)"
	@terraform version | head -n 1
	@ansible --version | head -n 1
	@aws --version
	@echo "Environment: $(ENV)"

status: ## Show current Terraform state
	@echo "$(YELLOW)Current Terraform Status:$(NC)"
	@cd $(TERRAFORM_DIR) && terraform workspace show
	@cd $(TERRAFORM_DIR) && terraform state list 2>/dev/null || echo "No state file found"
