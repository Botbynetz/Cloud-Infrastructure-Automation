const { Resend } = require('resend');

// Initialize Resend with API key
const resend = new Resend(process.env.RESEND_API_KEY);

// Send verification code email
async function sendVerificationEmail(email, code) {
    try {
        // Create verification link
        const verifyLink = `https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html?verify=${code}&email=${encodeURIComponent(email)}`;
        
        const { data, error } = await resend.emails.send({
            from: 'CloudStack <noreply@resend.dev>',
            to: email,
            subject: 'CloudStack - Email Verification Code',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f7fa;
            line-height: 1.6;
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.08);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 50px 40px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            color: #ffffff;
            font-size: 32px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }
        .header p {
            margin: 10px 0 0 0;
            color: rgba(255,255,255,0.9);
            font-size: 16px;
        }
        .content {
            padding: 50px 40px;
        }
        .content h2 {
            color: #1a1a1a;
            font-size: 24px;
            margin: 0 0 16px 0;
            font-weight: 600;
        }
        .content p {
            color: #4a5568;
            font-size: 16px;
            line-height: 1.7;
            margin: 0 0 20px 0;
        }
        .code-container {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 16px;
            padding: 40px;
            text-align: center;
            margin: 35px 0;
            position: relative;
            box-shadow: 0 8px 24px rgba(102,126,234,0.3);
        }
        .code {
            font-size: 56px;
            font-weight: 800;
            color: #ffffff;
            letter-spacing: 12px;
            margin: 0;
            text-shadow: 0 4px 8px rgba(0,0,0,0.2);
            font-family: 'Courier New', monospace;
        }
        .code-label {
            color: rgba(255,255,255,0.95);
            font-size: 13px;
            margin: 15px 0 0 0;
            text-transform: uppercase;
            letter-spacing: 3px;
            font-weight: 600;
        }
        .copy-button {
            display: inline-block;
            background-color: rgba(255,255,255,0.2);
            color: #ffffff;
            padding: 12px 28px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            margin-top: 20px;
            border: 2px solid rgba(255,255,255,0.3);
            transition: all 0.3s ease;
            cursor: pointer;
        }
        .copy-button:hover {
            background-color: rgba(255,255,255,0.3);
            border-color: rgba(255,255,255,0.5);
        }
        .verify-button {
            display: inline-block;
            background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
            color: #ffffff;
            padding: 16px 40px;
            border-radius: 12px;
            text-decoration: none;
            font-size: 16px;
            font-weight: 700;
            margin: 25px 0;
            box-shadow: 0 6px 20px rgba(72,187,120,0.3);
            transition: all 0.3s ease;
        }
        .verify-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(72,187,120,0.4);
        }
        .button-container {
            text-align: center;
            margin: 30px 0;
        }
        .divider {
            text-align: center;
            margin: 30px 0;
            position: relative;
        }
        .divider::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 1px;
            background: #e2e8f0;
        }
        .divider span {
            background: #ffffff;
            padding: 0 20px;
            color: #a0aec0;
            font-size: 14px;
            position: relative;
            font-weight: 600;
        }
        .info-box {
            background: linear-gradient(135deg, #fef5e7 0%, #fdebd0 100%);
            border-left: 5px solid #f39c12;
            padding: 20px 24px;
            margin: 30px 0;
            border-radius: 8px;
        }
        .info-box p {
            margin: 0;
            color: #856404;
            font-size: 14px;
            line-height: 1.6;
        }
        .info-box strong {
            color: #744210;
        }
        .footer {
            background-color: #f8fafc;
            padding: 40px;
            text-align: center;
            border-top: 1px solid #e2e8f0;
        }
        .footer p {
            color: #718096;
            font-size: 14px;
            margin: 8px 0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }
        .footer a:hover {
            text-decoration: underline;
        }
        .features {
            margin: 30px 0;
            background-color: #f7fafc;
            padding: 30px;
            border-radius: 12px;
        }
        .feature-item {
            display: flex;
            align-items: center;
            margin: 14px 0;
            color: #2d3748;
            font-size: 15px;
        }
        .feature-icon {
            width: 24px;
            height: 24px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 14px;
            color: white;
            font-size: 13px;
            font-weight: bold;
            flex-shrink: 0;
        }
        @media only screen and (max-width: 600px) {
            .container {
                margin: 20px;
                border-radius: 12px;
            }
            .header {
                padding: 35px 25px;
            }
            .content {
                padding: 35px 25px;
            }
            .code {
                font-size: 42px;
                letter-spacing: 8px;
            }
            .code-container {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 CloudStack</h1>
            <p>Enterprise Infrastructure Automation</p>
        </div>
        
        <div class="content">
            <h2>Welcome to CloudStack!</h2>
            <p>Thank you for registering. We're excited to have you on board! 🎉</p>
            
            <p>To complete your registration, please verify your email address using one of the methods below:</p>
            
            <div class="button-container">
                <a href="${verifyLink}" class="verify-button">
                    ✓ Verify Email Instantly
                </a>
            </div>
            
            <div class="divider">
                <span>OR ENTER CODE MANUALLY</span>
            </div>
            
            <div class="code-container">
                <p class="code">${code}</p>
                <p class="code-label">Your Verification Code</p>
                <button class="copy-button" onclick="navigator.clipboard.writeText('${code}')">
                    📋 Copy Code
                </button>
            </div>
            
            <div class="info-box">
                <p><strong>⏱️ Important:</strong> This code expires in 10 minutes. For security reasons, please do not share this code with anyone. If you didn't request this verification, you can safely ignore this email.</p>
            </div>
            
            <h2 style="margin-top: 40px;">What's Next?</h2>
            <p>After verification, you'll unlock access to:</p>
            
            <div class="features">
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span><strong>One-Click Deployment</strong> - Deploy infrastructure in minutes</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span><strong>Real-Time Monitoring</strong> - Track deployment progress live</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span><strong>Enterprise Security</strong> - Bank-grade encryption & compliance</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span><strong>24/7 Support</strong> - Expert help whenever you need it</span>
                </div>
            </div>
            
            <p style="margin-top: 30px;">Need help? Our support team is here for you at <a href="mailto:support@cloudstack.com" style="color: #667eea; text-decoration: none; font-weight: 600;">support@cloudstack.com</a></p>
        </div>
        
        <div class="footer">
            <p><strong style="color: #2d3748;">CloudStack Platform</strong></p>
            <p>Powering Infrastructure Automation Worldwide</p>
            <p style="margin-top: 20px;">
                <a href="https://botbynetz.github.io/Cloud-Infrastructure-Automation/">Dashboard</a> • 
                <a href="mailto:info@cloudstack.com">Contact</a> • 
                <a href="https://botbynetz.github.io/Cloud-Infrastructure-Automation/pricing.html">Pricing</a>
            </p>
            <p style="margin-top: 25px; color: #a0aec0; font-size: 12px;">
                © 2025 CloudStack. All rights reserved.<br>
                This is an automated message, please do not reply to this email.
            </p>
        </div>
    </div>
</body>
</html>
            `,
            text: `
CloudStack - Email Verification Code

Welcome to CloudStack!

Your verification code is: ${code}

This code will expire in 10 minutes.

After verification, you'll get access to:
- One-click infrastructure deployment
- Real-time deployment monitoring
- Enterprise-grade security
- 24/7 technical support

If you didn't request this code, please ignore this email.

CloudStack Platform
Enterprise Infrastructure Automation
info@cloudstack.com
            `
        });
        
        if (error) {
            console.error('✗ Failed to send verification email:', error);
            return {
                success: false,
                error: error.message
            };
        }
        
        console.log('✓ Verification email sent via Resend:', data.id);
        
        return {
            success: true,
            messageId: data.id
        };
        
    } catch (error) {
        console.error('✗ Failed to send verification email:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

// Send password reset email
async function sendPasswordResetEmail(email, code) {
    try {
        const { data, error } = await resend.emails.send({
            from: 'CloudStack <noreply@resend.dev>',
            to: email,
            subject: 'CloudStack - Password Reset Code',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f7fa;
            line-height: 1.6;
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.08);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 50px 40px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            color: #ffffff;
            font-size: 32px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }
        .header p {
            margin: 10px 0 0;
            color: rgba(255, 255, 255, 0.9);
            font-size: 16px;
        }
        .content {
            padding: 50px 40px;
        }
        .content h2 {
            margin: 0 0 20px;
            color: #1a1a1a;
            font-size: 24px;
            font-weight: 700;
        }
        .content p {
            margin: 0 0 20px;
            color: #4a5568;
            font-size: 16px;
        }
        .code-container {
            background: linear-gradient(135deg, #e0e7ff 0%, #ddd6fe 100%);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
            border: 2px dashed #667eea;
        }
        .code {
            font-size: 56px;
            font-weight: 700;
            color: #5b21b6;
            letter-spacing: 12px;
            font-family: 'Courier New', monospace;
            margin: 0;
            user-select: all;
        }
        .copy-button {
            display: inline-block;
            margin-top: 15px;
            padding: 12px 30px;
            background: rgba(255, 255, 255, 0.9);
            color: #5b21b6;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            border: 2px solid #667eea;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .copy-button:hover {
            background: #ffffff;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        .warning-box {
            background: #fef2f2;
            border-left: 4px solid #ef4444;
            padding: 20px;
            border-radius: 8px;
            margin: 25px 0;
        }
        .warning-box p {
            margin: 0;
            color: #991b1b;
            font-size: 14px;
        }
        .warning-box strong {
            color: #7f1d1d;
        }
        .info-text {
            background: #f0f9ff;
            padding: 20px;
            border-radius: 8px;
            margin: 25px 0;
            border-left: 4px solid #0284c7;
        }
        .info-text p {
            margin: 0;
            color: #075985;
            font-size: 14px;
        }
        .footer {
            background: #f9fafb;
            padding: 30px 40px;
            text-align: center;
            border-top: 1px solid #e5e7eb;
        }
        .footer p {
            margin: 0 0 15px;
            color: #6b7280;
            font-size: 14px;
        }
        .footer a {
            color: #f59e0b;
            text-decoration: none;
            margin: 0 10px;
        }
        .footer a:hover {
            text-decoration: underline;
        }
        @media only screen and (max-width: 600px) {
            .container {
                margin: 20px;
            }
            .header, .content, .footer {
                padding: 35px 25px;
            }
            .code {
                font-size: 42px;
                letter-spacing: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 CloudStack</h1>
            <p>Enterprise Infrastructure Automation</p>
        </div>
        
        <div class="content">
            <h2>Reset Your Password</h2>
            <p>We received a request to reset your password for your CloudStack account. Use the verification code below to proceed:</p>
            
            <div class="code-container">
                <p class="code">${code}</p>
                <button class="copy-button" onclick="navigator.clipboard.writeText('${code}')">
                    📋 Copy Code
                </button>
            </div>
            
            <div class="warning-box">
                <p><strong>⚠️ Security Notice:</strong></p>
                <p>• This code expires in 10 minutes</p>
                <p>• If you didn't request this, please ignore this email</p>
                <p>• Never share this code with anyone</p>
            </div>
            
            <div class="info-text">
                <p><strong>💡 Didn't request this?</strong><br>
                If you didn't request a password reset, your account is still secure. You can safely ignore this email.</p>
            </div>
        </div>
        
        <div class="footer">
            <p>Need help? <a href="mailto:support@cloudstack.io">Contact Support</a></p>
            <p style="color: #9ca3af; font-size: 12px;">
                © 2024 CloudStack. All rights reserved.<br>
                Cloud Infrastructure Automation Platform
            </p>
        </div>
    </div>
</body>
</html>
            `
        });

        if (error) {
            console.error('Resend error:', error);
            return { success: false, error: error.message };
        }

        console.log('Password reset email sent successfully:', data);
        return { success: true, messageId: data.id };

    } catch (error) {
        console.error('Error sending password reset email:', error);
        return { success: false, error: error.message };
    }
}

// Verify Resend configuration
async function verifyEmailConfig() {
    try {
        if (!process.env.RESEND_API_KEY) {
            console.error('✗ RESEND_API_KEY not configured');
            return false;
        }
        console.log('✓ Resend email service ready');
        return true;
    } catch (error) {
        console.error('✗ Email service error:', error.message);
        return false;
    }
}

module.exports = {
    sendVerificationEmail,
    sendPasswordResetEmail,
    verifyEmailConfig
};
