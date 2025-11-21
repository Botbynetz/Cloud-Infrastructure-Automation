// Mode Toggle Logic - Reusable across all pages
document.addEventListener('DOMContentLoaded', function() {
    const mode = localStorage.getItem('univai_mode');
    const modeSwitch = document.getElementById('modeSwitch');
    const modeLabel = document.getElementById('modeLabel');
    const pricingMenuItems = document.querySelectorAll('.pricing-menu-item');
    
    // Check if mode toggle exists on this page
    if (!modeSwitch || !modeLabel) {
        return;
    }
    
    // Set initial toggle state
    if (mode === 'real') {
        modeSwitch.checked = true;
        modeLabel.textContent = 'Real';
        modeLabel.style.color = '#0066FF';
        // Show pricing menu items in real mode
        pricingMenuItems.forEach(item => {
            item.classList.remove('hidden');
        });
    } else {
        modeSwitch.checked = false;
        modeLabel.textContent = 'Demo';
        modeLabel.style.color = '#F59E0B';
        // Hide pricing menu items in demo mode
        pricingMenuItems.forEach(item => {
            item.classList.add('hidden');
        });
    }
    
    // Handle toggle switch change
    modeSwitch.addEventListener('change', function() {
        const currentMode = localStorage.getItem('univai_mode');
        const currentPage = window.location.pathname.split('/').pop();
        
        if (this.checked) {
            // Switching to Real mode
            if (currentMode === 'demo' || !currentMode) {
                if (confirm('🚀 Switch to Real Mode?\n\nYou will need a subscription plan to use your own AWS credentials.')) {
                    localStorage.setItem('univai_mode', 'real');
                    
                    // Check if user already has a plan
                    const userPlan = localStorage.getItem('userPlan');
                    
                    if (!userPlan || userPlan === 'free') {
                        // No plan - redirect to pricing first
                        window.location.href = 'pricing.html';
                    } else {
                        // Has plan - redirect to real mode version
                        if (currentPage === 'index.html') {
                            window.location.href = 'index-real.html';
                        } else if (currentPage === 'dashboard.html') {
                            window.location.href = 'dashboard-real.html';
                        } else if (currentPage === 'deploy.html') {
                            window.location.href = 'deploy-real.html';
                        } else if (currentPage === 'pricing.html') {
                            location.reload(); // Already on pricing
                        } else {
                            window.location.href = 'index-real.html'; // Default to real home
                        }
                    }
                } else {
                    // User cancelled, revert switch
                    this.checked = false;
                }
            }
        } else {
            // Switching to Demo mode
            if (currentMode === 'real') {
                if (confirm('🧪 Switch to Demo Mode?\n\nYou will get access to all features for free with test credentials. Your current plan will remain active.')) {
                    localStorage.setItem('univai_mode', 'demo');
                    
                    // Redirect to demo mode version
                    if (currentPage === 'index-real.html') {
                        window.location.href = 'index.html';
                    } else if (currentPage === 'dashboard-real.html') {
                        window.location.href = 'dashboard.html';
                    } else if (currentPage === 'deploy-real.html') {
                        window.location.href = 'deploy.html';
                    } else if (currentPage === 'pricing.html') {
                        window.location.href = 'index.html'; // Go to demo home
                    } else {
                        window.location.href = 'index.html'; // Default to demo home
                    }
                } else {
                    // User cancelled, revert switch
                    this.checked = true;
                }
            }
        }
    });
});
