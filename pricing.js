// Pricing Calculator Logic
// Token-based pricing with real-time calculation

// State management
const state = {
    selectedModules: new Set(),
    config: {
        environment: 'dev',
        region: 'single',
        availability: 'standard'
    },
    tokenPrice: 80000, // Rp 80k per token (average)
};

// Module pricing database
const MODULE_PRICES = {
    'self-service-portal': { tokens: 1.0, name: 'Self-Service Portal', category: 'basic' },
    'observability': { tokens: 1.0, name: 'Observability 2.0', category: 'basic' },
    'gitops-cicd': { tokens: 1.0, name: 'GitOps CI/CD', category: 'basic' },
    'autoscaling': { tokens: 1.0, name: 'Auto-Scaling', category: 'basic' },
    'finops': { tokens: 1.0, name: 'FinOps Optimization', category: 'basic' },
    'kubernetes': { tokens: 2.0, name: 'Kubernetes/EKS', category: 'advanced' },
    'zero-trust': { tokens: 2.0, name: 'Zero Trust Security', category: 'advanced' },
    'service-mesh': { tokens: 2.0, name: 'Service Mesh', category: 'advanced' },
    'policy-governance': { tokens: 2.0, name: 'Policy-as-Code', category: 'advanced' },
    'aiops': { tokens: 3.0, name: 'AIOps Intelligence', category: 'complex' },
    'disaster-recovery': { tokens: 3.0, name: 'Disaster Recovery', category: 'complex' },
    'multi-cloud': { tokens: 3.0, name: 'Multi-Cloud', category: 'complex' }
};

// Multiplier configuration
const MULTIPLIERS = {
    environment: {
        dev: 1.0,
        prod: 1.2
    },
    region: {
        single: 1.0,
        multi: 1.5
    },
    availability: {
        standard: 1.0,
        ha: 1.3
    }
};

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    initializeCalculator();
    setupEventListeners();
    makeCalculatorSticky();
});

// Initialize calculator
function initializeCalculator() {
    updateCalculator();
    updateMultipliers();
}

// Setup event listeners
function setupEventListeners() {
    // Deploy button
    const deployBtn = document.getElementById('btnProceedDeploy');
    if (deployBtn) {
        deployBtn.addEventListener('click', () => {
            if (state.selectedModules.size > 0) {
                proceedToDeploy();
            }
        });
    }

    // Toggle calculator details
    const calculator = document.getElementById('floatingCalculator');
    if (calculator) {
        calculator.addEventListener('click', (e) => {
            if (e.target.closest('.calculator-content') && state.selectedModules.size > 0) {
                toggleCalculatorDetails();
            }
        });
    }
}

// Make calculator sticky on scroll
function makeCalculatorSticky() {
    const calculator = document.getElementById('floatingCalculator');
    const navbar = document.querySelector('.navbar');
    
    if (!calculator || !navbar) return;

    const navbarHeight = navbar.offsetHeight;
    const calculatorTop = calculator.offsetTop;

    window.addEventListener('scroll', () => {
        if (window.scrollY > calculatorTop - navbarHeight) {
            calculator.classList.add('sticky');
            calculator.style.top = `${navbarHeight}px`;
        } else {
            calculator.classList.remove('sticky');
            calculator.style.top = 'auto';
        }
    });
}

// Toggle module selection
function toggleModule(element) {
    const moduleId = element.dataset.module;
    
    if (state.selectedModules.has(moduleId)) {
        state.selectedModules.delete(moduleId);
        element.classList.remove('selected');
    } else {
        state.selectedModules.add(moduleId);
        element.classList.add('selected');
    }
    
    updateCalculator();
}

// Update multipliers display
function updateMultipliers() {
    const env = document.querySelector('input[name="environment"]:checked')?.value || 'dev';
    const region = document.querySelector('input[name="region"]:checked')?.value || 'single';
    const avail = document.querySelector('input[name="availability"]:checked')?.value || 'standard';
    
    state.config.environment = env;
    state.config.region = region;
    state.config.availability = avail;
    
    // Update multiplier displays
    const envMultiplier = MULTIPLIERS.environment[env];
    const regionMultiplier = MULTIPLIERS.region[region];
    const availMultiplier = MULTIPLIERS.availability[avail];
    
    const envDisplay = document.getElementById('envMultiplierDisplay');
    const regionDisplay = document.getElementById('regionMultiplierDisplay');
    const availDisplay = document.getElementById('availMultiplierDisplay');
    
    if (envDisplay) envDisplay.textContent = `+${Math.round((envMultiplier - 1) * 100)}%`;
    if (regionDisplay) regionDisplay.textContent = `+${Math.round((regionMultiplier - 1) * 100)}%`;
    if (availDisplay) availDisplay.textContent = `+${Math.round((availMultiplier - 1) * 100)}%`;
    
    updateCalculator();
}

