# GitHub Branch Protection Setup Guide

This guide explains how to configure branch protection rules to ensure code quality and security for the Cloud Infrastructure Automation project.

## 🎯 Overview

Branch protection rules prevent direct commits to important branches and enforce quality gates through pull requests and automated checks.

## 🔒 Recommended Branch Protection Rules

### For `main` Branch (Production)

Navigate to: **Settings → Branches → Add branch protection rule**

#### Branch name pattern
```
main
```

#### Protection Rules

**Require a pull request before merging** ✅
- ✅ Require approvals: **2**
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners
- ✅ Require approval of the most recent reviewable push

**Require status checks to pass before merging** ✅
- ✅ Require branches to be up to date before merging
- **Required status checks:**
  - `Security Scanning / security-scan`
  - `Terraform / terraform`
  - `Ansible Lint / ansible-lint`
  - `Generate Terraform Documentation / terraform-docs`
  - `Generate Architecture Diagrams / generate-diagrams`

**Require conversation resolution before merging** ✅

**Require signed commits** ✅

**Require linear history** ✅

**Require deployments to succeed before merging** ✅
- Required deployment environments:
  - `staging`

**Lock branch** ❌ (Do not enable - prevents all pushes)

**Do not allow bypassing the above settings** ✅

**Restrict who can push to matching branches** ✅
- Add: Administrators, DevOps team

**Allow force pushes** ❌

**Allow deletions** ❌

### For `develop` Branch (Staging)

#### Branch name pattern
```
develop
```

#### Protection Rules

**Require a pull request before merging** ✅
- ✅ Require approvals: **1**
- ✅ Dismiss stale pull request approvals when new commits are pushed

**Require status checks to pass before merging** ✅
- ✅ Require branches to be up to date before merging
- **Required status checks:**
  - `Security Scanning / security-scan`
  - `Terraform / terraform`
  - `Ansible Lint / ansible-lint`

**Require conversation resolution before merging** ✅

**Require signed commits** ✅

**Allow force pushes** ❌

**Allow deletions** ❌

## 📋 Step-by-Step Configuration

### Step 1: Access Repository Settings

1. Go to your repository on GitHub
2. Click **Settings** (requires admin access)
3. Click **Branches** in the left sidebar

### Step 2: Add Branch Protection Rule for Main

1. Click **Add branch protection rule**
2. Enter branch name pattern: `main`
3. Enable all recommended settings above
4. Click **Create** at the bottom

### Step 3: Add Branch Protection Rule for Develop

1. Click **Add branch protection rule** again
2. Enter branch name pattern: `develop`
3. Enable settings for develop branch
4. Click **Create**

### Step 4: Configure CODEOWNERS (Optional but Recommended)

Create `.github/CODEOWNERS` file:

```
# Infrastructure code requires DevOps review
/terraform/     @Botbynetz
/ansible/       @Botbynetz

# CI/CD workflows require approval
/.github/workflows/  @Botbynetz

# Documentation can be approved by anyone
/docs/          @Botbynetz

# Security-critical files
/SECURITY.md    @Botbynetz
/.github/       @Botbynetz
```

### Step 5: Enable Required Status Checks

After first workflow runs, status checks will appear in the branch protection settings:

1. Edit the branch protection rule
2. Scroll to "Require status checks to pass"
3. Search and add each status check name
4. Save changes

## 🔐 Signed Commits Setup

### For Individual Contributors

#### Step 1: Generate GPG Key

```bash
gpg --full-generate-key
```

Choose:
- RSA and RSA
- 4096 bits
- Key doesn't expire (or set expiration)
- Your name and email (must match GitHub email)

#### Step 2: List GPG Keys

```bash
gpg --list-secret-keys --keyid-format=long
```

Copy the GPG key ID (after `sec rsa4096/`)

#### Step 3: Export Public Key

```bash
gpg --armor --export YOUR_KEY_ID
```

#### Step 4: Add to GitHub

1. Go to GitHub Settings → SSH and GPG keys
2. Click **New GPG key**
3. Paste the public key
4. Click **Add GPG key**

#### Step 5: Configure Git

