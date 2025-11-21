// Mode Toggle Logic - Clean Version
document.addEventListener('DOMContentLoaded', function() {
    // Get or set default mode
    let mode = localStorage.getItem('univai_mode');
    if (!mode) {
        mode = 'demo';
        localStorage.setItem('univai_mode', 'demo');
    }
    
    const modeSwitch = document.getElementById('modeSwitch');
    const modeLabel = document.getElementById('modeLabel');
    const pricingMenuItems = document.querySelectorAll('.pricing-menu-item');
    
    // Exit if toggle elements don't exist
    if (!modeSwitch || !modeLabel) return;
    
    // Update UI based on current mode
    function updateUI(currentMode) {
        if (currentMode === 'real') {
            modeSwitch.checked = true;
            modeLabel.textContent = 'Real';
            modeLabel.style.color = '#0066FF';
            pricingMenuItems.forEach(item => item.classList.remove('hidden'));
        } else {
            modeSwitch.checked = false;
            modeLabel.textContent = 'Demo';
            modeLabel.style.color = '#F59E0B';
            pricingMenuItems.forEach(item => item.classList.add('hidden'));
        }
    }
    
    // Initialize UI
    updateUI(mode);
    
    // Handle toggle switch change
    modeSwitch.addEventListener('change', function() {
        const currentMode = localStorage.getItem('univai_mode');
        const currentPage = window.location.pathname.split('/').pop();
        const userPlan = localStorage.getItem('userPlan');
        
        if (this.checked) {
            // Switching to Real Mode
            if (confirm('🚀 Switch to Real Mode?\n\nYou will need a subscription plan to use your own AWS credentials.')) {
                localStorage.setItem('univai_mode', 'real');
                
                // Check if user has a plan
                if (!userPlan || userPlan === 'free') {
                    // No plan - go to pricing first
                    window.location.href = 'pricing.html';
                } else {
                    // Has plan - go to real mode house
                    if (currentPage === 'index.html') {
                        window.location.href = 'index-real.html';
                    } else if (currentPage === 'dashboard.html') {
                        window.location.href = 'dashboard-real.html';
                    } else if (currentPage === 'deploy.html') {
                        window.location.href = 'deploy-real.html';
                    } else if (currentPage === 'pricing.html') {
                        location.reload();
                    } else {
                        window.location.href = 'index-real.html';
                    }
                }
            } else {
                // User cancelled - revert
                this.checked = false;
            }
        } else {
            // Switching to Demo Mode
            if (confirm('🧪 Switch to Demo Mode?\n\nYou will get free access to all features with test credentials.')) {
                localStorage.setItem('univai_mode', 'demo');
                
                // Go to demo mode house
                if (currentPage === 'index-real.html') {
                    window.location.href = 'index.html';
                } else if (currentPage === 'dashboard-real.html') {
                    window.location.href = 'dashboard.html';
                } else if (currentPage === 'deploy-real.html') {
                    window.location.href = 'deploy.html';
                } else if (currentPage === 'pricing.html') {
                    window.location.href = 'index.html';
                } else {
                    window.location.href = 'index.html';
                }
            } else {
                // User cancelled - revert
                this.checked = true;
            }
        }
    });
});
