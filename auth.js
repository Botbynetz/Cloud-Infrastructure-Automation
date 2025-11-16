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

// Initialize Google Sign-In
function initGoogleSignIn() {
    if (!GOOGLE_CLIENT_ID || GOOGLE_CLIENT_ID === 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') {
        console.warn('Google Client ID not configured. Please set it in google-config.js');
        return;
    }
    
    if (typeof google !== 'undefined' && google.accounts) {
        google.accounts.id.initialize({
            client_id: GOOGLE_CLIENT_ID,
            callback: handleGoogleSignIn,
            auto_select: false
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
        const users = JSON.parse(localStorage.getItem('cloudstack_users') || '[]');
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
            localStorage.setItem('cloudstack_users', JSON.stringify(users));
            
            showAlert('Account created with Google! Logging in...', 'success');
        } else {
            showAlert('Welcome back! Logging in with Google...', 'success');
        }
        
        // Store session
        sessionStorage.setItem('cloudstack_user', JSON.stringify({
            email: user.email,
            company: user.company,
            phone: user.phone,
            tier: user.tier,
            picture: picture,
            authMethod: 'google',
            loginTime: Date.now()
        }));
        
        // Get redirect URL
        const urlParams = new URLSearchParams(window.location.search);
        const tier = urlParams.get('tier') || user.tier;
        
        setTimeout(() => {
            window.location.href = `deploy.html?tier=${tier}`;
        }, 1000);
        
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
    
    // Get stored users from localStorage
    const users = JSON.parse(localStorage.getItem('cloudstack_users') || '[]');
    
    // Find user
    const user = users.find(u => u.email === email && u.password === password);
    
    if (user) {
        // Store session
        sessionStorage.setItem('cloudstack_user', JSON.stringify({
            email: user.email,
            company: user.company,
            phone: user.phone,
            tier: user.tier || 'free',
            loginTime: Date.now()
        }));
        
        showAlert('Login successful! Redirecting...', 'success');
        
        // Get redirect URL (tier from pricing page)
        const urlParams = new URLSearchParams(window.location.search);
        const tier = urlParams.get('tier') || 'free';
        
        setTimeout(() => {
            window.location.href = `deploy.html?tier=${tier}`;
        }, 1000);
    } else {
        showAlert('Invalid email or password. Please try again.', 'error');
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
    
    // Get stored users
    const users = JSON.parse(localStorage.getItem('cloudstack_users') || '[]');
    
    // Check if user already exists
    if (users.find(u => u.email === email)) {
        showAlert('Email already registered. Please login instead.', 'error');
        return;
    }
    
    // Generate 6-digit verification code
    verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store pending user data (not yet saved to localStorage)
    pendingUser = {
        email: email,
        company: company,
        phone: phone,
        password: password,
        tier: 'free',
        createdAt: Date.now(),
        deployments: 0,
        verified: false,
        verificationCode: verificationCode
    };
    
    // Save to localStorage with expiry (10 minutes)
    const pendingKey = `pending_verification_${email}`;
    localStorage.setItem(pendingKey, JSON.stringify(pendingUser));
    setTimeout(() => {
        localStorage.removeItem(pendingKey);
    }, 10 * 60 * 1000); // 10 minutes
        tier: 'free',
        createdAt: Date.now(),
        deployments: 0,
        verified: false
    };
    
    // Send verification code via email
    try {
        const response = await fetch('https://cloud-infrastructure-automation-production.up.railway.app/api/send-verification-email', {
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
function verifyCode() {
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
        // Code is correct - save user to localStorage
        pendingUser.verified = true;
        
        const users = JSON.parse(localStorage.getItem('cloudstack_users') || '[]');
        users.push(pendingUser);
        localStorage.setItem('cloudstack_users', JSON.stringify(users));
        
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
        const response = await fetch('https://cloud-infrastructure-automation-production.up.railway.app/api/send-verification-email', {
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
        const users = JSON.parse(localStorage.getItem('cloudstack_users') || '[]');
        if (users.find(u => u.email === decodedEmail)) {
            showAlert('Email already verified. Please login.', 'success');
            switchTab('login');
            document.getElementById('login-email').value = decodedEmail;
            return;
        }
        
        // Save user to cloudstack_users
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
        localStorage.setItem('cloudstack_users', JSON.stringify(users));
        
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