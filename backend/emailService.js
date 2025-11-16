const nodemailer = require('nodemailer');

// Email configuration
const EMAIL_CONFIG = {
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER || 'bynetzg@gmail.com',
        pass: process.env.EMAIL_PASS // App-specific password dari Gmail
    }
};

// Create transporter
let transporter = null;

function createTransporter() {
    if (!transporter) {
        transporter = nodemailer.createTransport(EMAIL_CONFIG);
    }
    return transporter;
}

// Send verification code email
async function sendVerificationEmail(email, code) {
    try {
        const transport = createTransporter();
        
        const mailOptions = {
            from: {
                name: 'CloudStack Platform',
                address: EMAIL_CONFIG.auth.user
            },
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
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            color: #ffffff;
            font-size: 28px;
            font-weight: 700;
        }
        .content {
            padding: 40px 30px;
        }
        .content h2 {
            color: #333333;
            font-size: 22px;
            margin: 0 0 20px 0;
        }
        .content p {
            color: #666666;
            font-size: 16px;
            line-height: 1.6;
            margin: 0 0 20px 0;
        }
        .code-container {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
        }
        .code {
            font-size: 48px;
            font-weight: 700;
            color: #ffffff;
            letter-spacing: 8px;
            margin: 0;
            text-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .code-label {
            color: rgba(255,255,255,0.9);
            font-size: 14px;
            margin: 10px 0 0 0;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .info-box {
            background-color: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .info-box p {
            margin: 0;
            color: #555555;
            font-size: 14px;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
        }
        .footer p {
            color: #999999;
            font-size: 13px;
            margin: 5px 0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        .features {
            margin: 25px 0;
        }
        .feature-item {
            display: flex;
            align-items: center;
            margin: 12px 0;
            color: #666666;
            font-size: 14px;
        }
        .feature-icon {
            width: 20px;
            height: 20px;
            background-color: #667eea;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 12px;
            color: white;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 CloudStack Platform</h1>
        </div>
        
        <div class="content">
            <h2>Welcome to CloudStack!</h2>
            <p>Thank you for registering with CloudStack, the enterprise infrastructure automation platform.</p>
            
            <p>To complete your registration and verify your email address, please use the following verification code:</p>
            
            <div class="code-container">
                <p class="code">${code}</p>
                <p class="code-label">Verification Code</p>
            </div>
            
            <div class="info-box">
                <p><strong>⏱️ Important:</strong> This code will expire in 10 minutes. If you didn't request this code, please ignore this email.</p>
            </div>
            
            <p>After verification, you'll get access to:</p>
            
            <div class="features">
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span>One-click infrastructure deployment</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span>Real-time deployment monitoring</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span>Enterprise-grade security</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✓</span>
                    <span>24/7 technical support</span>
                </div>
            </div>
            
            <p>If you have any questions, feel free to reach out to our support team.</p>
        </div>
        
        <div class="footer">
            <p><strong>CloudStack Platform</strong></p>
            <p>Enterprise Infrastructure Automation</p>
            <p style="margin-top: 15px;">
                <a href="mailto:info@cloudstack.com">info@cloudstack.com</a> | 
                <a href="https://botbynetz.github.io/Cloud-Infrastructure-Automation/">Visit Dashboard</a>
            </p>
            <p style="margin-top: 20px; color: #aaaaaa;">
                © 2025 CloudStack. All rights reserved.
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
        };
        
        const info = await transport.sendMail(mailOptions);
        console.log('✓ Verification email sent:', info.messageId);
        
        return {
            success: true,
            messageId: info.messageId
        };
        
    } catch (error) {
        console.error('✗ Failed to send verification email:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

// Verify transporter configuration
async function verifyEmailConfig() {
    try {
        const transport = createTransporter();
        await transport.verify();
        console.log('✓ Email service ready');
        return true;
    } catch (error) {
        console.error('✗ Email service error:', error.message);
        return false;
    }
}

module.exports = {
    sendVerificationEmail,
    verifyEmailConfig
};
