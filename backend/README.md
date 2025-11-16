# CloudStack Deployment Backend

Backend server untuk CloudStack infrastructure deployment platform dengan real-time WebSocket streaming.

## 🚀 Features

- **Real-time Deployment**: WebSocket-based streaming logs
- **Tier-based Access**: Free, Professional, Enterprise, Ultimate tiers
- **Module Validation**: Enforce tier limits and module availability
- **Terraform Execution**: Execute Terraform deployments on customer AWS accounts
- **Job Tracking**: PostgreSQL-based deployment history
- **Queue System**: Redis-backed job queue for concurrent deployments

## 📋 Prerequisites

- Node.js 18.x
- PostgreSQL (Heroku addon)
- Redis (Heroku addon)
- Terraform 1.6+

## 🛠️ Local Development

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Create `.env` file**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Run development server**:
   ```bash
   npm run dev
   ```

4. **Test WebSocket connection**:
   Open `test.html` in browser or use Socket.IO client

## 🚢 Heroku Deployment

### 1. Create Heroku App

```bash
# Login to Heroku
heroku login

# Create app
heroku create cloudstack-deployment-api

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:mini

# Add Redis addon
heroku addons:create heroku-redis:mini
```

### 2. Set Environment Variables

```bash
heroku config:set NODE_ENV=production
heroku config:set FRONTEND_URL=https://your-username.github.io/cloudstack-website
heroku config:set JWT_SECRET=$(openssl rand -base64 32)
heroku config:set API_KEY=$(openssl rand -base64 32)
```

### 3. Deploy

```bash
# Deploy to Heroku
git init
git add .
git commit -m "Initial backend deployment"
heroku git:remote -a cloudstack-deployment-api
git push heroku main

# Check logs
heroku logs --tail
```

### 4. Scale

```bash
# Scale web dynos
heroku ps:scale web=1

# For production with more traffic
heroku ps:scale web=2
```

## 📡 API Endpoints

### Health Check
```
GET /health
Response: { "status": "ok", "version": "1.0.0" }
```

### Get Deployment Status
```
GET /api/deploy/:jobId/status
Response: {
  "jobId": "uuid",
  "status": "running|completed|failed",
  "startTime": 1234567890,
  "endTime": 1234567890,
  "result": { ... }
}
```

### WebSocket Events

**Client → Server**:
- `deploy`: Start deployment
  ```javascript
  socket.emit('deploy', {
    awsAccessKey: 'AKIA...',
    awsSecretKey: 'secret',
    awsRegion: 'us-east-1',
    projectName: 'my-project',
    environment: 'production',
    modules: ['self-service-portal', 'observability'],
    tier: 'professional'
  });
  ```

**Server → Client**:
- `job-created`: Deployment job created
- `log`: Real-time log message
- `progress`: Progress update (0-100%)
- `module-status`: Module deployment status
- `complete`: Deployment finished successfully
- `error`: Error occurred

## 💰 Pricing Tiers

| Tier | Price | Max Modules | Max Deployments/mo |
|------|-------|-------------|-------------------|
| Free | $0 | 1 | 1 (one-time) |
| Professional | $299 | 3 | 10 |
| Enterprise | $999 | 7 | 50 |
| Ultimate | $2,499 | 10 | Unlimited |

## 🔐 Security

- Helmet.js for HTTP headers security
- CORS configured for trusted origins only
- Customer AWS credentials never stored (transmitted securely, used once)
- Rate limiting on API endpoints
- Input validation and sanitization

## 📊 Monitoring

- Morgan for HTTP request logging
- Heroku metrics dashboard
- Optional: Sentry for error tracking
- Optional: Datadog for APM

## 🧪 Testing

```bash
# Unit tests
npm test

# Load test
npm run load-test
```

## 🐛 Troubleshooting

**WebSocket connection fails**:
- Check CORS configuration in `server.js`
- Verify `FRONTEND_URL` env variable
- Check Heroku logs: `heroku logs --tail`

**Deployment timeouts**:
- Increase `DEPLOYMENT_TIMEOUT` env variable
- Check Terraform execution logs
- Verify AWS credentials

**Database errors**:
- Confirm PostgreSQL addon is active: `heroku addons`
- Check `DATABASE_URL` env variable
- Run migrations if needed

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `FRONTEND_URL` | Frontend URL for CORS | * |
| `DATABASE_URL` | PostgreSQL connection | (Heroku auto) |
| `REDIS_URL` | Redis connection | (Heroku auto) |
| `JWT_SECRET` | JWT signing key | - |
| `API_KEY` | API authentication | - |
| `MAX_CONCURRENT_DEPLOYMENTS` | Max parallel deploys | 5 |
| `DEPLOYMENT_TIMEOUT` | Timeout in ms | 3600000 |

## 🚀 Production Checklist

- [ ] Set all environment variables
- [ ] Enable Heroku PostgreSQL
- [ ] Enable Heroku Redis  
- [ ] Configure domain/SSL
- [ ] Set up monitoring (Sentry/Datadog)
- [ ] Configure backup strategy
- [ ] Set up CI/CD pipeline
- [ ] Load testing completed
- [ ] Security audit passed
- [ ] Documentation updated

## 📞 Support

For issues or questions:
- GitHub Issues: [Your Repo]
- Email: support@cloudstack.io

## 📄 License

MIT License - see LICENSE file

---

Built with ❤️ for CloudStack Infrastructure Platform