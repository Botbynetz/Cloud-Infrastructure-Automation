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

// Contact form submission (demo)
document.querySelector('.contact-form form').addEventListener('submit', function(e) {
    e.preventDefault();
    alert('Thank you for your interest! We will contact you shortly.\n\nNote: This is a demo form. In production, this would send your information to our team.');
    this.reset();
});

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