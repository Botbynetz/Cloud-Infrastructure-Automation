# Email Service Setup Guide

Backend email service menggunakan Gmail SMTP untuk mengirim verification codes ke user saat registrasi.

## Prerequisites

1. **Gmail Account**: bynetzg@gmail.com
2. **2-Step Verification**: Harus diaktifkan di Google Account
3. **App-Specific Password**: Generated dari Google Account Security settings

## Setup Steps

### 1. Enable 2-Step Verification

1. Login ke Google Account: https://myaccount.google.com/
2. Pilih **Security** di sidebar
3. Cari **2-Step Verification**
4. Klik **Get Started** dan ikuti petunjuk
5. Verifikasi dengan phone number

### 2. Generate App-Specific Password

1. Setelah 2-Step Verification aktif, kembali ke **Security**
2. Scroll ke **2-Step Verification**
3. Klik **App passwords** (di bagian bawah 2-Step Verification section)
4. Pilih:
   - **Select app**: Mail
   - **Select device**: Other (Custom name)
   - **Enter name**: CloudStack Backend
5. Klik **Generate**
6. **COPY** 16-digit password yang muncul (format: xxxx xxxx xxxx xxxx)
7. **SIMPAN** password ini dengan aman - tidak bisa dilihat lagi!

### 3. Configure Railway Environment Variables

1. Login ke Railway: https://railway.app/
2. Pilih project: **cloud-infrastructure-automation-production**
3. Klik **Variables** tab
4. Tambahkan environment variables:

```bash
EMAIL_USER=bynetzg@gmail.com
EMAIL_PASS=your-16-digit-app-password-here
```

**IMPORTANT**: 
- Jangan gunakan password Gmail biasa!
- Hanya gunakan App-Specific Password
- Hapus spasi dari 16-digit password (xxxxxxxxxxxx)

### 4. Redeploy Backend

Setelah menambahkan environment variables:

1. Klik **Deployments** tab
2. Klik **Deploy** button (atau push code baru)
3. Tunggu deployment selesai
4. Check logs untuk konfirmasi:
   - ✅ `📧 Email service initialized successfully` → Setup berhasil
   - ⚠️ `Email service not configured` → Environment variables belum di-set

## Testing Email Service

### Test via cURL

```bash
curl -X POST https://cloud-infrastructure-automation-production.up.railway.app/api/send-verification-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "code": "123456"
  }'
```

**Expected Response (Success)**:
```json
{
  "success": true,
  "message": "Verification email sent successfully",
  "messageId": "<unique-message-id@gmail.com>"
}
```

**Expected Response (Error)**:
```json
{
  "success": false,
  "error": "Failed to send email",
  "details": "Invalid login credentials"
}
```

### Test via Frontend

1. Buka: https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html
2. Klik tab **Register**
3. Isi form dengan Gmail address
4. Klik **Create Account**
5. Check email inbox → Should receive verification code email
6. Enter code in modal → Account created

## Email Template Preview

Email yang dikirim memiliki:
- **Subject**: CloudStack - Email Verification Code
- **From**: CloudStack Platform <bynetzg@gmail.com>
- **Design**: Professional HTML template with:
  - Purple gradient header
  - Large 6-digit code display
  - Feature highlights
  - CloudStack branding
  - Footer with contact info

## Troubleshooting

### Error: "Invalid login credentials"

**Cause**: Wrong email or app password

**Solution**:
1. Verify EMAIL_USER = bynetzg@gmail.com
2. Regenerate app-specific password
3. Update EMAIL_PASS in Railway
4. Redeploy backend

### Error: "Authentication failed"

**Cause**: 2-Step Verification not enabled or using regular password

**Solution**:
1. Enable 2-Step Verification
2. Generate new app-specific password
3. Use app password (NOT regular password)

### Error: "Connection timeout"

**Cause**: Network issue or Gmail SMTP blocked

**Solution**:
1. Check Railway deployment logs
2. Verify no firewall blocking port 587/465
3. Try redeploying backend

### Email not received

**Possible Causes**:
1. Email in Spam folder → Check spam/junk
2. Wrong email address → Verify user entered correct Gmail
3. Gmail rate limiting → Wait a few minutes and retry
4. Email server delay → Can take up to 1 minute

**Solution**:
1. Check Spam/Junk folder
2. Use "Resend Code" button
3. Check Railway logs for errors

### Frontend shows "Email service unavailable"

**Cause**: Backend not responding or not deployed

**Solution**:
1. Check backend health: https://cloud-infrastructure-automation-production.up.railway.app/health
2. Should return: `{"status":"ok","version":"1.0.0"}`
3. If not responding, check Railway deployment status
4. Redeploy if needed

## Security Best Practices

✅ **DO**:
- Use App-Specific Password (NOT regular Gmail password)
- Store EMAIL_PASS in environment variables (never commit to code)
- Enable 2-Step Verification
- Monitor email send logs in Railway
- Rotate app password periodically (every 6 months)

❌ **DON'T**:
- Commit .env file to Git
- Share app password publicly
- Use regular Gmail password
- Disable 2-Step Verification
- Hard-code email credentials

## Rate Limits

Gmail SMTP has rate limits:
- **Free Gmail**: ~500 emails/day
- **Google Workspace**: ~2,000 emails/day

For production with high volume:
- Consider using SendGrid, AWS SES, or Mailgun
- Implement email queue system
- Add rate limiting on frontend

## Environment Variables Reference

| Variable | Value | Description |
|----------|-------|-------------|
| `EMAIL_USER` | bynetzg@gmail.com | Gmail account for sending emails |
| `EMAIL_PASS` | 16-digit password | App-specific password from Google |
| `NODE_ENV` | production | Environment mode |
| `PORT` | 3000 | Server port (Railway auto-assigns) |
| `FRONTEND_URL` | https://botbynetz.github.io/Cloud-Infrastructure-Automation/ | CORS whitelist |

## API Endpoints

### POST /api/send-verification-email

Send verification code email to user.

**Request Body**:
```json
{
  "email": "user@gmail.com",
  "code": "123456"
}
```

**Validation**:
- `email` required, valid email format
- `code` required, exactly 6 digits (numeric)

**Response (Success)**:
```json
{
  "success": true,
  "message": "Verification email sent successfully",
  "messageId": "<unique-id@gmail.com>"
}
```

**Response (Error)**:
```json
{
  "success": false,
  "error": "Invalid email format"
}
```

## Monitoring

Check Railway logs for email activity:

```bash
# Success log
✓ Verification email sent: <abc123@gmail.com>

# Error log
✗ Failed to send verification email: Invalid login credentials

# Startup log
📧 Email service initialized successfully
```

## Support

Jika ada masalah dengan email service:
1. Check Railway deployment logs
2. Verify environment variables set correctly
3. Test dengan cURL command
4. Regenerate app-specific password if needed
5. Contact Railway support jika masalah persist

---

**Last Updated**: November 16, 2025
**Backend URL**: https://cloud-infrastructure-automation-production.up.railway.app
**Email Account**: bynetzg@gmail.com
