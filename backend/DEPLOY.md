# CloudStack Deployment Backend

## Quick Deploy to Heroku

### Prerequisites
- [x] Heroku CLI installed
- [x] Heroku account created
- [x] Git installed

### Step 1: Initialize Git
```bash
cd "a:\website penjelasan cloud aws\deployment-backend"
git init
git add .
git commit -m "Initial backend deployment"
```

### Step 2: Login to Heroku
```bash
heroku login
```

### Step 3: Create Heroku App
```bash
heroku create cloudstack-deploy-api
```

### Step 4: Add PostgreSQL & Redis
```bash
heroku addons:create heroku-postgresql:mini
heroku addons:create heroku-redis:mini
```

### Step 5: Set Environment Variables
```bash
heroku config:set NODE_ENV=production
heroku config:set FRONTEND_URL=https://botbynetz.github.io/cloudstack-website
```

### Step 6: Deploy
```bash
git push heroku main
```

### Step 7: View Logs
```bash
heroku logs --tail
```

### Step 8: Open App
```bash
heroku open
```

## After Deployment

1. Copy Heroku app URL (e.g., https://cloudstack-deploy-api.herokuapp.com)
2. Update `deploy.js` line 650-700 with the Heroku URL
3. Commit and push frontend to GitHub Pages
4. Test deployment flow

## Cost Estimate
- Hobby Dyno: $7/month
- PostgreSQL Mini: $0 (free tier)
- Redis Mini: $0 (free tier)
- **Total: ~$7/month**

## Scaling
```bash
# Scale to 2 dynos for production
heroku ps:scale web=2
```

## Monitoring
```bash
# View real-time logs
heroku logs --tail

# Check dyno status
heroku ps

# Check addons
heroku addons
```