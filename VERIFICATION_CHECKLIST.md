# ✅ POST-FIX VERIFICATION CHECKLIST

Run through this checklist after applying the fixes to ensure everything works correctly.

## 📋 PRE-DEPLOYMENT CHECKLIST

### 1. Dependencies Installation
- [ ] `cd backend && npm install` runs without errors
- [ ] bcrypt@5.1.1 installed successfully
- [ ] winston, jsonwebtoken, express-validator installed
- [ ] No vulnerability warnings (or only low-severity)

### 2. Environment Configuration
- [ ] `.env` file created from `.env.example`
- [ ] `JWT_SECRET` set (minimum 32 characters)
- [ ] `FRONTEND_URL` set to correct domain
- [ ] `RESEND_API_KEY` set (or skip if testing without email)
- [ ] `RECAPTCHA_SECRET_KEY` set (optional in dev)

### 3. Backend Startup
- [ ] `npm start` launches without errors
- [ ] Server binds to port 3000 (or custom PORT)
- [ ] No "JWT_SECRET required" error
- [ ] Logs directory created automatically
- [ ] Winston logger working (see timestamps in logs)

### 4. Health Checks
```bash
curl http://localhost:3000/health
```
- [ ] Returns `{"status":"ok","version":"1.0.0",...}`
- [ ] Response time < 100ms
- [ ] No errors in backend logs

```bash
curl http://localhost:3000/readiness
```
- [ ] Returns `{"status":"ready","services":{...}}`
- [ ] Email service status shown (ok or degraded)

### 5. Authentication Endpoints

**Register Test:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234","company":"Test","tier":"free"}'
```
- [ ] Returns `{"success":true,"user":{...},"token":"..."}`
- [ ] JWT token present in response
- [ ] User saved to `backend/data/users.json`
- [ ] Password is hashed (not plain text in file)
- [ ] Log entry created in `backend/logs/combined.log`

**Login Test:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234"}'
```
- [ ] Returns success with JWT token
- [ ] Token is different from registration token (or same if < 1 second)
- [ ] Login logged in `backend/logs/combined.log`

**Invalid Password Test:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"WrongPass"}'
```
- [ ] Returns `401` status code
- [ ] Error message: "Invalid credentials"
- [ ] Failed login logged with warning level

### 6. Input Validation

**Weak Password Test:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test2@example.com","password":"weak"}'
```
- [ ] Returns `400` status code
- [ ] Error about password requirements
- [ ] Validation error includes details

**Invalid Email Test:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"notanemail","password":"Test1234"}'
```
- [ ] Returns `400` status code
- [ ] Error message about invalid email

### 7. Rate Limiting

**Auth Rate Limit Test:**
Run this curl command 6 times quickly:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"wrong"}'
```
- [ ] First 5 requests return 401 (invalid credentials)
- [ ] 6th request returns 429 (too many requests)
- [ ] Error message about rate limiting

### 8. JWT Token Protection

**Get token first:**
```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234"}' | jq -r '.token')
```

**Test protected endpoint WITHOUT token:**
```bash
curl http://localhost:3000/api/auth/user?email=test@example.com
```
- [ ] Returns `401` Unauthorized
- [ ] Error: "Access token is required"

**Test protected endpoint WITH token:**
```bash
curl http://localhost:3000/api/auth/user?email=test@example.com \
  -H "Authorization: Bearer $TOKEN"
```
- [ ] Returns `200` with user data
- [ ] User data matches registration

### 9. Logging Verification
- [ ] `backend/logs/combined.log` file exists
- [ ] `backend/logs/error.log` file exists (may be empty if no errors)
- [ ] Logs are JSON formatted with timestamps
- [ ] Request/response logged with duration
- [ ] No sensitive data in logs (passwords, tokens)

Check log entry format:
```bash
tail -n 1 backend/logs/combined.log | jq
```
- [ ] Contains `timestamp`, `level`, `message` fields
- [ ] Metadata includes useful context

### 10. CORS Configuration

**Test from allowed origin:**
```bash
curl -H "Origin: https://botbynetz.github.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:3000/api/auth/login -v
```
- [ ] Response includes `Access-Control-Allow-Origin` header
- [ ] Status 200 or 204

**Test from disallowed origin (production only):**
```bash
curl -H "Origin: https://evil.com" \
  -X OPTIONS http://localhost:3000/api/auth/login -v
```
- [ ] In production: Should be blocked
- [ ] In development: May be allowed (check NODE_ENV)

### 11. Docker (Optional)

**Build test:**
```bash
docker-compose build
```
- [ ] Backend image builds without errors
- [ ] No security vulnerabilities in base image
- [ ] Final image size < 200MB

**Run test:**
```bash
docker-compose up -d
docker-compose logs backend
```
- [ ] Backend container starts successfully
- [ ] Health check passes after 5 seconds
- [ ] Redis container running
- [ ] Can access http://localhost:3000/health

**Cleanup:**
```bash
docker-compose down
```

### 12. Error Handling

**Trigger 404:**
```bash
curl http://localhost:3000/nonexistent
```
- [ ] Returns `404` status
- [ ] JSON response: `{"success":false,"error":"Endpoint not found"}`

**Trigger 500 (if possible):**
- [ ] Errors logged with stack trace in `error.log`
- [ ] Client receives generic error (not stack trace)
- [ ] In production: "Internal server error"
- [ ] In development: May include error details

### 13. Contact Form

```bash
curl -X POST http://localhost:3000/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","message":"Test message long enough for validation"}'
```
- [ ] Returns success message
- [ ] Submission logged in `combined.log`
- [ ] Email and name sanitized (trimmed)

**Short message test:**
```bash
curl -X POST http://localhost:3000/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@test.com","message":"Short"}'
```
- [ ] Returns `400` error
- [ ] Message about minimum length requirement

---

## 🎯 SUCCESS CRITERIA

For the fixes to be considered successful:

- ✅ **All Critical**: 13/13 checks in sections 1-4 pass
- ✅ **All Security**: 7/7 checks in sections 5-7 pass
- ✅ **All Features**: 6/6 checks in sections 8-13 pass

**Total: 26/26 checks should pass** ✅

---

## 🐛 TROUBLESHOOTING

### Issue: npm install fails
```bash
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Issue: bcrypt won't compile
```bash
npm install --build-from-source bcrypt@5.1.1
```

### Issue: Port 3000 already in use
```bash
# Change in .env
PORT=3001

# Or kill existing process
# Windows:
netstat -ano | findstr :3000
taskkill /PID <pid> /F

# Linux/Mac:
lsof -ti:3000 | xargs kill
```

### Issue: JWT_SECRET not set error
Edit `.env` and add:
```bash
JWT_SECRET=your-super-secret-key-minimum-32-characters-long-for-security
```

### Issue: Logs not created
```bash
mkdir -p backend/logs
chmod 755 backend/logs
```

---

## 📊 RESULTS TRACKING

Date: ___________  
Tester: ___________  

**Summary:**
- Checks Passed: __ / 26
- Checks Failed: __
- Blockers: __
- Notes: ___________

**Sign-off:**
- [ ] Ready for staging deployment
- [ ] Ready for production deployment
- [ ] Needs additional work

---

**Last Updated:** November 18, 2025
