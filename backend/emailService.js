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
            subject: 'Verify your email address',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f6f8fa;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 20px;">
        <tr>
            <td align="center">
                <table width="100%" style="max-width: 600px; background-color: #ffffff; border-radius: 8px; border: 1px solid #d0d7de;" cellpadding="0" cellspacing="0">
                    
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 32px 24px 32px;">
                            <h1 style="margin: 0; font-size: 24px; font-weight: 600; color: #24292f;">CloudStack</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 0 32px 32px 32px;">
                            <p style="margin: 0 0 16px 0; font-size: 16px; color: #24292f;">Hi there,</p>
                            <p style="margin: 0 0 24px 0; font-size: 14px; color: #57606a; line-height: 1.5;">Please verify your email address by entering this code:</p>
                            
                            <!-- Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; border-radius: 6px; border: 1px solid #d0d7de; margin: 0 0 24px 0;">
                                <tr>
                                    <td style="padding: 24px; text-align: center;">
                                        <div style="font-size: 32px; font-weight: 700; color: #24292f; letter-spacing: 8px; font-family: 'Courier New', monospace;">${code}</div>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Button -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 24px 0;">
                                <tr>
                                    <td align="center">
                                        <a href="${verifyLink}" style="display: inline-block; background-color: #2da44e; color: #ffffff; text-decoration: none; padding: 12px 20px; border-radius: 6px; font-size: 14px; font-weight: 600;">Verify email address</a>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 0; font-size: 12px; color: #57606a; line-height: 1.5;">This code will expire in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="padding: 24px 32px; border-top: 1px solid #d0d7de; text-align: center;">
                            <p style="margin: 0; font-size: 12px; color: #57606a;">CloudStack • Enterprise Infrastructure Automation</p>
                        </td>
                    </tr>
                    
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
            `
        });

        if (error) {
            console.error('Resend error:', error);
            return { success: false, error: error.message };
        }

        console.log('Verification email sent successfully:', data);
        return { success: true, messageId: data.id };

    } catch (error) {
        console.error('Error sending verification email:', error);
        return { success: false, error: error.message };
    }
}

// Send password reset email
async function sendPasswordResetEmail(email, code) {
    try {
        const { data, error } = await resend.emails.send({
            from: 'CloudStack <noreply@resend.dev>',
            to: email,
            subject: 'Reset your password',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f6f8fa;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; padding: 40px 20px;">
        <tr>
            <td align="center">
                <table width="100%" style="max-width: 600px; background-color: #ffffff; border-radius: 8px; border: 1px solid #d0d7de;" cellpadding="0" cellspacing="0">
                    
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 32px 24px 32px;">
                            <h1 style="margin: 0; font-size: 24px; font-weight: 600; color: #24292f;">CloudStack</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 0 32px 32px 32px;">
                            <p style="margin: 0 0 16px 0; font-size: 16px; color: #24292f;">Hi there,</p>
                            <p style="margin: 0 0 24px 0; font-size: 14px; color: #57606a; line-height: 1.5;">We received a request to reset your password. Use this code to continue:</p>
                            
                            <!-- Code Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f6f8fa; border-radius: 6px; border: 1px solid #d0d7de; margin: 0 0 24px 0;">
                                <tr>
                                    <td style="padding: 24px; text-align: center;">
                                        <div style="font-size: 32px; font-weight: 700; color: #24292f; letter-spacing: 8px; font-family: 'Courier New', monospace;">${code}</div>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 0 0 16px 0; font-size: 12px; color: #57606a; line-height: 1.5;">This code will expire in 10 minutes. If you didn't request a password reset, you can safely ignore this email.</p>
                            
                            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fff8c5; border-radius: 6px; border: 1px solid #d4a72c; margin: 16px 0 0 0;">
                                <tr>
                                    <td style="padding: 16px;">
                                        <p style="margin: 0; font-size: 12px; color: #6f4e37; line-height: 1.5;"><strong>Security tip:</strong> Never share this code with anyone. CloudStack will never ask for your verification code.</p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="padding: 24px 32px; border-top: 1px solid #d0d7de; text-align: center;">
                            <p style="margin: 0; font-size: 12px; color: #57606a;">CloudStack • Enterprise Infrastructure Automation</p>
                        </td>
                    </tr>
                    
                </table>
            </td>
        </tr>
    </table>
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
