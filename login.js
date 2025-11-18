// Login Page JavaScript

// Show alert message
function showAlert(message, type) {
    const alert = document.getElementById('alert');
    alert.textContent = message;
    alert.className = `alert ${type}`;
    alert.style.display = 'block';
    
    setTimeout(() => {
        alert.style.display = 'none';
    }, 5000);
}

// Toggle password visibility
function togglePassword(inputId) {
    const input = document.getElementById(inputId);
    const icon = event.target;
    
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

// Google Sign-In Configuration
const GOOGLE_CLIENT_ID = typeof GOOGLE_CONFIG !== 'undefined' ? GOOGLE_CONFIG.CLIENT_ID : '';

// Initialize Google Sign-In
function initGoogleSignIn() {
    if (!GOOGLE_CLIENT_ID || GOOGLE_CLIENT_ID === 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') {
        console.warn('Google Client ID not configured');
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
                password: 'google_oauth_' + Date.now(),
                tier: 'free',
                createdAt: Date.now(),
                deployments: 0,
                authMethod: 'google',
                picture: picture
            };
            
            users.push(user);
            localStorage.setItem('univai_users', JSON.stringify(users));
        }
        
        // Store session in localStorage for persistence
        localStorage.setItem('univai_user', JSON.stringify({
            email: user.email,
            name: user.company || user.name || user.email.split('@')[0],
            company: user.company,
            phone: user.phone,
            tier: user.tier,
            plan: user.tier, // For badge system compatibility
            picture: picture,
            authMethod: 'google',
            loginTime: Date.now()
        }));
        
        showAlert('Login successful! Redirecting...', 'success');
        
        setTimeout(() => {
            window.location.href = 'index.html';
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
                showAlert('Please enable popups or try again', 'error');
            }
        });
    } else {
        showAlert('Loading Google Sign-In... Please wait', 'error');
        setTimeout(() => {
            if (typeof google !== 'undefined') {
                initGoogleSignIn();
                loginWithGoogle();
            }
        }, 1000);
    }
}

// Email/Password Login Handler
document.getElementById('loginForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    // Get users from localStorage
    const users = JSON.parse(localStorage.getItem('univai_users') || '[]');
    const user = users.find(u => u.email === email && u.password === password);
    
    if (user) {
        // Store session in localStorage for persistence
        localStorage.setItem('univai_user', JSON.stringify({
            email: user.email,
            name: user.company || user.name || user.email.split('@')[0],
            company: user.company,
            phone: user.phone,
            tier: user.tier,
            plan: user.tier, // For badge system compatibility
            authMethod: 'email',
            loginTime: Date.now()
        }));
        
        showAlert('Login successful! Redirecting...', 'success');
        
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 1000);
    } else {
        showAlert('Invalid email or password. Please try again.', 'error');
    }
});

// Initialize Google Sign-In on page load
window.addEventListener('load', function() {
    // Check if already logged in
    const currentUser = localStorage.getItem('univai_user');
    if (currentUser) {
        window.location.href = 'index.html';
        return;
    }
    
    // Initialize Google Sign-In
    setTimeout(() => {
        initGoogleSignIn();
    }, 500);
});
