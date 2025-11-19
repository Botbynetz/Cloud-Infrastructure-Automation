// ============================================
// UnivAI Cloud Platform - Authentication
// Rebuild with proper flow - November 2025
// ============================================

const API_URL = 'https://cloud-infrastructure-automation-production.up.railway.app';

// ============================================
// UI HELPER FUNCTIONS
// ============================================

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

function showAlert(message, type) {
    const alert = document.getElementById('alert');
    alert.textContent = message;
    alert.className = `alert alert-${type} show`;
    
    setTimeout(() => {
        hideAlert();
    }, 3000);
}

function hideAlert() {
    const alert = document.getElementById('alert');
    alert.classList.remove('show');
}

// ============================================
// GOOGLE SIGN-IN INTEGRATION
// ============================================

const GOOGLE_CLIENT_ID = typeof GOOGLE_CONFIG !== 'undefined' ? GOOGLE_CONFIG.CLIENT_ID : '';

function initGoogleSignIn() {
    if (!GOOGLE_CLIENT_ID || GOOGLE_CLIENT_ID === 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') {
        console.warn('⚠️ Google Client ID not configured');
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
        console.log('✓ Google Sign-In initialized');
    }
}

function loginWithGoogle() {
    if (typeof google !== 'undefined' && google.accounts) {
        google.accounts.id.prompt((notification) => {
            if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
                console.log('Google prompt not displayed, trying alternative method');
                renderGoogleButton();
            }
        });
    } else {
        showAlert('Loading Google Sign-In... Please wait.', 'error');
        setTimeout(() => {
            if (typeof google !== 'undefined') {
                initGoogleSignIn();
                loginWithGoogle();
            }
        }, 1000);
    }
}

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

function handleGoogleSignIn(response) {
    console.log('🔑 Google Sign-In callback triggered');
    
    try {
        const payload = parseJwt(response.credential);
        const email = payload.email;
        const name = payload.name;
        const picture = payload.picture;
        
        console.log('✓ Google user:', email);
        
        // Check if user exists in backend
        fetch(`${API_URL}/api/auth/check-user`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email })
        })
        .then(res => res.json())
        .then(data => {
            if (data.exists) {
                // User exists - login directly
                console.log('✓ User exists, logging in...');
                completeGoogleLogin(response.credential, email, name, picture, data.user);
            } else {
                // New user - auto-register
                console.log('→ New user, auto-registering...');
                registerGoogleUser(response.credential, email, name, picture);
            }
        })
        .catch(error => {
            console.error('Error checking user:', error);
            // Fallback to localStorage for offline
            handleGoogleLoginOffline(response.credential, email, name, picture);
        });
        
    } catch (error) {
        console.error('❌ Google Sign-In Error:', error);
        showAlert('Google Sign-In failed. Please try again.', 'error');
    }
}

function completeGoogleLogin(token, email, name, picture, userData) {
    // Store JWT token
    localStorage.setItem('univai_token', token);
    console.log('✓ Token stored');
    
    // Store user data
    localStorage.setItem('univai_user', JSON.stringify({
        email: email,
        name: name,
        company: userData?.company || name,
        phone: userData?.phone || 'Google Auth',
        tier: userData?.tier || 'free',
        plan: userData?.tier || 'free',
        picture: picture,
        authMethod: 'google',
        loginTime: Date.now()
    }));
    console.log('✓ User data stored');
    
    // Redirect immediately without alert
    console.log('🔄 Redirecting to index.html...');
    window.location.href = 'index.html';
}

