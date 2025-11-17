// ========================================
// CLEAN HEADER JAVASCRIPT - REBUILD
// ========================================

document.addEventListener('DOMContentLoaded', function() {
    // Get elements
    const profileBtn = document.getElementById('profileBtn');
    const profileMenu = document.getElementById('profileMenu');
    const menuBtn = document.getElementById('menuBtn');
    const sideMenu = document.getElementById('sideMenu');
    const sideMenuOverlay = document.getElementById('sideMenuOverlay');
    const sideMenuClose = document.getElementById('sideMenuClose');
    
    // Profile Menu Toggle
    if (profileBtn && profileMenu) {
        profileBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            profileMenu.classList.toggle('show');
            // Close side menu if open
            if (sideMenu && sideMenu.classList.contains('show')) {
                closeSideMenu();
            }
        });
        
        // Close when clicking outside
        document.addEventListener('click', function(e) {
            if (!profileMenu.contains(e.target) && e.target !== profileBtn) {
                profileMenu.classList.remove('show');
            }
        });
    }
    
    // Side Menu Functions
    function openSideMenu() {
        if (sideMenu && sideMenuOverlay && menuBtn) {
            sideMenu.classList.add('show');
            sideMenuOverlay.classList.add('show');
            menuBtn.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }
    
    function closeSideMenu() {
        if (sideMenu && sideMenuOverlay && menuBtn) {
            sideMenu.classList.remove('show');
            sideMenuOverlay.classList.remove('show');
            menuBtn.classList.remove('active');
            document.body.style.overflow = '';
        }
    }
    
    // Menu Button Click
    if (menuBtn) {
        menuBtn.addEventListener('click', function() {
            if (sideMenu && sideMenu.classList.contains('show')) {
                closeSideMenu();
            } else {
                openSideMenu();
                // Close profile menu if open
                if (profileMenu && profileMenu.classList.contains('show')) {
                    profileMenu.classList.remove('show');
                }
            }
        });
    }
    
    // Close Button Click
    if (sideMenuClose) {
        sideMenuClose.addEventListener('click', closeSideMenu);
    }
    
    // Overlay Click
    if (sideMenuOverlay) {
        sideMenuOverlay.addEventListener('click', closeSideMenu);
    }
    
    // Close menu when clicking a link
    if (sideMenu) {
        const menuItems = sideMenu.querySelectorAll('.side-menu-item');
        menuItems.forEach(item => {
            item.addEventListener('click', function() {
                closeSideMenu();
            });
        });
    }
    
    // User Authentication
    function updateUserProfile() {
        const userStr = localStorage.getItem('cloudstack_user');
        if (userStr) {
            try {
                const user = JSON.parse(userStr);
                
                // Update avatar
                const userAvatar = document.getElementById('userAvatar');
                const profileMenuAvatar = document.getElementById('profileMenuAvatar');
                if (user.name) {
                    const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=0066FF&color=fff&size=128`;
                    if (userAvatar) userAvatar.src = avatarUrl;
                    if (profileMenuAvatar) profileMenuAvatar.src = avatarUrl;
                }
                
                // Update name and email
                const userName = document.getElementById('userName');
                const userEmail = document.getElementById('userEmail');
                if (userName) userName.textContent = user.name || 'User';
                if (userEmail) userEmail.textContent = user.email || '';
                
                // Update auth button
                const authAction = document.getElementById('authAction');
                if (authAction) {
                    authAction.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Sign Out</span>';
                    authAction.href = '#';
                    authAction.addEventListener('click', function(e) {
                        e.preventDefault();
                        localStorage.removeItem('cloudstack_user');
                        localStorage.removeItem('cloudstack_token');
                        window.location.href = 'auth.html';
                    });
                }
            } catch (error) {
                console.error('Error parsing user data:', error);
            }
        }
    }
    
    // Initialize user profile
    updateUserProfile();
});
