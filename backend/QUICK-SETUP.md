# Quick Setup - Email Service on Railway

## 🚀 Langkah Cepat Setup

### 1. Generate App-Specific Password Gmail

1. **Buka Google Account Security**: https://myaccount.google.com/security
2. **Enable 2-Step Verification** (jika belum aktif):
   - Scroll ke "2-Step Verification"
   - Klik "Get Started"
   - Follow petunjuk (butuh phone number)
3. **Generate App Password**:
   - Setelah 2-Step active, scroll ke "2-Step Verification" lagi
   - Klik "App passwords" (di bagian bawah)
   - Select app: **Mail**
   - Select device: **Other** → ketik "CloudStack Backend"
   - Klik **Generate**
   - **COPY** 16-digit password (format: xxxx xxxx xxxx xxxx)
   - **SIMPAN** password ini - tidak bisa dilihat lagi!

### 2. Set Environment Variables di Railway

1. **Login ke Railway**: https://railway.app
2. **Pilih project**: cloud-infrastructure-automation-production
3. **Klik tab "Variables"**
4. **Tambahkan 2 variables**:

```
EMAIL_USER=bynetzg@gmail.com
EMAIL_PASS=xxxxxxxxxxxx (16-digit app password tanpa spasi)
```

**PENTING**: 
- Hapus spasi dari app password (dari xxxx xxxx xxxx xxxx jadi xxxxxxxxxxxxxxxx)
- Jangan pakai password Gmail biasa!

### 3. Redeploy Backend

Setelah add variables:
1. Klik tab **"Deployments"**
2. Railway akan otomatis redeploy
3. Atau klik **"Deploy"** button untuk force redeploy

### 4. Verify Setup

Check logs di Railway:
- ✅ **Success**: `📧 Email service initialized successfully`
- ❌ **Error**: `Email service not configured` → environment variables salah

### 5. Test Email Service

Open: https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html

1. Klik tab **Register**
2. Isi form dengan Gmail
3. Klik **Create Account**
4. **CHECK EMAIL** → Harus terima verification code
5. Masukkan code → Success!

## 🔧 Troubleshooting

### "Invalid login credentials"
- Pastikan pakai **App-Specific Password** (bukan password Gmail biasa)
- Generate ulang app password
- Pastikan EMAIL_USER = bynetzg@gmail.com

### Email tidak terima
- Check **Spam/Junk** folder
- Tunggu 1-2 menit (bisa delay)
- Klik **"Resend Code"**
- Check Railway logs untuk error

### "Email service unavailable"
- Check Railway deployment status
- Verify environment variables sudah di-set
- Check backend health: https://cloud-infrastructure-automation-production.up.railway.app/health

## 📊 Current Status

- ✅ Backend code updated (nodemailer installed)
- ✅ Email service module created
- ✅ API endpoint ready: POST /api/send-verification-email
- ✅ Frontend integrated dengan backend
- ⏳ **NEXT**: Set EMAIL_USER & EMAIL_PASS di Railway
- ⏳ **THEN**: Redeploy dan test

## 🎯 Expected Result

Setelah setup selesai:
1. User register → Email otomatis terkirim
2. Email contains 6-digit code dengan professional HTML template
3. User input code → Account created
4. No more alert() popup - real email service! 📧

---

**Backend URL**: https://cloud-infrastructure-automation-production.up.railway.app
**Email Account**: bynetzg@gmail.com
**Status**: Ready to configure ⏳
