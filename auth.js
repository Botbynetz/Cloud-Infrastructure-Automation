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

// Login with Google (placeholder)
function loginWithGoogle() {
    showAlert('Google OAuth integration coming soon! Please use email/password for now.', 'error');
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
});