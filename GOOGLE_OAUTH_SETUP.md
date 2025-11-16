# Google OAuth Setup Guide

## 🔑 Cara Setup Google Sign-In untuk CloudStack Platform

### Step 1: Buat Google Cloud Project

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Klik **Select a project** → **New Project**
3. Nama project: `CloudStack Deployment Platform`
4. Klik **Create**

### Step 2: Enable Google Sign-In API

1. Di sidebar kiri, pilih **APIs & Services** → **Library**
2. Cari `Google+ API` atau `Google Identity`
3. Klik **Enable**

### Step 3: Create OAuth 2.0 Credentials

1. Di sidebar kiri, pilih **APIs & Services** → **Credentials**
2. Klik **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Jika diminta, configure consent screen:
   - User Type: **External**
   - App name: `CloudStack Platform`
   - User support email: (email Anda)
   - Developer contact: (email Anda)
   - Klik **Save and Continue**
   - Scopes: (skip, klik Save and Continue)
   - Test users: (skip, klik Save and Continue)

4. Kembali ke Create OAuth client ID:
   - Application type: **Web application**
   - Name: `CloudStack Web Client`
   
5. **Authorized JavaScript origins** (tambahkan 2 URL ini):
   ```
   https://botbynetz.github.io
   http://localhost:5500
   ```

6. **Authorized redirect URIs** (tambahkan 2 URL ini):
   ```
   https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html
   http://localhost:5500/auth.html
   ```

7. Klik **CREATE**

### Step 4: Copy Client ID

1. Setelah dibuat, akan muncul popup dengan **Client ID** dan **Client Secret**
2. **COPY** Client ID (format: `xxxxx.apps.googleusercontent.com`)
3. Client Secret **TIDAK PERLU** (kita pakai client-side OAuth)

### Step 5: Configure Website

1. Buka file `google-config.js`
2. Ganti `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com` dengan Client ID Anda:

```javascript
const GOOGLE_CONFIG = {
    CLIENT_ID: '123456789-abcdefg.apps.googleusercontent.com', // <-- PASTE DI SINI
    AUTHORIZED_DOMAINS: [
        'botbynetz.github.io',
        'localhost'
    ]
};
```

3. Save file
4. Commit dan push ke GitHub:
```bash
git add google-config.js
git commit -m "Configure Google OAuth Client ID"
git push origin main
```

### Step 6: Test Google Sign-In

1. Tunggu GitHub Pages deploy (1-2 menit)
2. Buka: https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html
3. Klik tombol **Continue with Google**
4. Pilih akun Google Anda
5. Jika berhasil, akan auto-login dan redirect ke deployment page

---

## 🔒 Security Notes

- Client ID **AMAN** untuk dipublikasikan (sudah dibatasi di authorized domains)
- Client Secret **TIDAK DIGUNAKAN** (client-side flow)
- User data dari Google: email, name, picture (tidak ada password)
- Auto-register user baru dengan tier FREE secara default

---

## 🐛 Troubleshooting

### Error: "redirect_uri_mismatch"
**Solusi**: Pastikan URL di Authorized redirect URIs **EXACT** sama dengan URL website Anda (termasuk `/auth.html`)

### Error: "popup_closed_by_user"
**Solusi**: User menutup popup Google. Coba lagi.

### Error: "idpiframe_initialization_failed"
**Solusi**: 
- Cek apakah browser memblokir cookies third-party
- Coba di Incognito mode
- Cek apakah Client ID sudah benar

### Google button tidak muncul
**Solusi**:
- Buka browser console (F12)
- Cek error message
- Pastikan `google-config.js` sudah diisi dengan Client ID yang benar
- Pastikan internet connection stabil (butuh load Google SDK)

---

## 📊 Google Sign-In Flow

```
User clicks "Continue with Google"
         ↓
Google OAuth popup appears
         ↓
User selects Google account
         ↓
Google returns JWT token with user info (email, name, picture)
         ↓
JavaScript decodes JWT token
         ↓
Check if user exists in localStorage
         ↓
    ┌─────────────┐
    │  Exists?    │
    └─────────────┘
         ↓
    ┌────┴────┐
   YES       NO
    │         │
    │         └→ Auto-register user (tier: FREE)
    │
    └→ Login existing user
         ↓
Store session in sessionStorage
         ↓
Redirect to deploy.html with tier parameter
```

---

## 🎯 Benefits Google Sign-In

✅ **No Password Management**: User tidak perlu ingat password  
✅ **Faster Registration**: 1-click registration  
✅ **Verified Email**: Email sudah terverifikasi oleh Google  
✅ **Better UX**: Familiar flow untuk semua orang  
✅ **Profile Picture**: Bisa tampilkan foto user dari Google  
✅ **Secure**: OAuth 2.0 standard dari Google  

---

## 💡 Tips

- Test di Incognito mode untuk simulasi new user
- Gunakan multiple Google accounts untuk test tier restrictions
- Check browser console untuk debug errors
- Google OAuth free dan unlimited users

---

**Need Help?** Check [Google Identity Documentation](https://developers.google.com/identity/gsi/web/guides/overview)