function registerGoogleUser(token, email, name, picture) {
    fetch(`${API_URL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: email,
            company: name,
            phone: 'Google Auth',
            password: 'google_oauth_' + Date.now(),
            tier: 'free',
            authMethod: 'google'
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            console.log('✓ User registered successfully');
            completeGoogleLogin(token, email, name, picture, data.user);
        } else {
            showAlert(data.error || 'Registration failed', 'error');
        }
    })
    .catch(error => {
        console.error('Registration error:', error);
        // Fallback to localStorage
        handleGoogleLoginOffline(token, email, name, picture);
    });
}

function handleGoogleLoginOffline(token, email, name, picture) {
    console.log('📴 Using offline mode (localStorage)');
    
    const users = JSON.parse(localStorage.getItem('univai_users') || '[]');
    let user = users.find(u => u.email === email);
    
    if (!user) {
        user = {
            email: email,
            company: name,
            phone: 'Google Auth',
            password: 'google_oauth_' + Date.now(),
            tier: 'free',
            createdAt: Date.now(),
            authMethod: 'google'
        };
        users.push(user);
        localStorage.setItem('univai_users', JSON.stringify(users));
        console.log('✓ User created in localStorage');
    }
    
    completeGoogleLogin(token, email, name, picture, user);
}

// ============================================
// EMAIL/PASSWORD LOGIN
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    
    if (loginForm) {
        loginForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            console.log('📧 Email/Password login started');
            
            const email = document.getElementById('login-email').value.trim();
            const password = document.getElementById('login-password').value;
            
            if (!email || !password) {
                showAlert('Please fill in all fields', 'error');
                return;
            }
            
            try {
                const response = await fetch(`${API_URL}/api/auth/login`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password })
                });
                
                const data = await response.json();
                
                if (data.success && data.user && data.token) {
                    console.log('✓ Login successful');
                    
                    // Store token
                    localStorage.setItem('univai_token', data.token);
                    console.log('✓ Token stored:', data.token.substring(0, 20) + '...');
                    
                    // Store user data
                    localStorage.setItem('univai_user', JSON.stringify({
                        email: data.user.email,
                        name: data.user.company || data.user.name || email.split('@')[0],
                        company: data.user.company,
                        phone: data.user.phone,
                        tier: data.user.tier || 'free',
                        plan: data.user.tier || 'free',
                        authMethod: 'email',
                        loginTime: Date.now()
                    }));
                    console.log('✓ User data stored');
                    
                    // Redirect immediately without alert
                    console.log('🔄 Redirecting to index.html...');
                    window.location.href = 'index.html';
                } else {
                    showAlert(data.error || 'Invalid email or password', 'error');
                }
            } catch (error) {
                console.error('❌ Login error:', error);
                showAlert('Login failed. Please check your connection.', 'error');
            }
        });
    }
});

// ============================================
// REGISTRATION
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    const registerForm = document.getElementById('register-form');
    
    if (registerForm) {
        registerForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            console.log('📝 Registration started');
            
            const email = document.getElementById('register-email').value.trim();
            const company = document.getElementById('register-company').value.trim();
            const phone = document.getElementById('register-phone').value.trim();
            const password = document.getElementById('register-password').value;
            const confirmPassword = document.getElementById('register-confirm-password').value;
            
            // Validation
            if (!email || !company || !phone || !password || !confirmPassword) {
                showAlert('Please fill in all fields', 'error');
                return;
            }
            
            if (password !== confirmPassword) {
                showAlert('Passwords do not match', 'error');
                return;
            }
            
            if (password.length < 6) {
                showAlert('Password must be at least 6 characters', 'error');
                return;
            }
            
            try {
                const response = await fetch(`${API_URL}/api/auth/register`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        email,
                        company,
                        phone,
                        password,
                        tier: 'free'
                    })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    console.log('✓ Registration successful');
                    showAlert('Registration successful! Please login.', 'success');
                    
                    // Switch to login tab after 1.5 seconds
                    setTimeout(() => {
                        switchTab('login');
                        // Pre-fill email
                        document.getElementById('login-email').value = email;
                    }, 1500);
                } else {
                    showAlert(data.error || 'Registration failed', 'error');
                }
            } catch (error) {
                console.error('❌ Registration error:', error);
                showAlert('Registration failed. Please try again.', 'error');
            }
        });
    }
});

// ============================================
// UTILITY FUNCTIONS
// ============================================

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

// ============================================
// INITIALIZATION
// ============================================

window.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Auth page loaded');
    
    // Check if already logged in
    const token = localStorage.getItem('univai_token');
    const user = localStorage.getItem('univai_user');
    
    if (token && user) {
        console.log('✓ Already logged in, redirecting...');
        window.location.href = 'index.html';
        return;
    }
    
    // Check for redirect parameters
    const urlParams = new URLSearchParams(window.location.search);
    const from = urlParams.get('from');
    const tier = urlParams.get('tier');
    
    if (from === 'pricing' && tier) {
        showAlert(`Please login or register to access ${tier.toUpperCase()} tier`, 'error');
    }
    
    // Initialize Google Sign-In
    setTimeout(() => {
        initGoogleSignIn();
    }, 500);
    
    console.log('✓ Auth system ready');
});
