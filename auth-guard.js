// Auth Guard - Protect all pages except login/auth pages
// This script runs on EVERY page to check if user is logged in

(function() {
    // Get current page filename
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    // Pages that DON'T require authentication
    const publicPages = ['auth.html', 'register.html'];
    
    // Check if current page is public
    const isPublicPage = publicPages.some(page => currentPage.includes(page));
    
    // If public page, no need to check auth
    if (isPublicPage) {
        return;
    }
    
    // Check if user is logged in
    const currentUser = localStorage.getItem('univai_user');
    const token = localStorage.getItem('univai_token');
    
    if (!currentUser || !token) {
        // Not logged in - redirect to login page
        console.log('Access denied: User not logged in');
        localStorage.removeItem('univai_user');
        localStorage.removeItem('univai_token');
        window.location.href = 'auth.html';
    } else {
        // User is logged in - parse user data and check token expiry
        try {
            const userData = JSON.parse(currentUser);
            
            // Check token expiration (JWT tokens expire after 24h)
            const tokenPayload = parseJwt(token);
            if (tokenPayload && tokenPayload.exp) {
                const currentTime = Math.floor(Date.now() / 1000);
                if (currentTime > tokenPayload.exp) {
                    console.log('Token expired - please login again');
                    localStorage.removeItem('univai_user');
                    localStorage.removeItem('univai_token');
                    alert('Your session has expired. Please login again.');
                    window.location.href = 'auth.html';
                    return;
                }
            }
            
            console.log('User authenticated:', userData.email);
            
            // Add user info to pages (if element exists)
            addUserInfoToPage(userData);
        } catch (e) {
            console.error('Invalid session data');
            localStorage.removeItem('univai_user');
            localStorage.removeItem('univai_token');
            window.location.href = 'auth.html';
        }
    }
    
    // Parse JWT token helper function
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
    
    // Function to add user info and logout button to pages
    function addUserInfoToPage(userData) {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => insertUserInfo(userData));
        } else {
            insertUserInfo(userData);
        }
    }
    
    function insertUserInfo(userData) {
        // Check if page already has user-info div
        let userInfoDiv = document.getElementById('user-info');
        
        if (!userInfoDiv) {
            // Try to find navigation bar to add user info
            const navbar = document.querySelector('.navbar .container');
            if (navbar) {
                userInfoDiv = document.createElement('div');
                userInfoDiv.id = 'user-info';
                userInfoDiv.style.cssText = 'margin-left: auto; display: flex; align-items: center; gap: 15px;';
                navbar.appendChild(userInfoDiv);
            }
        }
        
        if (userInfoDiv && !userInfoDiv.hasChildNodes()) {
            const tierColors = {
                'free': '#6c757d',
                'professional': '#667eea',
                'enterprise': '#f59e0b',
                'ultimate': '#ec4899'
            };
            
            const tierColor = tierColors[userData.tier?.toLowerCase()] || '#667eea';
            
            userInfoDiv.innerHTML = `
                <div style="display: flex; align-items: center; gap: 12px; padding: 8px 16px; background: #f8f9fa; border-radius: 8px;">
                    ${userData.picture ? 
                        `<img src="${userData.picture}" alt="Profile" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">` :
                        `<div style="width: 32px; height: 32px; border-radius: 50%; background: ${tierColor}; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">
                            ${userData.email.charAt(0).toUpperCase()}
                        </div>`
                    }
                    <div style="display: flex; flex-direction: column; gap: 2px;">
                        <span style="font-size: 13px; font-weight: 600; color: #1a1a1a;">${userData.email}</span>
                        <span style="font-size: 11px; padding: 2px 8px; background: ${tierColor}; color: white; border-radius: 4px; text-transform: uppercase; font-weight: 600;">
                            ${userData.tier || 'FREE'}
                        </span>
                    </div>
                    <button onclick="logout()" style="padding: 8px 16px; background: #dc3545; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; transition: all 0.3s ease;" onmouseover="this.style.background='#c82333'" onmouseout="this.style.background='#dc3545'">
                        <i class="fas fa-sign-out-alt"></i> Logout
                    </button>
                </div>
            `;
        }
    }
    
    // Global logout function
    window.logout = function() {
        if (confirm('Are you sure you want to logout?')) {
            localStorage.removeItem('univai_user');
            localStorage.removeItem('univai_token');
            localStorage.removeItem('currentUser');
            window.location.href = 'auth.html';
        }
    };
})();
