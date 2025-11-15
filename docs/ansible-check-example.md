# Ansible Dry Run Example Output
# Generated for: dev environment
# Date: 2025-11-15

## Command
```bash
cd ansible
ansible-playbook -i inventory/dev/hosts playbook.yml --check --diff
```

## Example Output

```yaml
PLAY [Configure web servers] ***************************************************

TASK [Gathering Facts] *********************************************************
ok: [dev-web-server]

TASK [webserver : Update apt cache] ********************************************
changed: [dev-web-server]

TASK [webserver : Install required packages] ***********************************
changed: [dev-web-server] => (item=nginx)
changed: [dev-web-server] => (item=python3-pip)
changed: [dev-web-server] => (item=git)
changed: [dev-web-server] => (item=curl)

TASK [webserver : Ensure nginx is started and enabled] *************************
changed: [dev-web-server]

TASK [webserver : Create web directory] ****************************************
--- before
+++ after
@@ -1,4 +1,4 @@
 {
-    "path": "/var/www/html",
-    "state": "absent"
+    "path": "/var/www/cloud-infra",
+    "state": "directory"
 }

changed: [dev-web-server]

TASK [webserver : Deploy custom index.html] ************************************
--- before
+++ after: /home/ubuntu/.ansible/tmp/ansible-local-1234/tmpxyz/index.html.j2
@@ -0,0 +1,50 @@
+<!DOCTYPE html>
+<html lang="en">
+<head>
+    <meta charset="UTF-8">
+    <meta name="viewport" content="width=device-width, initial-scale=1.0">
+    <title>Cloud Infrastructure - dev</title>
+    <style>
+        body {
+            margin: 0;
+            padding: 0;
+            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
+            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
+            color: white;
+            display: flex;
+            justify-content: center;
+            align-items: center;
+            height: 100vh;
+        }
+        .container {
+            text-align: center;
+            padding: 40px;
+            background: rgba(255, 255, 255, 0.1);
+            border-radius: 20px;
+            backdrop-filter: blur(10px);
+            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
+        }
+        h1 {
+            font-size: 3em;
+            margin-bottom: 20px;
+        }
+        .badge {
+            display: inline-block;
+            padding: 10px 20px;
+            background: rgba(255, 255, 255, 0.2);
+            border-radius: 25px;
+            margin: 10px;
+        }
+    </style>
+</head>
+<body>
+    <div class="container">
+        <h1>🚀 Cloud Infrastructure</h1>
+        <div class="badge">Environment: dev</div>
+        <div class="badge">Region: ap-southeast-1</div>
+        <div class="badge">Project: cloud-infra</div>
+        <p>Deployed with Terraform + Ansible</p>
+    </div>
+</body>
+</html>

changed: [dev-web-server]

TASK [webserver : Configure nginx site] ****************************************
--- before
+++ after: /home/ubuntu/.ansible/tmp/ansible-local-1234/tmpxyz/nginx-site.conf.j2
@@ -0,0 +1,25 @@
+server {
+    listen 80;
+    listen [::]:80;
+    
+    server_name _;
+    
+    root /var/www/cloud-infra;
+    index index.html;
+    
+    location / {
+        try_files $uri $uri/ =404;
+    }
+    
+    location /health {
+        access_log off;
+        return 200 "healthy\n";
+        add_header Content-Type text/plain;
+    }
+    
+    # Security headers
+    add_header X-Frame-Options "SAMEORIGIN" always;
+    add_header X-Content-Type-Options "nosniff" always;
+    add_header X-XSS-Protection "1; mode=block" always;
+}

changed: [dev-web-server]

TASK [webserver : Enable nginx site] *******************************************
--- before
+++ after
@@ -1,4 +1,4 @@
 {
-    "dest": "/etc/nginx/sites-enabled/cloud-infra",
-    "state": "absent"
+    "dest": "/etc/nginx/sites-enabled/cloud-infra",
+    "src": "/etc/nginx/sites-available/cloud-infra",
+    "state": "link"
 }

changed: [dev-web-server]

TASK [webserver : Remove default nginx site] ***********************************
changed: [dev-web-server]

TASK [webserver : Test nginx configuration] ************************************
ok: [dev-web-server]

RUNNING HANDLER [webserver : reload nginx] *************************************
changed: [dev-web-server]

PLAY RECAP *********************************************************************
dev-web-server             : ok=11   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

## Summary
- **Total tasks**: 11
- **Changed**: 9 (in check mode, these would be applied)
- **OK**: 2 (already in desired state)
- **Failed**: 0
- **Duration**: ~15-20 seconds

## What Will Be Done
1. ✅ Update apt package cache
2. ✅ Install nginx, python3-pip, git, curl
3. ✅ Start and enable nginx service
4. ✅ Create web directory `/var/www/cloud-infra`
5. ✅ Deploy custom index.html with environment styling
6. ✅ Configure nginx virtual host
7. ✅ Enable the site
8. ✅ Remove default nginx site
9. ✅ Test nginx configuration
10. ✅ Reload nginx to apply changes

## Next Steps
1. Review the changes (--diff shows exact file changes)
2. Remove `--check` flag to apply changes for real
3. Access the website at `http://<EC2_PUBLIC_IP>`
