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
        
        if (this.checked) {
            // Switching to Real mode
            if (currentMode === 'demo' || !currentMode) {
                if (confirm('🚀 Switch to Real Mode?\n\nYou will need a subscription plan to use your own AWS credentials.')) {
                    localStorage.setItem('univai_mode', 'real');
                    modeLabel.textContent = 'Real';
                    modeLabel.style.color = '#0066FF';
                    pricingMenuItems.forEach(item => {
                        item.classList.remove('hidden');
                    });
                    // No reload, just update UI
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
                    modeLabel.textContent = 'Demo';
                    modeLabel.style.color = '#F59E0B';
                    pricingMenuItems.forEach(item => {
                        item.classList.add('hidden');
                    });
                    // No reload, just update UI
                } else {
                    // User cancelled, revert switch
                    this.checked = true;
                }
            }
        }
    });
});
