# 🧪 UnivAI Cloud - Quick Pre-Launch Testing Script

**Duration:** 10-15 minutes  
**Purpose:** Final smoke test before Nov 19, 2025 stakeholder presentation  
**Tester:** You (before demo)

---

## ✅ Test Sequence

### 1. Homepage Test (2 minutes)
```
1. Open browser (Chrome recommended)
2. Navigate to: file:///a:/Otomatisasi%20Infrastruktur%20Cloud/cloud-infra/index.html
   OR open index.html directly from folder

Expected:
✅ Page loads in <2 seconds
✅ UnivAI Cloud logo visible in header
✅ "UnivAI Cloud" text (NOT "CloudStack")
✅ Profile button (top-left)
✅ Hamburger menu button (top-right)
✅ No console errors (F12 → Console tab)

Actions:
- Click "View Modules" button → should scroll to modules section
- Click "Get Started" button → should scroll to contact form
- Scroll to footer → check links present
- Click navbar links: Value, Modules, ROI, Pricing, Contact (should scroll smoothly)
```

---

### 2. Navigation Test (2 minutes)
```
1. From index.html, click "Value Proposition" in navbar OR hamburger menu

Expected:
✅ Navigates to value.html
✅ Same header/footer design
✅ Profile button + hamburger menu present
✅ Page content displays correctly

Actions:
- Test hamburger menu (click 3 lines top-right)
- Click each menu item:
  → Home (index.html)
  → Value (value.html)
  → Modules (modules.html)
  → ROI (roi.html)
  → Pricing (pricing.html)
  → Contact (contact.html)
- Each page should load without errors
- Header/footer should look identical on all pages
```

---

### 3. Registration Test (3 minutes)
```
1. Click "Get Started" → redirects to pricing.html
2. Click "Get Started" under any tier → redirects to register.html

Expected at register.html:
✅ Page title: "Register - UnivAI Cloud Platform"
✅ Registration form with fields: Gmail, Company, Phone, Password, Confirm Password
✅ "Sign in with Google" button
✅ Link to "Already have account? Login here"
✅ No console errors

Actions:
- Enter test data:
  Gmail: test123@gmail.com
  Company: Test Company
  Phone: 081234567890
  Password: TestPass123!
  Confirm: TestPass123!
- Click "Create Account" button

Expected Result:
✅ Email verification modal appears
✅ Modal shows: "A verification link has been sent to test123@gmail.com"
✅ "Verify Now" and "Resend Email" buttons present
✅ No JavaScript errors in console

Note: Email won't actually send (backend not deployed), but modal should appear.
```

---

### 4. Login Test (2 minutes)
```
1. From register.html, click "Already have account? Login here"
   OR directly open auth.html

Expected at auth.html:
✅ Page title: "Login - UnivAI Cloud Platform"
✅ Login form with Email and Password fields
✅ "Sign in with Google" button
✅ "Forgot Password?" link
✅ Link to "Create new account"

Actions:
- Enter test credentials:
  Email: test@gmail.com
  Password: password123
- Click "Sign In" button

Expected Result (if account exists):
✅ Redirects to index.html (NOT deploy.html)
✅ Profile button shows user avatar/name
✅ Profile menu shows email address
✅ Badge shows "Free" plan

Expected Result (if account doesn't exist):
⚠️ Error message: "Invalid email or password"
```

---

### 5. Google Sign-In Test (2 minutes)
```
1. On auth.html, click "Sign in with Google" button

Expected:
✅ Google popup window opens
✅ Shows "Sign in with Google" dialog
✅ NO console errors or FedCM warnings
✅ NO "AbortError" messages in console

Actions:
- Complete Google authentication
- Allow UnivAI Cloud to access email

Expected Result:
✅ Popup closes
✅ Redirects to index.html (NOT deploy.html!)
✅ Profile button shows Google account name
✅ Profile menu shows Google email
✅ Badge shows "Free" plan
✅ Console is clean (no red errors)

If you see errors:
❌ FedCM deprecation warning → Check GOOGLE_SIGNIN_FIX.md
❌ Redirect to deploy.html → Check auth.js line 127
```

---

### 6. Profile Menu Test (1 minute)
```
1. After logging in, click profile button (top-left)

Expected:
✅ Dropdown menu appears with:
   - User avatar
   - User name (not "Guest User")
   - Email address
   - Plan badge (Free/Pro/Enterprise/Ultimate)
   - "My Account" link
   - "History" link → frontend/dashboard.html
   - "Settings" link
   - "Contact & Support" link
   - "Sign Out" button (if logged in)
   - "Sign In" button (if not logged in)

Actions:
- Click "History" → should navigate to frontend/dashboard.html
- Click "My Account" → should navigate to profile.html
- Click "Sign Out" → should logout and show "Sign In" option
```