// Calculate total cost
function calculateCost() {
    if (state.selectedModules.size === 0) {
        return {
            baseTokens: 0,
            totalTokens: 0,
            totalRupiah: 0,
            breakdown: []
        };
    }
    
    // Calculate base tokens
    let baseTokens = 0;
    const breakdown = [];
    
    state.selectedModules.forEach(moduleId => {
        const module = MODULE_PRICES[moduleId];
        if (module) {
            baseTokens += module.tokens;
            breakdown.push({
                name: module.name,
                tokens: module.tokens
            });
        }
    });
    
    // Apply multipliers
    const envMultiplier = MULTIPLIERS.environment[state.config.environment];
    const regionMultiplier = MULTIPLIERS.region[state.config.region];
    const availMultiplier = MULTIPLIERS.availability[state.config.availability];
    
    const totalMultiplier = envMultiplier * regionMultiplier * availMultiplier;
    const totalTokens = baseTokens * totalMultiplier;
    const totalRupiah = totalTokens * state.tokenPrice;
    
    return {
        baseTokens,
        totalTokens: parseFloat(totalTokens.toFixed(2)),
        totalRupiah: Math.round(totalRupiah),
        totalMultiplier,
        envMultiplier,
        regionMultiplier,
        availMultiplier,
        breakdown
    };
}

// Update calculator display
function updateCalculator() {
    const cost = calculateCost();
    
    // Update total tokens and rupiah
    const totalTokensEl = document.getElementById('totalTokens');
    const totalRupiahEl = document.getElementById('totalRupiah');
    
    if (totalTokensEl) {
        totalTokensEl.textContent = cost.totalTokens.toFixed(1);
    }
    
    if (totalRupiahEl) {
        totalRupiahEl.textContent = formatRupiah(cost.totalRupiah);
    }
    
    // Update selected modules text
    const selectedText = document.getElementById('selectedModulesText');
    if (selectedText) {
        if (state.selectedModules.size === 0) {
            selectedText.textContent = 'Select modules below to calculate';
        } else {
            const moduleNames = Array.from(state.selectedModules)
                .map(id => MODULE_PRICES[id]?.name)
                .filter(Boolean)
                .slice(0, 3)
                .join(', ');
            const extra = state.selectedModules.size > 3 ? ` +${state.selectedModules.size - 3} more` : '';
            selectedText.textContent = moduleNames + extra;
        }
    }
    
    // Enable/disable deploy button
    const deployBtn = document.getElementById('btnProceedDeploy');
    if (deployBtn) {
        if (state.selectedModules.size > 0) {
            deployBtn.disabled = false;
            deployBtn.classList.add('active');
        } else {
            deployBtn.disabled = true;
            deployBtn.classList.remove('active');
        }
    }
    
    // Update calculator details
    updateCalculatorDetails(cost);
    
    // Add visual feedback
    const calculator = document.getElementById('floatingCalculator');
    if (calculator && state.selectedModules.size > 0) {
        calculator.classList.add('has-selection');
    } else if (calculator) {
        calculator.classList.remove('has-selection');
    }
}

// Update calculator details panel
function updateCalculatorDetails(cost) {
    const detailsPanel = document.getElementById('calculatorDetails');
    if (!detailsPanel) return;
    
    if (state.selectedModules.size === 0) {
        detailsPanel.style.display = 'none';
        return;
    }
    
    // Update selected modules list
    const modulesList = document.getElementById('selectedModulesList');
    if (modulesList) {
        modulesList.innerHTML = cost.breakdown
            .map(item => `<li>${item.name} <strong>${item.tokens.toFixed(1)} tokens</strong></li>`)
            .join('');
    }
    
    // Update config list
    const envConfig = document.getElementById('envConfig');
    if (envConfig) {
        const envLabels = { dev: 'Development', prod: 'Production' };
        const regionLabels = { single: 'Single Region', multi: 'Multi-Region' };
        const availLabels = { standard: 'Standard', ha: 'High Availability' };
        
        envConfig.textContent = `${envLabels[state.config.environment]}, ${regionLabels[state.config.region]}, ${availLabels[state.config.availability]}`;
    }
    
    // Update cost breakdown
    const breakdownList = document.getElementById('costBreakdownList');
    if (breakdownList) {
        const items = [`<li>Base Modules: <strong>${cost.baseTokens.toFixed(1)} tokens</strong></li>`];
        
        if (cost.envMultiplier > 1) {
            items.push(`<li>Production: <strong>+${((cost.envMultiplier - 1) * cost.baseTokens).toFixed(1)} tokens</strong></li>`);
        }
        if (cost.regionMultiplier > 1) {
            items.push(`<li>Multi-Region: <strong>+${((cost.regionMultiplier - 1) * cost.baseTokens * cost.envMultiplier).toFixed(1)} tokens</strong></li>`);
        }
        if (cost.availMultiplier > 1) {
            items.push(`<li>High Availability: <strong>+${((cost.availMultiplier - 1) * cost.baseTokens * cost.envMultiplier * cost.regionMultiplier).toFixed(1)} tokens</strong></li>`);
        }
        
        items.push(`<li class="total-row">Total: <strong>${cost.totalTokens.toFixed(1)} tokens</strong></li>`);
        items.push(`<li class="rupiah-row">Amount: <strong>Rp ${formatRupiah(cost.totalRupiah)}</strong></li>`);
        
        breakdownList.innerHTML = items.join('');
    }
}

