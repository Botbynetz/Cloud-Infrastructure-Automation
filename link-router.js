// Link Router - Automatically routes links based on current mode
// Real mode pages link to real mode pages, demo mode pages link to demo mode pages
(function() {
    const currentPage = window.location.pathname.split('/').pop();
    const isRealMode = currentPage.includes('-real.html');
    
    // Wait for DOM to load
    document.addEventListener('DOMContentLoaded', function() {
        // Get all links
        const links = document.querySelectorAll('a[href]');
        
        links.forEach(link => {
            const href = link.getAttribute('href');
            
            // Skip external links, anchors, and already processed links
            if (!href || href.startsWith('http') || href.startsWith('#') || href.startsWith('mailto:')) {
                return;
            }
            
            // Pages that need routing
            const pagesMap = {
                'index.html': isRealMode ? 'index-real.html' : 'index.html',
                'dashboard.html': isRealMode ? 'dashboard-real.html' : 'dashboard.html',
                'deploy.html': isRealMode ? 'deploy-real.html' : 'deploy.html',
                // Reverse mapping for when switching modes
                'index-real.html': isRealMode ? 'index-real.html' : 'index.html',
                'dashboard-real.html': isRealMode ? 'dashboard-real.html' : 'dashboard.html',
                'deploy-real.html': isRealMode ? 'deploy-real.html' : 'deploy.html'
            };
            
            // Check if this link needs routing
            Object.keys(pagesMap).forEach(page => {
                if (href === page || href.includes(page)) {
                    link.setAttribute('href', pagesMap[page]);
                }
            });
        });
    });
})();