---

### 7. Deploy Page Test (2 minutes)
```
1. Login first (if not logged in)
2. Navigate directly to: deploy.html

Expected:
✅ Page loads successfully
✅ Header shows "UnivAI Cloud Platform" (NOT "CloudStack")
✅ Console header shows "UnivAI Cloud Deployment Console"
✅ Footer shows "info@univaicloud.com" (NOT "@cloudstack.com")
✅ Tier badge shows user's plan (e.g., "Free")
✅ Configuration form present (AWS credentials, region, modules)

Actions:
- Check top-left logo → should say "UnivAI Cloud"
- Scroll to footer → should have correct email
- Check browser console (F12) → should be clean (no errors)
```

---

### 8. Mobile Responsiveness Test (2 minutes)
```
1. Open index.html in browser
2. Press F12 (DevTools)
3. Click "Toggle device toolbar" icon (or Ctrl+Shift+M)
4. Select "iPhone SE" or "Responsive" mode
5. Set width to 375px

Expected:
✅ Page scales to mobile width
✅ Hamburger menu visible (3 horizontal lines)
✅ Logo visible and centered
✅ Profile button visible
✅ Hero text readable (not cut off)
✅ Buttons large enough to tap (min 44px)
✅ Forms full-width

Actions:
- Click hamburger menu → side menu should slide in from right
- Click menu items → should navigate correctly
- Close menu (X button or overlay) → menu should close
- Scroll page → no horizontal scroll bar
- Test other pages: value.html, modules.html, pricing.html
```

---

### 9. Badge System Test (3 minutes)
```
1. Login to any account
2. Open browser console (F12)
3. Run these commands one at a time:

Test Free Tier:
localStorage.setItem('univai_user', JSON.stringify({email: 'test@test.com', name: 'Free User', plan: 'free'}));
location.reload();

Expected: Badge is gray with text "Free"

Test Professional Tier:
localStorage.setItem('univai_user', JSON.stringify({email: 'test@test.com', name: 'Pro User', plan: 'professional'}));
location.reload();

Expected: Badge is silver with check icon (✓)

Test Enterprise Tier:
localStorage.setItem('univai_user', JSON.stringify({email: 'test@test.com', name: 'Enterprise User', plan: 'enterprise'}));
location.reload();

Expected: Badge is gold with check icon (✓)

Test Ultimate Tier:
localStorage.setItem('univai_user', JSON.stringify({email: 'test@test.com', name: 'Ultimate User', plan: 'ultimate'}));
location.reload();

Expected: Badge has animated crown (👑) with gradient colors

All badges should appear in:
✅ Profile dropdown menu (top-left)
✅ Profile page
✅ Dashboard header (if applicable)
```

---

### 10. 404 Page Test (1 minute)
```
1. Navigate to a non-existent page: nonexistent.html
   OR type invalid URL in address bar

Expected:
✅ Shows custom 404 error page
✅ Large "404" text with gradient
✅ "Page Not Found" message
✅ "Back to Home" button → links to index.html
✅ "Go to Dashboard" button → links to frontend/dashboard.html
✅ "Popular Pages" section with links:
   - Enterprise Modules (modules.html)
   - Pricing Plans (pricing.html)
   - ROI Calculator (roi.html)
   - Contact Us (contact.html)
✅ UnivAI Cloud logo visible
✅ Clean design (no broken elements)
```

---

## 🚨 Critical Issues (Stop Launch If Found)

**If you encounter ANY of these, DO NOT PROCEED with launch:**

1. ❌ **CloudStack branding visible anywhere**
   - Logo says "CloudStack"
   - Header/footer says "CloudStack"
   - Email addresses contain "@cloudstack.com"
   → FIX: Check LAUNCH_READINESS.md section 1

2. ❌ **Google Sign-In console errors**
   - FedCM deprecation warnings
   - AbortError messages
   - "GSI_LOGGER" errors
   → FIX: See GOOGLE_SIGNIN_FIX.md

3. ❌ **Login redirects to deploy.html**
   - After login, lands on deploy.html instead of index.html
   → FIX: Check auth.js line 127

4. ❌ **Profile shows "Guest User" after login**
   - Logged in but profile menu still says "Guest User"
   → FIX: Check AUTH_FIX_SUMMARY.md

5. ❌ **Broken navigation links**
   - Clicking navbar links results in 404 errors
   - Pages don't load
   → FIX: Check file paths in each HTML file

6. ❌ **JavaScript errors on page load**
   - Red errors in console preventing page from working
   - Forms not submitting
   - Buttons not responding
   → FIX: Check console errors, review relevant .js files

---

