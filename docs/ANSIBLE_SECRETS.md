# AWS Secrets Manager Integration for Ansible

Complete guide for using AWS Secrets Manager with Ansible playbooks.

## Prerequisites

### Install Required Collections

```bash
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install community.aws
```

### Install Python Dependencies

```bash
pip install boto3 botocore
```

### Configure AWS Credentials

**Option 1: IAM Role (Recommended for EC2)**
```bash
# EC2 instance automatically uses instance profile
# No manual configuration needed
```

**Option 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

**Option 3: AWS CLI Profile**
```bash
aws configure --profile ansible
export AWS_PROFILE=ansible
```

## Usage Examples

### Basic Secret Lookup

```yaml
---
- name: Fetch secret from Secrets Manager
  hosts: localhost
  vars:
    my_secret: "{{ lookup('amazon.aws.aws_secret', 'my-secret-name', region='ap-southeast-1') }}"
  
  tasks:
    - name: Display secret (be careful in production!)
      debug:
        msg: "Secret value: {{ my_secret }}"
```

### JSON Secret with Multiple Fields

```yaml
---
- name: Fetch database credentials
  hosts: all
  vars:
    db_creds: "{{ lookup('amazon.aws.aws_secret', 'database-prod', region='ap-southeast-1') | from_json }}"
  
  tasks:
    - name: Connect to database
      postgresql_db:
        login_host: "{{ db_creds.host }}"
        login_user: "{{ db_creds.username }}"
        login_password: "{{ db_creds.password }}"
        name: myapp
        state: present
```

### Multiple Secrets

```yaml
---
- name: Fetch multiple secrets
  hosts: webservers
  vars:
    db_secret: "{{ lookup('amazon.aws.aws_secret', 'database-credentials') | from_json }}"
    api_key: "{{ lookup('amazon.aws.aws_secret', 'external-api-key') }}"
    ssh_key: "{{ lookup('amazon.aws.aws_secret', 'ssh-private-key') }}"
  
  tasks:
    - name: Configure application
      template:
        src: app-config.j2
        dest: /etc/app/config.yml
        mode: '0600'
```

### Error Handling

```yaml
---
- name: Fetch secret with error handling
  hosts: all
  vars:
    secret_value: "{{ lookup('amazon.aws.aws_secret', 'my-secret', region='ap-southeast-1', on_missing='error') }}"
  
  tasks:
    - name: Use secret safely
      debug:
        msg: "Secret exists and loaded"
      when: secret_value is defined

    - name: Handle missing secret
      debug:
        msg: "Secret not found, using default"
      when: secret_value is not defined
```

### Using in Templates

**Jinja2 Template** (`templates/app-config.j2`):
```jinja2
# Application Configuration
database:
  host: {{ db_credentials.host }}
  port: {{ db_credentials.port }}
  username: {{ db_credentials.username }}
  password: {{ db_credentials.password }}
  database: {{ db_credentials.dbname }}

api:
  key: {{ api_key }}
  endpoint: https://api.example.com

security:
  secret_key: {{ app_secret }}
```

**Playbook**:
```yaml
---
- name: Deploy application with configuration
  hosts: webservers
  vars:
    db_credentials: "{{ lookup('amazon.aws.aws_secret', 'db-prod') | from_json }}"
    api_key: "{{ lookup('amazon.aws.aws_secret', 'api-key-prod') }}"
    app_secret: "{{ lookup('amazon.aws.aws_secret', 'app-secret-key') }}"
  
  tasks:
    - name: Deploy config file
      template:
        src: app-config.j2
        dest: /etc/app/config.yml
        owner: app
        group: app
        mode: '0600'
```

## Real-World Playbook Examples

### Web Application Deployment

```yaml
---
- name: Deploy web application with secrets
  hosts: webservers
  become: yes
  
  vars:
    db_secret: "{{ lookup('amazon.aws.aws_secret', 'webapp-db-prod', region='ap-southeast-1') | from_json }}"
    oauth_secret: "{{ lookup('amazon.aws.aws_secret', 'webapp-oauth-prod', region='ap-southeast-1') | from_json }}"
  
  pre_tasks:
    - name: Verify AWS access
      command: aws sts get-caller-identity
      register: aws_check
      changed_when: false
      
  tasks:
    - name: Create application directory
      file:
        path: /opt/webapp
        state: directory
        owner: webapp
        group: webapp
        mode: '0755'
    
    - name: Deploy environment file
      template:
        src: webapp.env.j2
        dest: /opt/webapp/.env
        owner: webapp
        group: webapp
        mode: '0600'
      vars:
        DB_HOST: "{{ db_secret.host }}"
        DB_USER: "{{ db_secret.username }}"
        DB_PASS: "{{ db_secret.password }}"
        OAUTH_ID: "{{ oauth_secret.client_id }}"
        OAUTH_SECRET: "{{ oauth_secret.client_secret }}"
      notify: restart webapp
    
    - name: Start application
      systemd:
        name: webapp
        state: started
        enabled: yes
  
  handlers:
    - name: restart webapp
      systemd:
        name: webapp
        state: restarted
```

### SSH Key Management

```yaml
---
- name: Setup SSH keys from Secrets Manager
  hosts: bastion
  become: yes
  
  vars:
    ssh_private_key: "{{ lookup('amazon.aws.aws_secret', 'bastion-ssh-key', region='ap-southeast-1') }}"
  
  tasks:
    - name: Create .ssh directory
      file:
        path: /root/.ssh
        state: directory
        owner: root
        group: root
        mode: '0700'
    
    - name: Deploy SSH private key
      copy:
        content: "{{ ssh_private_key }}"
        dest: /root/.ssh/id_rsa
        owner: root
        group: root
        mode: '0600'
    
    - name: Secure SSH configuration
      template:
        src: ssh_config.j2
        dest: /root/.ssh/config
        mode: '0600'
```

