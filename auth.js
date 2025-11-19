// Authentication JavaScript

// Switch between login and register tabs
function switchTab(tab) {
    const tabs = document.querySelectorAll('.auth-tab');
    const forms = document.querySelectorAll('.auth-form');
    
    tabs.forEach(t => t.classList.remove('active'));
    forms.forEach(f => f.classList.remove('active'));
    
    if (tab === 'login') {
        tabs[0].classList.add('active');
        forms[0].classList.add('active');
    } else {
        tabs[1].classList.add('active');
        forms[1].classList.add('active');
    }
    
    hideAlert();
}

// Toggle password visibility
function togglePassword(inputId) {
    const input = document.getElementById(inputId);
    const icon = input.parentElement.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

// Show alert message
function showAlert(message, type) {
    const alert = document.getElementById('alert');
    alert.textContent = message;
    alert.className = `alert alert-${type} show`;
    
    setTimeout(() => {
        hideAlert();
    }, 5000);
}

// Hide alert
function hideAlert() {
    const alert = document.getElementById('alert');
    alert.classList.remove('show');
}

// Google Sign-In Configuration
const GOOGLE_CLIENT_ID = typeof GOOGLE_CONFIG !== 'undefined' ? GOOGLE_CONFIG.CLIENT_ID : '';

// Initialize Google Sign-In with new Identity Services (Fix FedCM warning)
function initGoogleSignIn() {
    if (!GOOGLE_CLIENT_ID || GOOGLE_CLIENT_ID === 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') {
        console.warn('Google Client ID not configured. Please set it in google-config.js');
        return;
    }
    
    if (typeof google !== 'undefined' && google.accounts) {
        google.accounts.id.initialize({
            client_id: GOOGLE_CLIENT_ID,
            callback: handleGoogleSignIn,
            auto_select: false,
            cancel_on_tap_outside: false,
            itp_support: true
        });
    }
}

// Handle Google Sign-In Response
function handleGoogleSignIn(response) {
    try {
        // Decode JWT token
        const payload = parseJwt(response.credential);
        
        const email = payload.email;
        const name = payload.name;
        const picture = payload.picture;
        
        // Check if user exists in localStorage
        const users = JSON.parse(localStorage.getItem('univai_users') || '[]');
        let user = users.find(u => u.email === email);
        
        if (!user) {
            // Auto-register new Google user
            user = {
                email: email,
                company: name,
                phone: 'Google Auth',
                password: 'google_oauth_' + Date.now(), // Random password for Google users
                tier: 'free',
                createdAt: Date.now(),
                deployments: 0,
                authMethod: 'google',
                picture: picture
            };
            
            users.push(user);
            localStorage.setItem('univai_users', JSON.stringify(users));
            
            showAlert('Account created with Google! Logging in...', 'success');
        } else {
            showAlert('Welcome back! Logging in with Google...', 'success');
        }
        
        // Store session in localStorage for persistence
        localStorage.setItem('univai_user', JSON.stringify({
            email: user.email,
            name: user.company,
            company: user.company,
            phone: user.phone,
            tier: user.tier,
            plan: user.tier, // For badge system compatibility
            picture: picture,
            authMethod: 'google',
            loginTime: Date.now()
        }));
        console.log('✓ Google user data stored');
        
        // Get redirect URL
        const urlParams = new URLSearchParams(window.location.search);
        const tier = urlParams.get('tier') || user.tier;
        
        // Redirect immediately (no delay needed)
        console.log('🔄 Redirecting to index.html...');
        window.location.href = 'index.html';
        
    } catch (error) {
        console.error('Google Sign-In Error:', error);
        showAlert('Google Sign-In failed. Please try again.', 'error');
    }
}

// Parse JWT token
function parseJwt(token) {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    } catch (e) {
        console.error('JWT Parse Error:', e);
        return null;
    }
}

// Login with Google - trigger Google Sign-In prompt
function loginWithGoogle() {
    if (typeof google !== 'undefined' && google.accounts) {
        google.accounts.id.prompt((notification) => {
            if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
                // Fallback: render button
                renderGoogleButton();
            }
        });
    } else {
        // Google Sign-In not loaded yet, show info
        showAlert('Loading Google Sign-In... Please wait and try again.', 'error');
        setTimeout(() => {
            if (typeof google !== 'undefined') {
                initGoogleSignIn();
                loginWithGoogle();
            }
        }, 1000);
    }
}