## ✅ Minor Issues (OK to Launch With)

**These are acceptable for stakeholder demo:**

1. ⚠️ **Console.log statements visible**
   - Development logs in console
   - Doesn't affect functionality
   → Post-launch fix: Remove logs from auth.js, auth-guard.js

2. ⚠️ **Email verification doesn't send**
   - Modal appears but email doesn't arrive
   - Backend not deployed yet
   → Expected behavior, explain to stakeholders

3. ⚠️ **Payment gateway missing**
   - No payment forms yet
   - User explicitly confirmed post-launch
   → Expected, not required for demo

4. ⚠️ **Backend test page still has "CloudStack"**
   - backend/test.html may have old branding (FIXED in commit 5a9c430)
   - Not a public-facing page
   → Low priority

---

## 📊 Testing Results Template

**Date:** ___________  
**Tester:** ___________  
**Browser:** Chrome / Firefox / Safari / Edge  
**OS:** Windows / Mac / Linux  

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Homepage Test | ✅ PASS / ❌ FAIL | |
| 2 | Navigation Test | ✅ PASS / ❌ FAIL | |
| 3 | Registration Test | ✅ PASS / ❌ FAIL | |
| 4 | Login Test | ✅ PASS / ❌ FAIL | |
| 5 | Google Sign-In Test | ✅ PASS / ❌ FAIL | |
| 6 | Profile Menu Test | ✅ PASS / ❌ FAIL | |
| 7 | Deploy Page Test | ✅ PASS / ❌ FAIL | |
| 8 | Mobile Responsive Test | ✅ PASS / ❌ FAIL | |
| 9 | Badge System Test | ✅ PASS / ❌ FAIL | |
| 10 | 404 Page Test | ✅ PASS / ❌ FAIL | |

**Overall Status:** ✅ READY / ⚠️ MINOR ISSUES / ❌ NOT READY

**Critical Issues Found:** ___________  
**Minor Issues Found:** ___________  
**Recommendation:** LAUNCH / FIX FIRST / DELAY

---

## 🎯 Demo Day Checklist

**Day Before Launch (Nov 18):**
- [ ] Run this full testing script
- [ ] Fix any critical issues
- [ ] Take screenshots of all major pages
- [ ] Test on multiple browsers (Chrome, Firefox)
- [ ] Prepare backup laptop/internet connection
- [ ] Print LAUNCH_READINESS.md as backup reference

**Launch Day Morning (Nov 19):**
- [ ] Quick 5-minute smoke test (tests 1, 4, 5, 7)
- [ ] Clear browser cache
- [ ] Close unnecessary tabs/apps
- [ ] Check internet connection
- [ ] Have GitHub repo open (show commit history)
- [ ] Have TESTING_GUIDE.md open in tab

**During Demo:**
- [ ] Start with index.html (most polished page)
- [ ] Show Google Sign-In (most impressive feature)
- [ ] Demonstrate badge system (visual tier hierarchy)
- [ ] Show mobile responsive toggle (DevTools)
- [ ] Keep LAUNCH_READINESS.md open as reference

**If Something Breaks:**
- [ ] Have screenshots ready (backup visuals)
- [ ] Explain: "This is the development environment, backend deployment coming next week"
- [ ] Focus on design/UX instead of functionality
- [ ] Show GitHub commit history (prove active development)

---

## 📞 Emergency Contacts

**If you need help during testing:**

**Developer:** UnivAI Generation  
**Support:** info@univaicloud.com  
**Telegram:** @Liaaarina  
**WhatsApp:** +62 822-3120-4883  

**GitHub Issues:** https://github.com/Botbynetz/Cloud-Infrastructure-Automation/issues  
**Documentation:** See LAUNCH_READINESS.md, AUTH_FIX_SUMMARY.md, GOOGLE_SIGNIN_FIX.md

---

## 🚀 Final Notes

**Testing Philosophy:**
- 🎯 **Test the demo flow** - Focus on what stakeholders will see
- 🧪 **Test happy paths** - Not stress testing, just smoke testing
- 📸 **Take screenshots** - Evidence of working features
- 🐛 **Critical bugs only** - Don't delay launch for minor issues

**Demo Success = Working Auth + Clean Design + No Console Errors**

You've done extensive fixes already:
- ✅ Profile loading (commit a29c6d7)
- ✅ Google Sign-In (commit 0e2af89)
- ✅ Login redirect (commit df6d02d)
- ✅ Deploy branding (commit 972358f)
- ✅ User database keys (commit c6cfa0d)
- ✅ Header branding (commit 5a9c430)

The platform is **ready**. This testing script is just final validation.

---

**Good luck with the launch! 🚀**  
**You've built something amazing! 💪**