### Database Backup with Credentials

```yaml
---
- name: Backup database with dynamic credentials
  hosts: backup_server
  
  vars:
    db_creds: "{{ lookup('amazon.aws.aws_secret', 'postgres-backup-user', region='ap-southeast-1') | from_json }}"
    s3_creds: "{{ lookup('amazon.aws.aws_secret', 's3-backup-access', region='ap-southeast-1') | from_json }}"
  
  tasks:
    - name: Perform database dump
      postgresql_db:
        login_host: "{{ db_creds.host }}"
        login_user: "{{ db_creds.username }}"
        login_password: "{{ db_creds.password }}"
        name: production
        state: dump
        target: /tmp/db_backup_{{ ansible_date_time.iso8601_basic_short }}.sql
    
    - name: Upload backup to S3
      aws_s3:
        bucket: company-db-backups
        object: "backups/{{ ansible_date_time.iso8601_basic_short }}.sql"
        src: /tmp/db_backup_{{ ansible_date_time.iso8601_basic_short }}.sql
        mode: put
        aws_access_key: "{{ s3_creds.access_key }}"
        aws_secret_key: "{{ s3_creds.secret_key }}"
      
    - name: Cleanup local backup
      file:
        path: /tmp/db_backup_{{ ansible_date_time.iso8601_basic_short }}.sql
        state: absent
```

## Best Practices

### 1. Use IAM Roles When Possible

```yaml
# Instead of storing AWS credentials in Ansible
# Use EC2 instance profiles or ECS task roles
---
- name: Playbook with IAM role
  hosts: ec2_instances
  # No AWS credentials needed!
  vars:
    secret: "{{ lookup('amazon.aws.aws_secret', 'my-secret') }}"
```

### 2. Cache Secrets During Playbook Run

```yaml
---
- name: Cache secrets at playbook start
  hosts: localhost
  connection: local
  run_once: yes
  
  vars:
    cached_db_secret: "{{ lookup('amazon.aws.aws_secret', 'db-prod') }}"
  
  tasks:
    - name: Set fact for all hosts
      set_fact:
        db_credentials: "{{ cached_db_secret | from_json }}"
      delegate_to: "{{ item }}"
      delegate_facts: yes
      loop: "{{ groups['all'] }}"
```

### 3. Never Log Secrets

```yaml
- name: Use secret safely
  shell: echo "{{ secret }}" | my_command
  no_log: true  # Prevents secret from appearing in logs
  
- name: Debug without exposing secrets
  debug:
    msg: "Secret loaded successfully"
  when: secret is defined
```

### 4. Validate Secrets Before Use

```yaml
- name: Fetch and validate secret
  set_fact:
    db_config: "{{ lookup('amazon.aws.aws_secret', 'database') | from_json }}"
  
- name: Validate required fields
  assert:
    that:
      - db_config.host is defined
      - db_config.username is defined
      - db_config.password is defined
    fail_msg: "Database secret is missing required fields"
```

### 5. Use Different Secrets Per Environment

```yaml
---
- name: Environment-specific secrets
  hosts: all
  vars:
    secret_name: "database-{{ environment }}"
    db_creds: "{{ lookup('amazon.aws.aws_secret', secret_name) | from_json }}"
  
  tasks:
    - name: Use environment-specific credentials
      debug:
        msg: "Connected to {{ environment }} database"
```

## Troubleshooting

### Problem: "NoCredentialsError"

**Solution**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Or set explicitly in playbook
- name: Set AWS credentials
  set_fact:
    ansible_aws_access_key: "{{ lookup('env', 'AWS_ACCESS_KEY_ID') }}"
    ansible_aws_secret_key: "{{ lookup('env', 'AWS_SECRET_ACCESS_KEY') }}"
```

### Problem: "AccessDeniedException"

**Solution**: Ensure IAM policy allows `secretsmanager:GetSecretValue`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:*:*:key/*"
    }
  ]
}
```

### Problem: "ResourceNotFoundException"

**Solution**:
```yaml
- name: Handle missing secret
  block:
    - name: Try to fetch secret
      set_fact:
        my_secret: "{{ lookup('amazon.aws.aws_secret', 'my-secret') }}"
  rescue:
    - name: Use default value
      set_fact:
        my_secret: "default-value"
    - name: Log warning
      debug:
        msg: "Warning: Secret not found, using default"
```

## Security Considerations

1. **Never commit secrets** to version control
2. **Use `no_log: true`** for tasks handling secrets
3. **Restrict IAM permissions** to specific secrets
4. **Enable CloudTrail** logging for secret access
5. **Rotate secrets regularly** (30-90 days)
6. **Use KMS encryption** for secrets at rest
7. **Implement least privilege** access policies

## Performance Tips

- Cache secrets at playbook start
- Use `run_once: yes` for lookups
- Fetch secrets in parallel when possible
- Consider using dynamic inventory with cached secrets

## Additional Resources

- [Amazon.aws Collection Docs](https://docs.ansible.com/ansible/latest/collections/amazon/aws/)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [Ansible Vault vs AWS Secrets Manager](https://docs.ansible.com/ansible/latest/user_guide/vault.html)

---

**Repository**: [Cloud-Infrastructure-Automation](https://github.com/Botbynetz/Cloud-Infrastructure-Automation)