```bash
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

### For GitHub Actions (Automatic)

GitHub Actions commits are automatically signed when using:

```yaml
- name: Commit changes
  run: |
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    git commit -m "Auto-generated commit"
```

## 🚦 Workflow Integration

### Status Checks Configuration

Ensure your workflows have clear job names that match status checks:

```yaml
jobs:
  security-scan:
    name: Security Scanning
    runs-on: ubuntu-latest
    # ...

  terraform:
    name: Terraform
    needs: security-scan
    # ...
```

### Required Workflows

All these workflows must pass before merging:

1. **Security Scanning** (`.github/workflows/infra.yml`)
   - tfsec
   - Checkov

2. **Terraform** (`.github/workflows/infra.yml`)
   - Format check
   - Validation
   - Plan generation

3. **Ansible Lint** (`.github/workflows/infra.yml`)
   - Playbook linting
   - Syntax check

4. **Documentation** (`.github/workflows/terraform-docs.yml`)
   - Auto-generated docs

5. **Diagrams** (`.github/workflows/diagrams.yml`)
   - Architecture diagrams

## 🎯 Best Practices

### Pull Request Workflow

1. **Create feature branch** from `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature
   ```

2. **Make changes and commit** (signed)
   ```bash
   git add .
   git commit -S -m "feat: add new feature"
   ```

3. **Push and create PR**
   ```bash
   git push origin feature/new-feature
   ```

4. **Wait for status checks** to pass

5. **Request reviews** from team members

6. **Resolve conversations** if any

7. **Merge** when approved and checks pass

### Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new EC2 instance type support
fix: resolve security group rule conflict
docs: update README with new examples
chore: upgrade Terraform to 1.6.0
refactor: reorganize module structure
test: add integration tests for bastion
ci: improve workflow performance
security: update dependencies with CVE fixes
```

### Review Guidelines

#### For Reviewers

- ✅ Check code quality and style
- ✅ Verify tests pass
- ✅ Review security implications
- ✅ Ensure documentation is updated
- ✅ Check for breaking changes
- ✅ Validate Terraform plan output

#### For Authors

- ✅ Write clear PR descriptions
- ✅ Reference related issues
- ✅ Keep PRs focused and small
- ✅ Respond to review comments promptly
- ✅ Update based on feedback
- ✅ Ensure all checks pass

## 🛡️ Emergency Bypass Procedure

In critical situations, administrators can bypass branch protection:

1. **Only for emergencies** (security patches, critical bugs)
2. **Document reason** in PR description
3. **Create follow-up PR** for proper review
4. **Notify team** immediately

### Enable Bypass Temporarily

1. Settings → Branches → Edit rule
2. Temporarily uncheck "Do not allow bypassing"
3. Merge critical fix
4. **Immediately re-enable** protection

## 📊 Monitoring Compliance

### Regular Audits

- Review branch protection settings monthly
- Check for unauthorized bypass attempts
- Audit unsigned commits
- Review failed status checks

### Metrics to Track

- PR merge time
- Number of review cycles
- Failed status checks
- Security scan findings
- Code review participation

## 🔧 Troubleshooting

### Status Check Not Appearing

**Problem**: Status check doesn't show in branch protection settings

**Solution**:
1. Ensure workflow has run at least once
2. Check workflow job name matches exactly
3. Verify workflow is on the protected branch

### Cannot Push Commits

**Problem**: `protected branch hook declined`

**Solution**:
1. Create a pull request instead
2. Ensure you're not pushing directly to `main` or `develop`

### Signed Commit Required Error

**Problem**: Commit rejected due to missing signature

**Solution**:
1. Configure GPG key (see setup above)
2. Enable automatic signing:
   ```bash
   git config --global commit.gpgsign true
   ```
3. Amend last commit with signature:
   ```bash
   git commit --amend --no-edit -S
   ```

### Reviews Required But No Reviewers

**Problem**: Can't merge because reviews required

**Solution**:
1. Add CODEOWNERS file
2. Request reviews from team members
3. For personal projects, reduce required reviews to 0

## 📚 Additional Resources

- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [Signed Commits Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [CODEOWNERS Syntax](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

---

**Repository**: [Cloud-Infrastructure-Automation](https://github.com/Botbynetz/Cloud-Infrastructure-Automation)  
**Maintainer**: [@Botbynetz](https://github.com/Botbynetz)
