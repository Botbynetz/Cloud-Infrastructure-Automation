// Auth Guard - Protect all pages except login/auth pages
// This script runs on EVERY page to check if user is logged in

(function() {
    // Get current page filename
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    
    // Pages that DON'T require authentication
    const publicPages = ['login.html', 'auth.html'];
    
    // Check if current page is public
    const isPublicPage = publicPages.some(page => currentPage.includes(page));
    
    // If public page, no need to check auth
    if (isPublicPage) {
        return;
    }
    
    // Check if user is logged in
    const currentUser = sessionStorage.getItem('cloudstack_user');
    
    if (!currentUser) {
        // Not logged in - redirect to login page
        console.log('Access denied: User not logged in');
        window.location.href = 'login.html';
    } else {
        // User is logged in - parse user data
        try {
            const userData = JSON.parse(currentUser);
            console.log('User authenticated:', userData.email);
            
            // Add user info to pages (if element exists)
            addUserInfoToPage(userData);
        } catch (e) {
            console.error('Invalid session data');
            sessionStorage.removeItem('cloudstack_user');
            window.location.href = 'login.html';
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
            sessionStorage.removeItem('cloudstack_user');
            window.location.href = 'login.html';
        }
    };
})();
