// Plan Guard for Real Mode Pages
// Checks if user has selected a plan, redirects to pricing if not
(function() {
    const mode = localStorage.getItem('univai_mode');
    const userPlan = localStorage.getItem('userPlan');
    const currentPage = window.location.pathname.split('/').pop();
    
    // Only run on real mode pages (not pricing page)
    if (mode === 'real' && currentPage !== 'pricing.html') {
        // Check if user has a plan
        if (!userPlan || userPlan === 'free') {
            // No plan selected - redirect to pricing
            alert('⚠️ Please select a subscription plan first');
            window.location.href = 'pricing.html';
        }
    }
})();
