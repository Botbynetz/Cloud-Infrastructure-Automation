# 🧪 Testing Guide - Profile Badge & Authentication

## ⚡ Quick Test (1 minute)

### Step 1: Clear Old Data
1. Open browser DevTools (F12)
2. Go to **Console** tab
3. Run these commands:
```javascript
localStorage.clear()
sessionStorage.clear()
location.reload()
```

### Step 2: Test Login
1. Go to `auth.html` page
2. Login with your email/password
3. After redirect, open profile menu (top right)
4. ✅ Should show YOUR name and email (not "Guest User")
5. ✅ Should show badge matching your plan tier

### Step 3: Test Persistence
1. Close browser completely
2. Open browser again
3. Go to website
4. ✅ Should still be logged in
5. ✅ Profile should still show your data

### Step 4: Test Logout
1. Click logout from profile menu
2. ✅ Should redirect to auth page
3. ✅ Profile should show "Guest User" again

---

## 🔍 Detailed Badge Testing

### Test All Badge Tiers

Open browser console and run these to test each badge:

#### Test Free Plan Badge
```javascript
localStorage.setItem('univai_user', JSON.stringify({
    email: 'test@example.com',
    name: 'Test User',
    plan: 'free',
    tier: 'free'
}));
location.reload();
```
✅ Should show: Gray badge with "Free" text

#### Test Professional Plan Badge
```javascript
localStorage.setItem('univai_user', JSON.stringify({
    email: 'pro@example.com',
    name: 'Pro User',
    plan: 'professional',
    tier: 'professional'
}));
location.reload();
```
✅ Should show: Silver verified check icon

#### Test Enterprise Plan Badge
```javascript
localStorage.setItem('univai_user', JSON.stringify({
    email: 'enterprise@example.com',
    name: 'Enterprise User',
    plan: 'enterprise',
    tier: 'enterprise'
}));
location.reload();
```
✅ Should show: Gold verified check icon

#### Test Ultimate Plan Badge
```javascript
localStorage.setItem('univai_user', JSON.stringify({
    email: 'ultimate@example.com',
    name: 'Ultimate User',
    plan: 'ultimate',
    tier: 'ultimate'
}));
location.reload();
```
✅ Should show: Animated crown with floating effect and glow

---

## 🐛 Troubleshooting

### Problem: Still shows "Guest User"

**Solution 1: Clear cache**
```javascript
localStorage.clear()
sessionStorage.clear()
location.reload()
```

**Solution 2: Check login saved data**
```javascript
// After login, check if data exists:
console.log(localStorage.getItem('univai_user'));
// Should show: {"email":"...","name":"...","plan":"..."}
```

**Solution 3: Check for JavaScript errors**
- Open DevTools → Console tab
- Look for red error messages
- Most common: `Uncaught SyntaxError: Unexpected token`

### Problem: Badge not showing

**Check 1: Verify plan field exists**
```javascript
const user = JSON.parse(localStorage.getItem('univai_user'));
console.log('Plan:', user.plan); // Should NOT be undefined
```

**Check 2: Verify badge HTML exists**
```javascript
console.log(document.getElementById('planBadge'));
// Should show: <span class="plan-badge" id="planBadge"...>
```

**Check 3: Check badge update function**
```javascript
// Manually trigger badge update
updatePlanBadge('ultimate'); // Should update badge immediately
```

### Problem: Logout not working

**Check logout function:**
```javascript
// In console, try manual logout:
localStorage.removeItem('univai_user');
location.href = 'auth.html';
```

---

## ✅ Success Indicators

### Profile Menu Should Show:
1. ✅ User avatar (generated from name)
2. ✅ User's actual name (not "Guest User")
3. ✅ User's email address
4. ✅ Correct badge for plan tier
5. ✅ Badge animation (Ultimate tier only)

### After Login:
1. ✅ No redirect to auth.html on page refresh
2. ✅ Profile data persists across browser restarts
3. ✅ All pages show same user info

### After Logout:
1. ✅ Profile shows "Guest User"
2. ✅ Badge shows "Free" tier
3. ✅ Can access public pages only
4. ✅ Redirects to auth.html on protected pages

---

## 📊 DevTools Inspection

### Check localStorage (should have):
```
univai_user: {"email":"...","name":"...","plan":"..."}
```

### Check localStorage (should NOT have):
```
❌ cloudstack_user
❌ cloudstack_token
```

### Check sessionStorage (should be empty):
```
❌ No cloudstack_user
❌ No authentication data
```

---

## 🎨 Badge Visual Reference

| Tier | Badge Style | Icon | Color | Animation |
|------|-------------|------|-------|-----------|
| Free | Text badge | None | Gray (#9CA3AF) | None |
| Professional | Icon badge | ✓ verified | Silver (#C0C0C0) | None |
| Enterprise | Icon badge | ✓ verified | Gold (#FFD700) | None |
| Ultimate | Icon badge | 👑 crown | Gold (#FFD700) | Float + Glow |

---

## 🚀 Quick Commands Reference

```javascript
// View current user
JSON.parse(localStorage.getItem('univai_user'))

// Clear all auth data
localStorage.removeItem('univai_user');
localStorage.removeItem('univai_token');
localStorage.removeItem('currentUser');

// Force logout
localStorage.clear(); location.href = 'auth.html';

// Test specific badge tier
updatePlanBadge('ultimate'); // or 'enterprise', 'professional', 'free'

// Check if function exists
typeof updatePlanBadge === 'function' // Should be true
```
