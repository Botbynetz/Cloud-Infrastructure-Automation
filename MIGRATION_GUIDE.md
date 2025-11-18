# 🔄 MIGRATION GUIDE - From Old to New Version

**Target Audience:** Existing users upgrading from the previous version  
**Time Required:** ~10 minutes  
**Downtime:** None (can run both versions in parallel during migration)

---

## 📊 WHAT CHANGED?

### Backend Changes
- ✅ JWT authentication instead of localStorage-only
- ✅ Input validation on all endpoints  
- ✅ Structured logging with Winston
- ✅ Environment-based configuration
- ✅ Fixed security vulnerabilities
- ✅ Added Docker support
- ✅ Health check endpoints

### Frontend Changes (Minimal)
- ⚠️ Must send JWT token in Authorization header
- ⚠️ Password requirements strengthened
- ✅ Can use new `frontend-config.js` for easier API calls

### Breaking Changes
1. JWT token required for protected endpoints
2. Password validation: min 8 chars + complexity
3. CORS: whitelist only in production
4. API response format includes `token` field

---

## 🚀 STEP-BY-STEP MIGRATION

### Phase 1: Backend Migration (5 minutes)

#### 1. Backup Current Data
```bash
# Backup user data
cp backend/data/users.json backend/data/users.json.backup

# Backup deployments
cp backend/data/deployments.json backend/data/deployments.json.backup
```

#### 2. Pull New Changes
```bash
git pull origin main
# Or download and extract new files
```

#### 3. Install New Dependencies
```bash
cd backend
npm install
```

**Expected new packages:**
- `winston@^3.11.0` - Logging
- `jsonwebtoken@^9.0.2` - JWT auth
- `express-validator@^7.0.1` - Input validation
- `bcrypt@^5.1.1` - Fixed version

#### 4. Update Environment Variables
```bash
# Copy new template
cp .env.example .env.new

# Migrate your settings
# OLD .env → NEW .env
```

**New required variables:**
```bash
# CRITICAL - Must set!
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long

# Existing (keep your values)
RESEND_API_KEY=re_xxxxx
RECAPTCHA_SECRET_KEY=xxxxx
FRONTEND_URL=https://yoursite.com
```

**Removed variables:**
```bash
# These are no longer used:
# API_KEY (replaced by JWT)
# TF_LOG (now in LOG_LEVEL)
# TERRAFORM_VERSION (not needed in backend)
```

#### 5. Migrate User Passwords
**IMPORTANT:** Old passwords are plain text, new version requires bcrypt hashing.

Run migration script:
```javascript
// backend/migrate-passwords.js
const bcrypt = require('bcrypt');
const fs = require('fs');

const users = JSON.parse(fs.readFileSync('data/users.json', 'utf8'));

async function migrate() {
    for (let user of users) {
        // Skip if already hashed (starts with $2b$)
        if (user.password.startsWith('$2b$')) continue;
        
        // Hash plain password
        user.password = await bcrypt.hash(user.password, 10);
        console.log(`Migrated user: ${user.email}`);
    }
    
    fs.writeFileSync('data/users.json', JSON.stringify(users, null, 2));
    console.log('✅ Migration complete!');
}

migrate();
```

Run it:
```bash
node backend/migrate-passwords.js
```

#### 6. Test Backend
```bash
npm start
```

Check health:
```bash
curl http://localhost:3000/health
```

Expected:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-11-18T...",
  "uptime": 123.45
}
```

### Phase 2: Frontend Migration (5 minutes)

#### Option A: Minimal Changes (Quickest)

Update only the authentication calls to include JWT token storage:

**In `auth.js`, after successful login:**
```javascript
// OLD:
localStorage.setItem('currentUser', JSON.stringify(data.user));

// NEW:
localStorage.setItem('auth_token', data.token);  // Add this line
localStorage.setItem('currentUser', JSON.stringify(data.user));
```

**In API calls that need authentication:**
```javascript
// OLD:
fetch('https://backend.com/api/endpoint', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
})