// Render Google Sign-In button (alternative method)
function renderGoogleButton() {
    const buttonDiv = document.createElement('div');
    buttonDiv.id = 'google-signin-button';
    buttonDiv.style.display = 'flex';
    buttonDiv.style.justifyContent = 'center';
    buttonDiv.style.margin = '20px 0';
    
    document.querySelector('.auth-form.active').appendChild(buttonDiv);
    
    if (typeof google !== 'undefined' && google.accounts) {
        google.accounts.id.renderButton(
            buttonDiv,
            { 
                theme: "outline", 
                size: "large",
                width: 400,
                text: "continue_with",
                shape: "rectangular"
            }
        );
    }
}

// Login Form Handler
document.getElementById('login-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    
    // Login via backend API (bcrypt password verification + JWT)
    try {
        const response = await apiCall('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                password: password
            })
        });

        const data = await response.json();
        
        if (data.success && data.user) {
            // Store JWT token (IMPORTANT!)
            if (data.token) {
                localStorage.setItem('univai_token', data.token);
                console.log('✓ Token stored:', data.token.substring(0, 20) + '...');
            }
            
            // Store user session in localStorage for persistence
            localStorage.setItem('currentUser', JSON.stringify(data.user));
            localStorage.setItem('univai_user', JSON.stringify({
                email: data.user.email,
                name: data.user.company || data.user.name || email.split('@')[0],
                company: data.user.company,
                phone: data.user.phone,
                tier: data.user.tier || 'free',
                plan: data.user.tier || 'free', // For badge system compatibility
                loginTime: Date.now()
            }));
            console.log('✓ User data stored');
            
            showAlert('Login successful! Redirecting...', 'success');
            
            // Redirect to homepage immediately (no delay needed)
            console.log('🔄 Redirecting to index.html...');
            window.location.href = 'index.html';
        } else {
            showAlert(data.error || 'Invalid email or password. Please try again.', 'error');
        }
    } catch (error) {
        console.error('Login error:', error);
        showAlert('Login failed. Please try again.', 'error');
    }
});

// Register Form Handler
let pendingUser = null; // Store pending user data for verification
let verificationCode = null; // Store generated verification code

document.getElementById('register-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('register-email').value;
    const company = document.getElementById('register-company').value;
    const phone = document.getElementById('register-phone').value;
    const password = document.getElementById('register-password').value;
    const confirm = document.getElementById('register-confirm').value;
    
    // Validate Gmail
    if (!email.includes('@gmail.com')) {
        showAlert('Please use a Gmail address (@gmail.com)', 'error');
        return;
    }
    
    // Validate password match
    if (password !== confirm) {
        showAlert('Passwords do not match!', 'error');
        return;
    }
    
    // Validate password strength
    if (password.length < 8) {
        showAlert('Password must be at least 8 characters long', 'error');
        return;
    }
    
    // Generate 6-digit verification code
    verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Get reCAPTCHA token
    let recaptchaToken = null;
    try {
        if (typeof grecaptcha !== 'undefined') {
            recaptchaToken = await grecaptcha.execute('6LcM7Q4sAAAAALl0ky_lqzQYtsaKcOZSnAROggpN', {action: 'register'});
        }
    } catch (error) {
        console.log('reCAPTCHA not available, continuing without it');
    }
    
    // Store pending user data temporarily
    pendingUser = {
        email: email,
        company: company,
        phone: phone,
        password: password,
        tier: 'free',
        verificationCode: verificationCode
    };
    
    // Save to localStorage with expiry (10 minutes)
    const pendingKey = `pending_verification_${email}`;
    localStorage.setItem(pendingKey, JSON.stringify(pendingUser));
    setTimeout(() => {
        localStorage.removeItem(pendingKey);
    }, 10 * 60 * 1000); // 10 minutes
    
    // Register user in backend (password will be hashed)
    try {
        const registerResponse = await apiCall('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                password: password,
                company: company,
                phone: phone,
                tier: 'free',
                recaptchaToken: recaptchaToken
            })
        });

        const registerData = await registerResponse.json();
        
        if (!registerData.success) {
            showAlert(registerData.error || 'Registration failed', 'error');
            return;
        }
        
        // Store JWT token (IMPORTANT!)
        if (registerData.token) {
            localStorage.setItem('univai_token', registerData.token);
        }
    } catch (error) {
        console.error('Error registering user:', error);
        showAlert('Failed to register. Please try again.', 'error');
        return;
    }
    
    // Send verification code via email
    try {
        const response = await apiCall('/api/send-verification-email', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: email,
                code: verificationCode
            })
        });
        
        const result = await response.json();
        
        if (!response.ok || !result.success) {
            throw new Error(result.error || 'Failed to send email');
        }
        
        console.log('✓ Verification email sent:', result.messageId);
        
        // Show verification modal
        document.getElementById('verificationEmail').textContent = email;
        document.getElementById('verificationModal').classList.add('show');
        
        // Setup code inputs after modal is shown
        setupCodeInputs();
        
        // Focus first input after a short delay
        setTimeout(() => {
            document.getElementById('code1').focus();
        }, 100);
        
        showAlert('Verification code sent to your email!', 'success');
        
    } catch (error) {
        console.error('Failed to send verification email:', error);
        
        // Fallback: show code in alert for testing
        alert(`⚠️ Email service unavailable. Use this code for testing:\n\n${verificationCode}\n\n(In production, this will be sent via email)`);
        
        // Show verification modal anyway
        document.getElementById('verificationEmail').textContent = email;
        document.getElementById('verificationModal').classList.add('show');
        
        // Setup code inputs after modal is shown
        setupCodeInputs();
        
        // Focus first input after a short delay
        setTimeout(() => {
            document.getElementById('code1').focus();
        }, 100);
        
        showAlert('Please enter the verification code', 'info');
    }
});

