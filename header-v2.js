// ============================================
// HEADER V2 - JavaScript Functions
// Hamburger Menu, Mode Badge, Profile Dropdown
// ============================================

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    initializeHeader();
});

// ============ INITIALIZATION ============
function initializeHeader() {
    // Detect current mode from filename
    const currentPage = window.location.pathname.split('/').pop();
    const isRealMode = currentPage.includes('-real');
    
    // Update mode badge
    updateModeBadge(isRealMode);
    
    // Update plan badge in profile
    updatePlanBadge();
    
    // Load user info
    loadUserInfo();
    
    // Setup event listeners
    setupEventListeners();
}

// ============ MODE BADGE ============
function updateModeBadge(isRealMode) {
    const modeBadge = document.getElementById('modeBadge');
    if (!modeBadge) return;
    
    if (isRealMode) {
        modeBadge.className = 'mode-badge real-badge';
        modeBadge.innerHTML = '<span class="emoji">💳</span><span class="mode-text">REAL MODE</span>';
    } else {
        modeBadge.className = 'mode-badge demo-badge';
        modeBadge.innerHTML = '<span class="emoji">🧪</span><span class="mode-text">DEMO MODE</span>';
    }
}

// ============ PLAN BADGE ============
function updatePlanBadge() {
    const userPlan = localStorage.getItem('userPlan') || 'free';
    const planBadge = document.getElementById('planBadge');
    
    if (!planBadge) return;
    
    const planConfig = {
        free: { emoji: '🆓', text: 'FREE', class: 'free-badge' },
        lite: { emoji: '💼', text: 'LITE', class: 'lite-badge' },
        basic: { emoji: '⚡', text: 'BASIC', class: 'basic-badge' },
        pro: { emoji: '💎', text: 'PRO', class: 'pro-badge' },
        enterprise: { emoji: '👑', text: 'ENTERPRISE', class: 'enterprise-badge' }
    };
    
    const plan = planConfig[userPlan] || planConfig.free;
    planBadge.innerHTML = `${plan.emoji} ${plan.text}`;
    planBadge.className = `plan-badge ${plan.class}`;
}

// ============ USER INFO ============
function loadUserInfo() {
    const userStr = localStorage.getItem('univai_user');
    if (!userStr) return;
    
    try {
        const user = JSON.parse(userStr);
        
        // Update username in header
        const usernameEls = document.querySelectorAll('.username');
        usernameEls.forEach(el => {
            el.textContent = user.name || 'User';
        });
        
        // Update email in dropdown
        const emailEl = document.getElementById('userEmail');
        if (emailEl) {
            emailEl.textContent = user.email || '';
        }
        
        // Update name in dropdown
        const nameEl = document.getElementById('userName');
        if (nameEl) {
            nameEl.textContent = user.name || 'User';
        }
    } catch (e) {
        console.error('Error loading user info:', e);
    }
}

// ============ EVENT LISTENERS ============
function setupEventListeners() {
    // Close dropdowns when clicking outside
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.profile-btn') && !e.target.closest('.profile-dropdown')) {
            closeProfileDropdown();
        }
    });
}

// ============ HAMBURGER MENU ============
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    
    if (sidebar && overlay) {
        sidebar.classList.toggle('active');
        overlay.classList.toggle('active');
    }
}

function closeSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    
    if (sidebar && overlay) {
        sidebar.classList.remove('active');
        overlay.classList.remove('active');
    }
}

// ============ MODE MODAL ============
function showModeModal() {
    const currentPage = window.location.pathname.split('/').pop();
    const isRealMode = currentPage.includes('-real');
    const userPlan = localStorage.getItem('userPlan') || 'free';
    
    const modal = document.getElementById('modeModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalDescription = document.getElementById('modalDescription');
    const modalPrimaryBtn = document.getElementById('modalPrimaryBtn');
    const modalSecondaryBtn = document.getElementById('modalSecondaryBtn');
    
    if (!modal) return;
    
    if (isRealMode) {
        // Currently in Real Mode
        modalTitle.textContent = 'You\'re in Real Mode';
        modalDescription.innerHTML = `
            <div style="margin: 20px 0;">
                <div class="plan-badge ${getPlanClass(userPlan)}" style="font-size: 14px; padding: 8px 16px;">
                    ${getPlanEmoji(userPlan)} ${userPlan.toUpperCase()} PLAN
                </div>
            </div>
            <p>You have access to all premium features and can deploy real infrastructure.</p>
            <p>Want to try the free demo version?</p>
        `;
        modalPrimaryBtn.textContent = 'Switch to Demo Mode';
        modalPrimaryBtn.onclick = switchToDemo;
        modalSecondaryBtn.textContent = 'Stay in Real Mode';
        modalSecondaryBtn.onclick = closeModeModal;
    } else {
        // Currently in Demo Mode
        modalTitle.textContent = 'You\'re in Demo Mode';
        modalDescription.innerHTML = `
            <p style="font-size: 16px; margin: 20px 0;">🆓 <strong>Free access to all features</strong></p>
            <p>In Demo Mode, you can explore the platform without any charges.</p>
            <p>Ready to deploy real infrastructure?</p>
        `;
        modalPrimaryBtn.textContent = 'Upgrade to Real Mode →';
        modalPrimaryBtn.onclick = switchToReal;
        modalSecondaryBtn.textContent = 'Stay in Demo';
        modalSecondaryBtn.onclick = closeModeModal;
    }
    
    modal.classList.add('active');
}

function closeModeModal() {
    const modal = document.getElementById('modeModal');
    if (modal) {
        modal.classList.remove('active');
    }
}

function switchToReal() {
    const userPlan = localStorage.getItem('userPlan') || 'free';
    
    if (!userPlan || userPlan === 'free') {
        // No plan - redirect to pricing
        window.location.href = 'pricing.html';
    } else {
        // Has plan - go to real mode homepage
        window.location.href = 'index-real.html';
    }
}

function switchToDemo() {
    // Switch to demo mode homepage
    window.location.href = 'index.html';
}

// ============ PROFILE DROPDOWN ============
function toggleProfile() {
    const dropdown = document.getElementById('profileDropdown');
    if (dropdown) {
        dropdown.classList.toggle('active');
    }
}

function closeProfileDropdown() {
    const dropdown = document.getElementById('profileDropdown');
    if (dropdown) {
        dropdown.classList.remove('active');
    }
}

// ============ HELPER FUNCTIONS ============
function getPlanClass(plan) {
    const classes = {
        free: 'free-badge',
        lite: 'lite-badge',
        basic: 'basic-badge',
        pro: 'pro-badge',
        enterprise: 'enterprise-badge'
    };
    return classes[plan] || 'free-badge';
}

function getPlanEmoji(plan) {
    const emojis = {
        free: '🆓',
        lite: '💼',
        basic: '⚡',
        pro: '💎',
        enterprise: '👑'
    };
    return emojis[plan] || '🆓';
}

// ============ LOGOUT ============
function logout() {
    if (confirm('Are you sure you want to logout?')) {
        localStorage.clear();
        window.location.href = 'auth.html';
    }
}
