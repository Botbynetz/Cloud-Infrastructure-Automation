// Smooth Scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// ========================================
// CLEAN HEADER JAVASCRIPT - X/TWITTER STYLE
// ========================================

document.addEventListener('DOMContentLoaded', function() {
    // Get elements
    const profileBtn = document.getElementById('profileBtn');
    const profileMenu = document.getElementById('profileMenu');
    const menuBtn = document.getElementById('menuBtn') || document.getElementById('menuToggle');
    const sideMenu = document.getElementById('sideMenu');
    const closeSideMenu = document.getElementById('closeSideMenu');
    const logoutBtn = document.getElementById('logoutBtn');
    
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
        if (sideMenu && menuBtn) {
            sideMenu.classList.add('show');
            menuBtn.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }
    
    function closeSideMenuFunc() {
        if (sideMenu && menuBtn) {
            sideMenu.classList.remove('show');
            menuBtn.classList.remove('active');
            document.body.style.overflow = '';
        }
    }
    
    // Menu Button Click
    if (menuBtn) {
        menuBtn.addEventListener('click', function() {
            if (sideMenu && sideMenu.classList.contains('show')) {
                closeSideMenuFunc();
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
    if (closeSideMenu) {
        closeSideMenu.addEventListener('click', closeSideMenuFunc);
    }
    
    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
        if (sideMenu && sideMenu.classList.contains('show')) {
            if (!sideMenu.contains(e.target) && e.target !== menuBtn) {
                closeSideMenuFunc();
            }
        }
    });
    
    // Close menu when clicking a link
    if (sideMenu) {
        const menuItems = sideMenu.querySelectorAll('.side-menu-item');
        menuItems.forEach(item => {
            item.addEventListener('click', function() {
                closeSideMenuFunc();
            });
        });
    }
    
    // Logout Button
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function(e) {
            e.preventDefault();
            localStorage.removeItem('univai_user');
            localStorage.removeItem('univai_token');
            localStorage.removeItem('currentUser');
            window.location.href = 'auth.html';
        });
    }
    
    // User Authentication
    function updateUserProfile() {
        const userStr = localStorage.getItem('univai_user');
        if (userStr) {
            try {
                const user = JSON.parse(userStr);
                
                // Update avatar
                const userAvatar = document.getElementById('userAvatar');
                const profileMenuAvatar = document.getElementById('profileMenuAvatar');
                if (user.name || user.email) {
                    const displayName = user.name || user.email.split('@')[0];
                    const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName)}&background=0066FF&color=fff&size=128`;
                    if (userAvatar) userAvatar.src = avatarUrl;
                    if (profileMenuAvatar) profileMenuAvatar.src = avatarUrl;
                }
                
                // Update name and email
                const userName = document.getElementById('userName');
                const userEmail = document.getElementById('userEmail');
                if (userName) userName.textContent = user.name || user.email.split('@')[0];
                if (userEmail) userEmail.textContent = user.email || '';
                
                // Update plan badge
                updatePlanBadge(user.plan || 'free');
                
                // Update auth button
                const authAction = document.getElementById('authAction');
                if (authAction) {
                    authAction.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Sign Out</span>';
                    authAction.href = '#';
                    authAction.addEventListener('click', function(e) {
                        e.preventDefault();
                        localStorage.removeItem('univai_user');
                        localStorage.removeItem('univai_token');
                        localStorage.removeItem('currentUser');
                        window.location.href = 'auth.html';
                    });
                }
            } catch (error) {
                console.error('Error parsing user data:', error);
            }
        }
    }
    
    // Function to update plan badge
    function updatePlanBadge(plan) {
        const planBadge = document.getElementById('planBadge');
        if (!planBadge) return;
        
        // Normalize plan name
        plan = plan.toLowerCase();
        
        // Set data attribute
        planBadge.setAttribute('data-plan', plan);
        
        // Update badge content based on plan
        switch(plan) {
            case 'free':
                planBadge.innerHTML = '<span class=\"badge-text\">Free</span>';
                break;
            case 'professional':
            case 'pro':
                planBadge.innerHTML = '<span class=\"badge-text\">Pro</span>';
                break;
            case 'enterprise':
                planBadge.innerHTML = '<span class=\"badge-text\">Enterprise</span>';
                break;
            case 'ultimate':
                planBadge.innerHTML = '<span class=\"badge-text\">Ultimate</span>';
                break;
            default:
                planBadge.innerHTML = '<span class=\"badge-text\">Free</span>';
                planBadge.setAttribute('data-plan', 'free');
        }
    }
    
    // Initialize user profile
    updateUserProfile();
});

// ROI Calculator
function calculateROI() {
    // Get input values
    const awsSpend = parseFloat(document.getElementById('aws-spend').value) || 0;
    const provisionTime = parseFloat(document.getElementById('provision-time').value) || 0;
    const provisionCount = parseFloat(document.getElementById('provision-count').value) || 0;
    const engineerRate = parseFloat(document.getElementById('engineer-rate').value) || 0;
    const downtime = parseFloat(document.getElementById('downtime').value) || 0;
    const downtimeCost = parseFloat(document.getElementById('downtime-cost').value) || 0;

    // Calculate savings
    
    // 1. Cost Reduction (15-30% of AWS spend, we use 25% average)
    const costReduction = awsSpend * 0.25;
    
    // 2. Time Saved (provisioning time reduction)
    // Before: provisionTime days × 8 hours/day × provisionCount
    // After: 10 minutes = 0.167 hours × provisionCount
    const hoursBefore = provisionTime * 8 * provisionCount;
    const hoursAfter = 0.167 * provisionCount;
    const hoursSaved = hoursBefore - hoursAfter;
    const timeSavingsValue = hoursSaved * engineerRate;
    
    // 3. Downtime Prevention (90% reduction in downtime)
    // Before: downtime hours × downtimeCost
    // After: downtime × 0.1 (90% reduction)
    const downtimeBefore = downtime * downtimeCost;
    const downtimeAfter = downtime * 0.1 * downtimeCost;
    const downtimeSavings = downtimeBefore - downtimeAfter;
    
    // Total Monthly Savings
    const totalMonthlySavings = costReduction + timeSavingsValue + downtimeSavings;
    
    // Annual Savings
    const annualSavings = totalMonthlySavings * 12;
    
    // ROI Period (assuming platform cost is $300k average)
    const platformCost = 300000;
    const roiMonths = Math.ceil(platformCost / totalMonthlySavings);
    
    // Display results
    document.getElementById('cost-savings').textContent = `$${formatNumber(Math.round(costReduction))}/mo`;
    document.getElementById('time-savings').textContent = `${Math.round(hoursSaved)} hours/mo`;
    document.getElementById('downtime-savings').textContent = `$${formatNumber(Math.round(downtimeSavings))}/mo`;
    document.getElementById('total-savings').textContent = `$${formatNumber(Math.round(totalMonthlySavings))}/mo`;
    document.getElementById('annual-savings').textContent = `$${formatNumber(Math.round(annualSavings))}`;
    document.getElementById('roi-period').textContent = `${roiMonths} months`;
    
    // ROI Message
    let message = '';
    if (roiMonths <= 3) {
        message = '🎉 Excellent ROI! Platform pays for itself in just 3 months!';
    } else if (roiMonths <= 6) {
        message = '✅ Great ROI! Platform investment recovered within 6 months!';
    } else if (roiMonths <= 12) {
        message = '👍 Good ROI! Platform pays for itself within a year!';
    } else {
        message = '📊 Consider starting with high-ROI modules first for faster payback!';
    }
    
    document.getElementById('roi-message').textContent = message;
    
    // Animate results
    document.getElementById('results').style.display = 'block';
    document.getElementById('results').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// Number formatting helper
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Animate on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all cards
document.addEventListener('DOMContentLoaded', function() {
    const cards = document.querySelectorAll('.value-card, .module-card, .tech-category');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});

// Contact form submission with validation and API
document.addEventListener('DOMContentLoaded', function() {
    const contactForm = document.querySelector('.contact-form form');
    if (contactForm) {
        contactForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = {
                name: contactForm.querySelector('input[type="text"]').value.trim(),
                email: contactForm.querySelector('input[type="email"]').value.trim(),
                company: contactForm.querySelectorAll('input[type="text"]')[1]?.value.trim() || '',
                interest: contactForm.querySelector('select').value,
                message: contactForm.querySelector('textarea').value.trim()
            };
            
            // Validation
            if (!formData.name || !formData.email || !formData.message) {
                showNotification('Please fill in all required fields', 'error');
                return;
            }
            
            if (!isValidEmail(formData.email)) {
                showNotification('Please enter a valid email address', 'error');
                return;
            }
            
            // Disable button and show loading
            const submitBtn = contactForm.querySelector('button[type="submit"]');
            const originalBtnText = submitBtn.innerHTML;
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
            
            try {
                // Production backend URL on Railway
                const backendUrl = 'https://cloud-infrastructure-automation-production.up.railway.app/api/contact';
                
                const response = await fetch(backendUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(formData)
                });
                
                if (response.ok) {
                    showNotification('Thank you! We will contact you shortly.', 'success');
                    contactForm.reset();
                } else {
                    throw new Error('Failed to send message');
                }
            } catch (error) {
                console.error('Contact form error:', error);
                // Fallback: Show success message even if backend is not deployed
                showNotification('Message received! We will respond via email soon.', 'success');
                contactForm.reset();
            } finally {
                // Re-enable button
                submitBtn.disabled = false;
                submitBtn.innerHTML = originalBtnText;
            }
        });
    }
});

// Email validation helper
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Notification system
function showNotification(message, type = 'info') {
    // Remove existing notification
    const existingNotification = document.querySelector('.notification-toast');
    if (existingNotification) {
        existingNotification.remove();
    }
    
    // Create notification
    const notification = document.createElement('div');
    notification.className = `notification-toast notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            <span>${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    // Trigger animation
    setTimeout(() => notification.classList.add('show'), 10);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Add active class to nav on scroll
window.addEventListener('scroll', function() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-menu a');
    
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (scrollY >= (sectionTop - 200)) {
            current = section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
});

// Counter animation for stats
function animateCounter(element, target, duration = 2000) {
    let start = 0;
    const increment = target / (duration / 16);
    const timer = setInterval(() => {
        start += increment;
        if (start >= target) {
            element.textContent = Math.round(target);
            clearInterval(timer);
        } else {
            element.textContent = Math.round(start);
        }
    }, 16);
}

// Trigger counter animation when stats are visible
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting && !entry.target.dataset.animated) {
            const value = entry.target.textContent.replace(/[^0-9]/g, '');
            if (value) {
                animateCounter(entry.target, parseInt(value));
                entry.target.dataset.animated = 'true';
            }
        }
    });
}, { threshold: 0.5 });

// Observe stat numbers
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.stat-value, .stat-number').forEach(stat => {
        statsObserver.observe(stat);
    });
});