// Setup Verification Code Input Handling
function setupCodeInputs() {
    const codeInputs = document.querySelectorAll('.code-input');
    
    codeInputs.forEach((input, index) => {
        // Remove old listeners by cloning
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
    });
    
    // Re-query after cloning
    const inputs = document.querySelectorAll('.code-input');
    
    inputs.forEach((input, index) => {
        input.addEventListener('input', function(e) {
            if (this.value.length === 1) {
                if (index < inputs.length - 1) {
                    inputs[index + 1].focus();
                }
            }
        });
        
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Backspace' && this.value === '') {
                if (index > 0) {
                    inputs[index - 1].focus();
                }
            }
        });
        
        // Only allow numbers
        input.addEventListener('keypress', function(e) {
            if (!/[0-9]/.test(e.key)) {
                e.preventDefault();
            }
        });
    });
}

// Verify Code Function
async function verifyCode() {
    const code1 = document.getElementById('code1').value;
    const code2 = document.getElementById('code2').value;
    const code3 = document.getElementById('code3').value;
    const code4 = document.getElementById('code4').value;
    const code5 = document.getElementById('code5').value;
    const code6 = document.getElementById('code6').value;
    
    const enteredCode = code1 + code2 + code3 + code4 + code5 + code6;
    
    if (enteredCode.length !== 6) {
        showAlert('Please enter the complete 6-digit code', 'error');
        return;
    }
    
    if (enteredCode === verificationCode) {
        // Code is correct - verify user in backend
        try {
            const response = await apiCall('/api/auth/verify-email', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    email: pendingUser.email
                })
            });

            const data = await response.json();
            
            if (data.success) {
                showAlert('Email verified successfully! You can now login.', 'success');
                
                // Close modal
                document.getElementById('verificationModal').classList.remove('show');
                
                // Clear inputs
                codeInputs.forEach(input => input.value = '');
                
                // Switch to login tab after 1.5 seconds
                setTimeout(() => {
                    switchTab('login');
                    document.getElementById('login-email').value = pendingUser.email;
                }, 1500);
                
                // Clear pending data
                pendingUser = null;
                verificationCode = null;
            } else {
                showAlert('Verification failed. Please try again.', 'error');
            }
        } catch (error) {
            console.error('Error verifying email:', error);
            showAlert('Failed to verify email. Please try again.', 'error');
        }
    } else {
        showAlert('Invalid verification code. Please try again.', 'error');
        // Clear inputs
        codeInputs.forEach(input => input.value = '');
        document.getElementById('code1').focus();
    }
}

// Resend Code Function
async function resendCode() {
    if (!pendingUser) {
        showAlert('Please register first', 'error');
        return;
    }
    
    // Generate new code
    verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Send verification code via email
    try {
        const response = await apiCall('/api/send-verification-email', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: pendingUser.email,
                code: verificationCode
            })
        });
        
        const result = await response.json();
        
        if (!response.ok || !result.success) {
            throw new Error(result.error || 'Failed to send email');
        }
        
        console.log('✓ New verification email sent:', result.messageId);
        showAlert('New verification code sent to your email!', 'success');
        
    } catch (error) {
        console.error('Failed to resend verification email:', error);
        
        // Fallback: show code in alert
        alert(`⚠️ Email service unavailable. New code for testing:\n\n${verificationCode}`);
        showAlert('New code generated (check console for testing)', 'info');
    }
    
    // Clear inputs
    const inputs = document.querySelectorAll('.code-input');
    inputs.forEach(input => input.value = '');
    document.getElementById('code1').focus();
}

