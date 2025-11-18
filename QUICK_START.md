# 🚀 Quick Start Guide - Fixed & Secured

## Prerequisites
- Node.js 18+ installed
- Git installed
- Railway/Heroku account (for deployment)

## 1️⃣ Backend Setup (5 minutes)

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
```

**Edit `.env` and set these CRITICAL variables:**
```bash
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long-change-this
RECAPTCHA_SECRET_KEY=your_recaptcha_secret_key  # Optional in dev
RESEND_API_KEY=re_your_api_key_here             # For email service
FRONTEND_URL=https://botbynetz.github.io
```

**Start backend:**
```bash
npm start
```

Backend running at `http://localhost:3000` ✅

## 2️⃣ Frontend Setup (2 minutes)

Frontend is static HTML/CSS/JS - just open in browser!

**Option A: Local Testing**
```bash
# Use Live Server extension in VS Code
# or Python HTTP server
python -m http.server 8000
```

**Option B: Deploy to GitHub Pages**
1. Push to GitHub
2. Enable GitHub Pages in repository settings
3. Done! Access at `https://yourusername.github.io/repo-name`

## 3️⃣ Docker Setup (Alternative)

```bash
# Start all services (backend + Redis)
docker-compose up -d

# Check logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

## 4️⃣ Deploy to Railway (Production)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Create project
railway init

# Add environment variables in Railway dashboard
railway variables set JWT_SECRET=your-secret
railway variables set RECAPTCHA_SECRET_KEY=your-key
railway variables set RESEND_API_KEY=your-api-key
railway variables set FRONTEND_URL=https://botbynetz.github.io

# Deploy
railway up
```

## 5️⃣ Verify Installation

**Test backend health:**
```bash
curl http://localhost:3000/health
```

**Expected response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-11-18T...",
  "uptime": 123.45
}
```

## 6️⃣ Test Authentication Flow

**Register a user:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234",
    "company": "Test Co",
    "tier": "free"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234"
  }'
```

**Response includes JWT token:**
```json
{
  "success": true,
  "user": {...},
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## 🔧 Common Issues

### Issue: "JWT_SECRET required"
**Solution:** Set `JWT_SECRET` in `.env` file (minimum 32 characters)

### Issue: "Email service unavailable"
**Solution:** Set `RESEND_API_KEY` in `.env` or skip email features in development

### Issue: "CORS error"
**Solution:** Update `FRONTEND_URL` in backend `.env` to match your frontend domain

### Issue: bcrypt installation fails
**Solution:** 
```bash
npm install --build-from-source bcrypt
# or
npm install bcrypt@5.1.1
```

## 📊 What Changed from Original?

| Feature | Before | Now |
|---------|--------|-----|
| Authentication | localStorage only | JWT tokens with expiration |
| Security | Hardcoded secrets | Environment variables |
| Logging | console.log | Winston logger |
| Validation | Manual checks | express-validator |
| Rate Limiting | Loose (100/15min) | Strict (5/15min for auth) |
| Health Checks | None | /health + /readiness |
| Docker | Not supported | Full Docker support |
| CORS | Open (*) | Whitelist only |

## 📚 Next Steps

1. **Production Checklist:**
   - [ ] Set strong `JWT_SECRET` (32+ characters)
   - [ ] Configure reCAPTCHA keys
   - [ ] Set up email service (Resend)
   - [ ] Update `FRONTEND_URL` to production domain
   - [ ] Enable HTTPS
   - [ ] Configure monitoring (optional)

2. **Optional Enhancements:**
   - Migrate to PostgreSQL (currently using file-based storage)
   - Add unit tests
   - Set up CI/CD pipeline
   - Configure Sentry for error tracking

## 🆘 Need Help?

- Check logs: `docker-compose logs backend`
- Health check: `curl http://localhost:3000/health`
- Read: `SECURITY_FIXES.md` for detailed changes
- Issues: Create GitHub issue

---

**You're ready to go! 🎉**

Backend: `http://localhost:3000`  
Frontend: `http://localhost:8000` or GitHub Pages  
API Docs: See `backend/middleware/validator.js` for endpoints
