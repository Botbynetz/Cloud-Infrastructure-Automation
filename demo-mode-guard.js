// Demo Mode Guard - Disable pricing links in demo mode
document.addEventListener('DOMContentLoaded', function() {
    const mode = localStorage.getItem('univai_mode');
    
    // Only run in demo mode
    if (mode === 'demo') {
        // Find all links to pricing.html
        const pricingLinks = document.querySelectorAll('a[href="pricing.html"]');
        
        pricingLinks.forEach(link => {
            // Prevent default navigation
            link.addEventListener('click', function(e) {
                e.preventDefault();
                alert('🧪 Demo Mode Active\n\nYou are currently in Demo Mode with free access to all features. Switch to Real Mode using the toggle switch to subscribe to a plan.');
            });
            
            // Add visual indication (optional - make it look disabled)
            link.style.opacity = '0.6';
            link.style.cursor = 'not-allowed';
            link.title = 'Available in Real Mode only';
        });
    }
});