// Check if redirected from pricing page or email verification link
window.addEventListener('load', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const tier = urlParams.get('tier');
    const from = urlParams.get('from');
    const verifyCode = urlParams.get('verify');
    const verifyEmail = urlParams.get('email');
    
    // Handle email verification link
    if (verifyCode && verifyEmail) {
        handleEmailVerification(verifyCode, verifyEmail);
        return;
    }
    
    if (from === 'pricing' && tier) {
        showAlert(`Please login or register to access ${tier.toUpperCase()} tier`, 'error');
    }
    
    // Initialize Google Sign-In
    setTimeout(() => {
        initGoogleSignIn();
    }, 500);
});

// Handle email verification from link
async function handleEmailVerification(code, email) {
    try {
        // Decode email
        const decodedEmail = decodeURIComponent(email);
        
        // Find pending user by email from localStorage (if exists)
        const pendingKey = `pending_verification_${decodedEmail}`;
        const pendingData = localStorage.getItem(pendingKey);
        
        if (!pendingData) {
            showAlert('Verification session expired. Please register again.', 'error');
            switchTab('register');
            return;
        }
        
        const userData = JSON.parse(pendingData);
        
        // Verify the code matches
        if (userData.verificationCode !== code) {
            showAlert('Invalid verification code. Please try again.', 'error');
            switchTab('register');
            return;
        }
        
        // Check if already verified
        const users = JSON.parse(localStorage.getItem('univai_users') || '[]');
        if (users.find(u => u.email === decodedEmail)) {
            showAlert('Email already verified. Please login.', 'success');
            switchTab('login');
            document.getElementById('login-email').value = decodedEmail;
            return;
        }
        
        // Save user to univai_users
        const newUser = {
            email: userData.email,
            company: userData.company,
            phone: userData.phone,
            password: userData.password,
            tier: 'free',
            createdAt: Date.now(),
            deployments: 0,
            verified: true
        };
        
        users.push(newUser);
        localStorage.setItem('univai_users', JSON.stringify(users));
        
        // Remove pending verification
        localStorage.removeItem(pendingKey);
        
        // Show success and switch to login
        showAlert('✅ Email verified successfully! You can now login.', 'success');
        
        setTimeout(() => {
            switchTab('login');
            document.getElementById('login-email').value = decodedEmail;
            
            // Clear URL parameters
            window.history.replaceState({}, document.title, window.location.pathname);
        }, 1500);
        
    } catch (error) {
        console.error('Verification error:', error);
        showAlert('Verification failed. Please try again.', 'error');
        switchTab('register');
    }
}

// ============= FORGOT PASSWORD FUNCTIONS =============

let forgotPasswordData = {
    email: '',
    verificationCode: ''
};

function showForgotPasswordModal() {
    document.getElementById('forgotPasswordModal').style.display = 'flex';
    // Reset to step 1
    document.getElementById('forgotPasswordStep1').style.display = 'block';
    document.getElementById('forgotPasswordStep2').style.display = 'none';
    document.getElementById('forgotPasswordStep3').style.display = 'none';
    document.getElementById('forgotPasswordSubtitle').textContent = 'Enter your email to receive a verification code';
    document.getElementById('forgotPasswordEmail').value = '';
}

function closeForgotPasswordModal() {
    document.getElementById('forgotPasswordModal').style.display = 'none';
    // Clear all inputs
    document.getElementById('forgotPasswordEmail').value = '';
    for (let i = 1; i <= 6; i++) {
        document.getElementById(`resetCode${i}`).value = '';
    }
    document.getElementById('newPassword').value = '';
    document.getElementById('confirmNewPassword').value = '';
}