// NEW:
const token = localStorage.getItem('auth_token');
fetch('https://backend.com/api/endpoint', {
    method: 'POST',
    headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`  // Add this line
    },
    body: JSON.stringify(data)
})
```

#### Option B: Full Migration (Recommended)

Use the new `frontend-config.js`:

1. **Add to HTML files:**
```html
<script src="frontend-config.js"></script>
```

2. **Replace API calls:**
```javascript
// OLD:
const response = await fetch('https://hardcoded-backend.com/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
});
const data = await response.json();

// NEW:
const result = await apiCall(API_CONFIG.ENDPOINTS.LOGIN, {
    method: 'POST',
    body: JSON.stringify({ email, password })
});
const data = result.data;

// Token is automatically handled!
```

3. **Update token storage:**
```javascript
// After login/register:
localStorage.setItem('auth_token', data.token);
localStorage.setItem('univai_user', JSON.stringify(data.user));
```

#### Password Validation Update

Update registration form validation:

```javascript
// OLD:
if (password.length < 6) {
    showAlert('Password must be at least 6 characters', 'error');
    return;
}

// NEW:
if (password.length < 8) {
    showAlert('Password must be at least 8 characters', 'error');
    return;
}
if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(password)) {
    showAlert('Password must contain uppercase, lowercase, and number', 'error');
    return;
}
```

### Phase 3: Testing (2 minutes)

#### 1. Test User Registration
- Open registration page
- Try weak password → Should fail with clear message
- Use strong password (`Test1234`) → Should succeed
- Check localStorage for `auth_token`

#### 2. Test User Login
- Login with registered user
- Should receive JWT token
- Token should be stored in localStorage
- Dashboard/profile should load correctly

#### 3. Test Protected Endpoints
- Access user profile
- Check that Authorization header is sent
- Verify backend logs show successful requests

#### 4. Test Token Expiration
- Set JWT_EXPIRY to 1 minute in backend .env
- Restart backend
- Login and wait 61 seconds
- Try accessing protected endpoint
- Should redirect to login with "Token expired" message

---

## 🔄 ROLLBACK PLAN

If something goes wrong:

### Quick Rollback (2 minutes)

1. **Stop new backend:**
```bash
# Kill the process or
npm stop
```

2. **Restore old version:**
```bash
git checkout HEAD~1
cd backend
npm install
npm start
```

3. **Restore data backups:**
```bash
cp backend/data/users.json.backup backend/data/users.json
cp backend/data/deployments.json.backup backend/data/deployments.json
```

4. **Clear browser cache:**
```
localStorage.clear()
```

---

## 📋 POST-MIGRATION CHECKLIST

- [ ] Backend starts without errors
- [ ] Health endpoint returns OK
- [ ] Can register new user
- [ ] Can login existing user
- [ ] JWT token stored in localStorage
- [ ] Protected endpoints work with token
- [ ] Weak passwords rejected
- [ ] Rate limiting working (try 6 login attempts)
- [ ] Logs written to `backend/logs/combined.log`
- [ ] No console.log in production logs
- [ ] Frontend loads correctly
- [ ] Old users can still login (after password migration)
- [ ] Deployments still work
- [ ] Contact form still works

---

## 🆘 COMMON MIGRATION ISSUES

### Issue: "bcrypt version mismatch"
**Cause:** Old bcrypt version cached  
**Fix:**
```bash
rm -rf node_modules package-lock.json
npm install
```

### Issue: "JWT_SECRET required"
**Cause:** .env not updated  
**Fix:** Copy JWT_SECRET from .env.example, generate secure value

### Issue: "Invalid credentials" for old users
**Cause:** Passwords not migrated from plain text to hashed  
**Fix:** Run `migrate-passwords.js` script above

### Issue: Frontend shows "401 Unauthorized"
**Cause:** Token not being sent  
**Fix:** Check localStorage has `auth_token`, verify Authorization header in network tab

### Issue: "Token expired" immediately
**Cause:** Clock skew or wrong JWT_EXPIRY  
**Fix:** 
```bash
# In .env
JWT_EXPIRY=24h  # Not too short
```

### Issue: CORS errors in production
**Cause:** Frontend URL not whitelisted  
**Fix:** Add to backend .env:
```bash
FRONTEND_URL=https://youractualfrontend.com
```

---

## 📊 MIGRATION TIMELINE

### Development/Staging
- **Day 1:** Backend migration + testing
- **Day 2:** Frontend migration + testing
- **Day 3:** Integration testing
- **Day 4:** Stakeholder review
- **Day 5:** Production deployment

### Production (Zero Downtime)
1. Deploy new backend to new URL (e.g., `api-v2.example.com`)
2. Test new backend thoroughly
3. Update frontend to use new backend URL
4. Deploy frontend changes
5. Monitor for 24 hours
6. Decommission old backend

---

## 📞 SUPPORT

**Issues during migration?**

1. Check logs: `backend/logs/error.log`
2. Verify environment variables: `cat backend/.env`
3. Test health endpoint: `curl http://localhost:3000/health`
4. Review checklist: `VERIFICATION_CHECKLIST.md`
5. Read detailed fixes: `SECURITY_FIXES.md`

**Still stuck?**
- GitHub Issues: Create issue with error logs
- Emergency rollback: Follow "Rollback Plan" above

---

**Migration prepared by:** GitHub Copilot  
**Last updated:** November 18, 2025  
**Version:** 1.0.0 → 2.0.0 (security fixes)
