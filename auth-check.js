// Auth check for deployment page
(function() {
    // Check if user is logged in
    const user = localStorage.getItem('univai_user');
    
    if (!user) {
        // Get tier from URL
        const urlParams = new URLSearchParams(window.location.search);
        const tier = urlParams.get('tier') || 'free';
        
        // Redirect to auth page
        window.location.href = `auth.html?tier=${tier}&from=deploy`;
        return;
    }
    
    // Parse user data
    const userData = JSON.parse(user);
    
    // Display user info
    const userEmail = userData.email;
    const userTier = userData.tier;
    
    console.log('✅ User authenticated:', userEmail, '| Tier:', userTier);
    
    // Add logout functionality
    window.logout = function() {
        if (confirm('Are you sure you want to logout?')) {
            localStorage.removeItem('univai_user');
            localStorage.removeItem('univai_token');
            localStorage.removeItem('currentUser');
            window.location.href = 'auth.html';
        }
    };
    
    // Show user info in UI (if element exists)
    const userInfoEl = document.getElementById('user-info');
    if (userInfoEl) {
        userInfoEl.innerHTML = `
            <div style="display: flex; align-items: center; gap: 15px; padding: 10px 20px; background: #F3F4F6; border-radius: 10px;">
                <div style="flex: 1;">
                    <div style="font-weight: 600; color: #1F2937;">${userEmail}</div>
                    <div style="font-size: 13px; color: #6B7280;">Tier: ${userTier.toUpperCase()}</div>
                </div>
                <button onclick="logout()" style="padding: 8px 16px; background: #EF4444; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px;">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </button>
            </div>
        `;
    }
})();