async function requestPasswordReset() {
    const email = document.getElementById('forgotPasswordEmail').value.trim();
    
    if (!email) {
        alert('Please enter your email address');
        return;
    }
    
    // Check if email exists
    const users = JSON.parse(localStorage.getItem('univai_users')) || [];
    const userExists = users.find(u => u.email === email);
    
    if (!userExists) {
        alert('Email not found. Please check your email or register a new account.');
        return;
    }
    
    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    forgotPasswordData.email = email;
    forgotPasswordData.verificationCode = code;
    
    // Save to localStorage with expiry
    const resetData = {
        email: email,
        code: code,
        createdAt: Date.now()
    };
    localStorage.setItem(`password_reset_${email}`, JSON.stringify(resetData));
    
    // Set expiry (10 minutes)
    setTimeout(() => {
        localStorage.removeItem(`password_reset_${email}`);
    }, 10 * 60 * 1000);
    
    try {
        // Send email via backend
        const response = await apiCall('/api/send-password-reset-email', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email, code })
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Move to step 2
            document.getElementById('forgotPasswordStep1').style.display = 'none';
            document.getElementById('forgotPasswordStep2').style.display = 'block';
            document.getElementById('forgotPasswordSubtitle').innerHTML = `We've sent a 6-digit code to<br><span class="verification-email">${email}</span>`;
            
            // Setup code inputs
            setupResetCodeInputs();
        } else {
            alert('Failed to send verification code. Please try again.');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Failed to send email. Please check your connection and try again.');
    }
}

function setupResetCodeInputs() {
    const inputs = [];
    for (let i = 1; i <= 6; i++) {
        const input = document.getElementById(`resetCode${i}`);
        inputs.push(input);
        
        input.addEventListener('input', function(e) {
            if (e.target.value.length === 1) {
                if (i < 6) {
                    document.getElementById(`resetCode${i + 1}`).focus();
                }
            }
        });
        
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Backspace' && e.target.value === '') {
                if (i > 1) {
                    document.getElementById(`resetCode${i - 1}`).focus();
                }
            }
        });
        
        input.addEventListener('paste', function(e) {
            e.preventDefault();
            const pasteData = e.clipboardData.getData('text').slice(0, 6);
            for (let j = 0; j < pasteData.length; j++) {
                if (j < 6) {
                    document.getElementById(`resetCode${j + 1}`).value = pasteData[j];
                }
            }
            if (pasteData.length === 6) {
                document.getElementById('resetCode6').focus();
            }
        });
    }
}

function verifyResetCode() {
    let code = '';
    for (let i = 1; i <= 6; i++) {
        const digit = document.getElementById(`resetCode${i}`).value;
        if (!digit) {
            alert('Please enter all 6 digits');
            return;
        }
        code += digit;
    }
    
    // Verify code
    const resetKey = `password_reset_${forgotPasswordData.email}`;
    const resetData = JSON.parse(localStorage.getItem(resetKey));
    
    if (!resetData) {
        alert('Verification code expired. Please request a new one.');
        closeForgotPasswordModal();
        return;
    }
    
    if (resetData.code !== code) {
        alert('Invalid verification code. Please try again.');
        return;
    }
    
    // Move to step 3
    document.getElementById('forgotPasswordStep2').style.display = 'none';
    document.getElementById('forgotPasswordStep3').style.display = 'block';
    document.getElementById('forgotPasswordSubtitle').textContent = 'Enter your new password';
}

function resetPassword() {
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmNewPassword').value;
    
    if (!newPassword || newPassword.length < 8) {
        alert('Password must be at least 8 characters');
        return;
    }
    
    if (newPassword !== confirmPassword) {
        alert('Passwords do not match');
        return;
    }
    
    // Update password in backend
    apiCall('/api/auth/reset-password', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            email: forgotPasswordData.email,
            newPassword: newPassword
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Remove reset data
            localStorage.removeItem(`password_reset_${forgotPasswordData.email}`);
            
            // Close modal and show success
            closeForgotPasswordModal();
            alert('✅ Password reset successfully! You can now login with your new password.');
            
            // Switch to login tab
            switchTab('login');
            document.getElementById('login-email').value = forgotPasswordData.email;
        } else {
            alert(data.error || 'Failed to reset password. Please try again.');
        }
    })
    .catch(error => {
        console.error('Password reset error:', error);
        alert('Failed to reset password. Please try again.');
    });
}

async function resendPasswordResetCode() {
    // Generate new code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    forgotPasswordData.verificationCode = code;
    
    // Update localStorage
    const resetData = {
        email: forgotPasswordData.email,
        code: code,
        createdAt: Date.now()
    };
    localStorage.setItem(`password_reset_${forgotPasswordData.email}`, JSON.stringify(resetData));
    
    try {
        const response = await apiCall('/api/send-password-reset-email', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email: forgotPasswordData.email, code })
        });
        
        const result = await response.json();
        
        if (result.success) {
            alert('✅ New verification code sent!');
        } else {
            alert('Failed to resend code. Please try again.');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Failed to resend email. Please check your connection.');
    }
}
