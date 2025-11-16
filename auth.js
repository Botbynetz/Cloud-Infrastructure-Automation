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
    
    // Check if email already exists
    if (users.some(u => u.email === email)) {
        showAlert('Email already registered. Please login instead.', 'error');
        return;
    }
    
    // Create new user
    const newUser = {
        email,
        company,
        phone,
        password,
        tier: 'free',
        createdAt: Date.now(),
        deployments: 0
    };
    
    users.push(newUser);
    localStorage.setItem('cloudstack_users', JSON.stringify(users));
    
    showAlert('Account created successfully! Please login.', 'success');
    
    // Switch to login tab after 1.5 seconds
    setTimeout(() => {
        switchTab('login');
        document.getElementById('login-email').value = email;
    }, 1500);
});

// Check if redirected from pricing page
window.addEventListener('load', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const tier = urlParams.get('tier');
    const from = urlParams.get('from');
    
    if (from === 'pricing' && tier) {
        showAlert(`Please login or register to access ${tier.toUpperCase()} tier`, 'error');
    }
    
    // Initialize Google Sign-In
    setTimeout(() => {
        initGoogleSignIn();
    }, 500);
});