// Toggle calculator details visibility
function toggleCalculatorDetails() {
    const detailsPanel = document.getElementById('calculatorDetails');
    if (!detailsPanel) return;
    
    if (detailsPanel.style.display === 'none' || !detailsPanel.style.display) {
        detailsPanel.style.display = 'block';
        detailsPanel.style.maxHeight = detailsPanel.scrollHeight + 'px';
    } else {
        detailsPanel.style.maxHeight = '0';
        setTimeout(() => {
            detailsPanel.style.display = 'none';
        }, 300);
    }
}

// Proceed to deploy page with selected modules
function proceedToDeploy() {
    if (state.selectedModules.size === 0) {
        alert('Please select at least one module to deploy');
        return;
    }
    
    // Store selection in session storage
    const deployConfig = {
        modules: Array.from(state.selectedModules),
        config: state.config,
        estimatedCost: calculateCost()
    };
    
    sessionStorage.setItem('deployConfig', JSON.stringify(deployConfig));
    
    // Redirect to deploy page
    window.location.href = 'deploy.html';
}

// Buy tokens handler
function buyTokens(packageType) {
    // Check if user is logged in
    const isLoggedIn = checkLoginStatus();
    
    if (!isLoggedIn) {
        // Redirect to login with return URL
        sessionStorage.setItem('returnUrl', window.location.href);
        sessionStorage.setItem('selectedPackage', packageType);
        window.location.href = 'auth.html';
        return;
    }
    
    // Proceed to payment
    const packages = {
        starter: { tokens: 10, price: 950000 },
        value: { tokens: 50, price: 4000000 },
        scale: { tokens: 150, price: 10500000 },
        enterprise: { tokens: 500, price: 30000000 }
    };
    
    const selectedPackage = packages[packageType];
    
    if (!selectedPackage) {
        alert('Invalid package selected');
        return;
    }
    
    // Show payment modal or redirect to payment page
    showPaymentModal(selectedPackage);
}

// Contact sales handler
function contactSales() {
    window.location.href = 'contact.html?plan=unlimited';
}

// Show payment modal
function showPaymentModal(packageData) {
    // This would integrate with Midtrans payment gateway
    alert(`Payment integration coming soon!\n\nPackage: ${packageData.tokens} tokens\nPrice: Rp ${formatRupiah(packageData.price)}`);
    
    // TODO: Integrate with backend API
    // fetch('/api/payment/create', {
    //     method: 'POST',
    //     headers: { 'Content-Type': 'application/json' },
    //     body: JSON.stringify({ tokenPackage: packageData.tokens })
    // })
    // .then(res => res.json())
    // .then(data => {
    //     // Open Midtrans Snap payment
    //     snap.pay(data.snapToken);
    // });
}

// Check login status
function checkLoginStatus() {
    // Check if user token exists in session storage
    const userToken = sessionStorage.getItem('userToken');
    return !!userToken;
}

// Format rupiah
function formatRupiah(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

// Smooth scroll to section
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        const navbar = document.querySelector('.navbar');
        const calculator = document.getElementById('floatingCalculator');
        const offset = navbar.offsetHeight + (calculator?.offsetHeight || 0);
        
        window.scrollTo({
            top: section.offsetTop - offset - 20,
            behavior: 'smooth'
        });
    }
}

// Export for use in HTML onclick handlers
window.toggleModule = toggleModule;
window.updateMultipliers = updateMultipliers;
window.buyTokens = buyTokens;
window.contactSales = contactSales;
window.proceedToDeploy = proceedToDeploy;
