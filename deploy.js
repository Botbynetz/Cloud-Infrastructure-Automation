// ============================================
// MODE DETECTION & AUTO-FILL
// ============================================
// Check user mode on page load
document.addEventListener('DOMContentLoaded', function() {
    const user = JSON.parse(localStorage.getItem('univai_user') || '{}');
    const mode = localStorage.getItem('univai_mode');
    
    if (mode === 'demo') {
        // Demo Mode: Auto-fill and disable AWS credentials
        const accessKeyField = document.getElementById('aws-access-key');
        const secretKeyField = document.getElementById('aws-secret-key');
        
        if (accessKeyField && secretKeyField) {
            accessKeyField.value = TEST_CREDENTIALS.accessKey;
            secretKeyField.value = TEST_CREDENTIALS.secretKey;
            accessKeyField.readOnly = true;
            secretKeyField.readOnly = true;
            accessKeyField.style.backgroundColor = '#F3F4F6';
            secretKeyField.style.backgroundColor = '#F3F4F6';
            accessKeyField.style.cursor = 'not-allowed';
            secretKeyField.style.cursor = 'not-allowed';
        }
        
        // Show demo mode indicator
        const demoNotice = document.createElement('div');
        demoNotice.style.cssText = 'background: #FEF3C7; border: 2px solid #F59E0B; border-radius: 8px; padding: 12px 16px; margin-bottom: 16px; display: flex; align-items: center; gap: 10px;';
        demoNotice.innerHTML = '<i class="fas fa-flask" style="color: #F59E0B; font-size: 20px;"></i><div><strong style="color: #92400E;">Demo Mode Active</strong><br><span style="font-size: 13px; color: #78350F;">AWS credentials are pre-filled and locked. No real resources will be created.</span></div>';
        
        const form = document.getElementById('deploy-form');
        if (form && form.firstChild) {
            form.insertBefore(demoNotice, form.firstChild);
        }
        
        // Update tier badge
        const tierBadge = document.getElementById('tier-badge');
        if (tierBadge) {
            tierBadge.textContent = 'Demo (All Features Unlocked)';
            tierBadge.style.background = 'linear-gradient(135deg, #F59E0B, #D97706)';
            tierBadge.style.color = 'white';
        }
    } else if (mode === 'real') {
        // Real Mode: Check if user has selected a plan OR coming from pricing page
        const pendingDeployment = sessionStorage.getItem('pendingDeployment');
        
        if ((!user.tier || user.tier === 'free') && !pendingDeployment) {
            alert('⚠️ Please select a subscription plan first');
            window.location.href = 'pricing.html';
            return;
        }
        
        // Show real mode indicator
        const realNotice = document.createElement('div');
        realNotice.style.cssText = 'background: #DBEAFE; border: 2px solid #3B82F6; border-radius: 8px; padding: 12px 16px; margin-bottom: 16px; display: flex; align-items: center; gap: 10px;';
        realNotice.innerHTML = '<i class="fas fa-rocket" style="color: #3B82F6; font-size: 20px;"></i><div><strong style="color: #1E3A8A;">Real Mode Active</strong><br><span style="font-size: 13px; color: #1E40AF;">Enter your AWS credentials. Real infrastructure will be created.</span></div>';
        
        const form = document.getElementById('deploy-form');
        if (form && form.firstChild) {
            form.insertBefore(realNotice, form.firstChild);
        }
    }
});

// ============================================
// DEMO MODE - Test Credentials
// ============================================
const DEMO_MODE = true; // Set false untuk production
const TEST_CREDENTIALS = {
    accessKey: 'AKIAIOSFODNN7EXAMPLE',
    secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    region: 'us-east-1'
};

// Demo mode messages
function isDemoMode(accessKey, secretKey) {
    const mode = localStorage.getItem('univai_mode');
    return mode === 'demo' || (DEMO_MODE && (
        accessKey === TEST_CREDENTIALS.accessKey || 
        accessKey === 'test' || 
        accessKey.includes('EXAMPLE')
    ));
}
// ============================================

// Pricing tiers configuration
const PRICING_TIERS = {
    demo: {
        name: "Demo (All Features Unlocked)",
        modules: ["self-service-portal", "aiops", "zero-trust", "disaster-recovery", "compliance", "finops", "multi-cloud", "gitops", "service-mesh", "observability"],
        maxModules: 10,
        color: "#F59E0B"
    },
    free: {
        name: "Free",
        modules: ["self-service-portal"],
        maxModules: 1,
        color: "#6B7280"
    },
    professional: {
        name: "Professional",
        modules: ["self-service-portal", "observability", "gitops", "service-mesh", "finops"],
        maxModules: 3,
        color: "#0066FF"
    },
    enterprise: {
        name: "Enterprise",
        modules: ["self-service-portal", "observability", "gitops", "zero-trust", "disaster-recovery", "compliance", "finops", "service-mesh"],
        maxModules: 7,
        color: "#0066FF"
    },
    ultimate: {
        name: "Ultimate",
        modules: ["self-service-portal", "aiops", "zero-trust", "disaster-recovery", "compliance", "finops", "multi-cloud", "gitops", "service-mesh", "observability"],
        maxModules: 10,
        color: "#8B5CF6"
    }
};

// Module definitions
const MODULES = {
    "self-service-portal": {
        name: "Self-Service Portal",
        description: "IDP with 10-min provisioning",
        price: "$40-80K",
        resources: 12,
        icon: "🎯",
        features: ["Instant provisioning", "AWS/Azure/GCP", "Self-service access"]
    },
    "aiops": {
        name: "AIOps",
        description: "AI-driven operations with 70% noise reduction",
        price: "$30-60K",
        resources: 18,
        icon: "🤖",
        features: ["Anomaly detection", "Auto-remediation", "Predictive insights"]
    },
    "zero-trust": {
        name: "Zero Trust Security",
        description: "5-tier network segmentation",
        price: "$25-40K",
        resources: 15,
        icon: "🔒"
    },
    "disaster-recovery": {
        name: "Disaster Recovery",
        description: "15-min RTO, cross-region failover",
        price: "$15-30K",
        resources: 22,
        icon: "🛡️",
        features: ["Automated backups", "Cross-region replication", "Fast recovery"]
    },
    "compliance": {
        name: "Advanced Compliance",
        description: "6 AWS Config rules with auto-remediation",
        price: "$20-35K",
        resources: 14,
        icon: "✅",
        features: ["Policy as code", "Compliance dashboard", "Auto-remediation"]
    },
    "finops": {
        name: "FinOps Optimization",
        description: "ML-powered cost optimization",
        price: "$10-20K",
        resources: 16,
        icon: "💰",
        features: ["Cost forecasting", "Resource optimization", "Budget alerts"]
    },
    "multi-cloud": {
        name: "Multi-Cloud Support",
        description: "Unified API for AWS, Azure, GCP",
        price: "$20-50K",
        resources: 10,
        icon: "☁️",
        features: ["Cloud abstraction", "Vendor flexibility", "Unified management"]
    },
    "gitops": {
        name: "GitOps & CI/CD",
        description: "Git as single source of truth",
        price: "$15-25K",
        resources: 12,
        icon: "🔄",
        features: ["ArgoCD/Flux", "Auto-sync", "Version control"]
    },
    "service-mesh": {
        name: "Service Mesh",
        description: "AWS App Mesh with mTLS",
        price: "$18-30K",
        resources: 8,
        icon: "🕸️",
        features: ["Traffic management", "Service discovery", "Observability"]
    },
    "observability": {
        name: "Observability 2.0",
        description: "Unified metrics, logs, traces",
        price: "$15-25K",
        resources: 9,
        icon: "📊",
        features: ["OpenTelemetry", "Distributed tracing", "Custom dashboards"]
    }
};

// Function to toggle section collapse
function toggleSection(headerElement) {
    const section = headerElement.closest('.collapsible-section');
    section.classList.toggle('collapsed');
}

// Function to update module count badge
function updateModuleCount() {
    const countBadge = document.querySelector('.module-count-badge');
    if (countBadge) {
        const count = window.selectedModules ? window.selectedModules.length : 0;
        countBadge.textContent = count === 0 ? '0 selected' : `${count} selected`;
        countBadge.style.background = count > 0 ? '#10B981' : '#0066FF';
    }
}

// Initialize modules and tier when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Get tier from URL parameter or localStorage
    const urlParams = new URLSearchParams(window.location.search);
    const user = JSON.parse(localStorage.getItem('univai_user') || '{}');
    const mode = localStorage.getItem('univai_mode');
    const isInDemoMode = mode === 'demo';
    const currentTier = isInDemoMode ? 'demo' : (urlParams.get('tier') || user.tier || 'free');
    const tierConfig = PRICING_TIERS[currentTier];

    // Update tier badge
    const tierBadge = document.getElementById('tier-badge');
    if (tierBadge) {
        tierBadge.textContent = tierConfig.name;
        if (currentTier === 'ultimate') {
            tierBadge.classList.add('ultimate');
        } else if (currentTier === 'enterprise') {
            tierBadge.classList.add('enterprise');
        }
    }

    // Populate module grid with cards
    const moduleGrid = document.getElementById('module-grid');
    window.selectedModules = [];

    if (moduleGrid) {
        // Clear existing content
        moduleGrid.innerHTML = '';
        
        // Add all modules as cards
        Object.keys(MODULES).forEach(moduleId => {
            const module = MODULES[moduleId];
            const isAvailable = tierConfig.modules.includes(moduleId);
            
            const card = document.createElement('div');
            card.className = `module-card ${!isAvailable ? 'disabled' : ''}`;
            card.dataset.moduleId = moduleId;
            card.setAttribute('data-module-id', moduleId);
            
            const featuresHTML = module.features ? module.features.map(f => 
                `<span><i class="fas fa-check"></i> ${f}</span>`
            ).join('') : '';
            
            card.innerHTML = `
                <div class="module-checkbox-wrapper">
                    <input type="checkbox" 
                           class="module-checkbox" 
                           id="module-${moduleId}" 
                           value="${moduleId}" 
                           ${!isAvailable ? 'disabled' : ''}>
                </div>
                <div class="module-card-content">
                    <div class="module-card-header">
                        <div class="module-card-title">${module.name}</div>
                        ${!isAvailable ? '<span class="module-card-badge">Upgrade Required</span>' : ''}
                    </div>
                    <div class="module-card-desc">${module.description}</div>
                </div>
            `;
            
            // Click handler for card
            if (isAvailable) {
                card.addEventListener('click', function(e) {
                    if (e.target.type !== 'checkbox') {
                        const checkbox = this.querySelector('.module-checkbox');
                        checkbox.checked = !checkbox.checked;
                        checkbox.dispatchEvent(new Event('change'));
                    }
                });
                
                // Checkbox change handler
                const checkbox = card.querySelector('.module-checkbox');
                checkbox.addEventListener('change', function() {
                    if (this.checked) {
                        card.classList.add('selected');
                        if (!window.selectedModules.includes(moduleId)) {
                            window.selectedModules.push(moduleId);
                        }
                    } else {
                        card.classList.remove('selected');
                        window.selectedModules = window.selectedModules.filter(m => m !== moduleId);
                    }
                    updateModuleCount();
                    console.log('Selected modules:', window.selectedModules);
                });
            }
            
            moduleGrid.appendChild(card);
        });
    }
    
    // Select All button handler
    const selectAllBtn = document.getElementById('select-all-btn');
    if (selectAllBtn) {
        selectAllBtn.addEventListener('click', function() {
            const allCheckboxes = document.querySelectorAll('.module-checkbox:not(:disabled)');
            const allChecked = Array.from(allCheckboxes).every(cb => cb.checked);
            
            allCheckboxes.forEach(checkbox => {
                checkbox.checked = !allChecked;
                checkbox.dispatchEvent(new Event('change'));
            });
            
            this.innerHTML = allChecked 
                ? '<i class="fas fa-check-double"></i> Select All Modules'
                : '<i class="fas fa-times"></i> Deselect All';
        });
    }

    // Check for pending deployment from pricing page
    const pendingDeployment = sessionStorage.getItem('pendingDeployment');
    if (pendingDeployment) {
        try {
            const deploymentData = JSON.parse(pendingDeployment);
            
            // Auto-select modules from pricing page
            if (deploymentData.modules && deploymentData.modules.length > 0) {
                deploymentData.modules.forEach(moduleId => {
                    const checkbox = document.getElementById(`module-${moduleId}`);
                    if (checkbox && !checkbox.disabled) {
                        checkbox.checked = true;
                        checkbox.dispatchEvent(new Event('change'));
                    }
                });
                
                console.log('✅ Auto-selected modules from pricing:', deploymentData.modules);
            }
        } catch (error) {
            console.error('Error loading pending deployment:', error);
        }
    }
});

// Module selector toggle - set after modules are populated
const moduleHeaderToggle = document.getElementById('moduleHeaderToggle');

if (moduleHeaderToggle && moduleSelector) {
    moduleHeaderToggle.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        this.classList.toggle('active');
        moduleSelector.classList.toggle('collapsed');
    });
}

function showUpgradeNotice() {
    const notice = document.getElementById('upgrade-notice');
    notice.style.display = 'block';
    notice.innerHTML = `
        <div class="upgrade-notice">
            <i class="fas fa-lock"></i>
            <p><strong>Module limit reached!</strong> Upgrade to select more modules.</p>
            <a href="pricing.html">Upgrade Plan</a>
        </div>
    `;
}

function updateUpgradeNotice() {
    const notice = document.getElementById('upgrade-notice');
    // Don't show upgrade notice in demo mode or ultimate tier
    if (isInDemoMode || currentTier === 'ultimate') {
        notice.style.display = 'none';
        return;
    }
    if (selectedModules.length >= tierConfig.maxModules) {
        notice.style.display = 'block';
        const nextTier = currentTier === 'free' ? 'Professional' : 
                         currentTier === 'professional' ? 'Enterprise' : 'Ultimate';
        notice.innerHTML = `
            <div class="upgrade-notice">
                <i class="fas fa-info-circle"></i>
                <p>Want more modules? <strong>Upgrade to ${nextTier}</strong> for additional capabilities.</p>
                <a href="pricing.html">View Plans</a>
            </div>
        `;
    } else {
        notice.style.display = 'none';
    }
}

// Console logging
function addConsoleLog(message, type = 'info') {
    const console = document.getElementById('console');
    const line = document.createElement('div');
    line.className = `console-line ${type}`;
    
    const timestamp = new Date().toLocaleTimeString();
    const icon = type === 'success' ? 'check' : 
                 type === 'error' ? 'times' : 
                 type === 'warning' ? 'exclamation-triangle' : 'info-circle';
    
    line.innerHTML = `<i class="fas fa-${icon}"></i> [${timestamp}] ${message}`;
    console.appendChild(line);
    console.scrollTop = console.scrollHeight;
}

// Format rupiah
function formatRupiah(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(amount);
}

// Update progress
function updateProgress(percent, status) {
    document.getElementById('progress-fill').style.width = percent + '%';
    document.getElementById('progress-percent').textContent = percent + '%';
    document.getElementById('progress-status').textContent = status;
}

// Update module status
function updateModuleStatus(moduleId, status) {
    const moduleProgress = document.getElementById('module-progress');
    let statusBadge = document.getElementById(`status-${moduleId}`);
    
    if (!statusBadge) {
        statusBadge = document.createElement('div');
        statusBadge.id = `status-${moduleId}`;
        statusBadge.className = `module-status ${status}`;
        moduleProgress.appendChild(statusBadge);
    } else {
        statusBadge.className = `module-status ${status}`;
    }
    
    const icons = {
        pending: 'clock',
        running: 'spinner fa-spin',
        success: 'check-circle',
        error: 'times-circle'
    };
    
    statusBadge.innerHTML = `
        <i class="fas fa-${icons[status]}"></i>
        ${MODULES[moduleId].name}
    `;
}

// Simulate deployment (replace with real WebSocket connection)
async function simulateDeployment(config) {
    const deployBtn = document.getElementById('deploy-btn');
    deployBtn.disabled = true;
    deployBtn.classList.add('deploying');
    deployBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> <span>Deploying...</span>';
    
    // Reset workflow
    resetWorkflow();
    
    const startTime = Date.now();
    
    addConsoleLog('🚀 Starting deployment process...', 'info');
    addConsoleLog(`Project: ${config.projectName}`, 'info');
    addConsoleLog(`Environment: ${config.environment}`, 'info');
    addConsoleLog(`Region: ${config.awsRegion}`, 'info');
    addConsoleLog(`Modules: ${selectedModules.length}`, 'info');
    
    // Start workflow animation
    animateWorkflow();
    
    await sleep(1000);
    
    addConsoleLog('✓ AWS credentials validated', 'success');
    await sleep(500);
    
    addConsoleLog('✓ Initializing Terraform backend...', 'info');
    await sleep(1500);
    
    addConsoleLog('✓ Backend initialized successfully', 'success');
    updateProgress(10, 'Backend initialized');
    await sleep(500);
    
    // Deploy each module
    let totalResources = 0;
    for (let i = 0; i < selectedModules.length; i++) {
        const moduleId = selectedModules[i];
        const module = MODULES[moduleId];
        const progress = 10 + (80 / selectedModules.length) * i;
        
        updateModuleStatus(moduleId, 'running');
        addConsoleLog(`📦 Deploying module: ${module.name}...`, 'info');
        updateProgress(progress, `Deploying ${module.name}...`);
        
        await sleep(2000);
        
        addConsoleLog(`  → Creating ${module.resources} AWS resources...`, 'info');
        await sleep(1500);
        
        addConsoleLog(`  → Configuring security groups...`, 'info');
        await sleep(1000);
        
        addConsoleLog(`  → Setting up monitoring...`, 'info');
        await sleep(1000);
        
        addConsoleLog(`✓ ${module.name} deployed successfully!`, 'success');
        updateModuleStatus(moduleId, 'success');
        totalResources += module.resources;
        
        await sleep(500);
    }
    
    // Complete workflow animation
    completeWorkflow();
    
    updateProgress(90, 'Finalizing deployment...');
    addConsoleLog('🔧 Running post-deployment checks...', 'info');
    await sleep(1500);
    
    addConsoleLog('✓ Health checks passed', 'success');
    await sleep(500);
    
    addConsoleLog('✓ Monitoring configured', 'success');
    await sleep(500);
    
    addConsoleLog('✓ Outputs generated', 'success');
    await sleep(500);
    
    updateProgress(100, 'Deployment complete!');
    
    const duration = Math.round((Date.now() - startTime) / 1000);
    const minutes = Math.floor(duration / 60);
    const seconds = duration % 60;
    
    addConsoleLog('', 'info');
    addConsoleLog('═══════════════════════════════════════', 'success');
    addConsoleLog('🎉 DEPLOYMENT SUCCESSFUL!', 'success');
    addConsoleLog('═══════════════════════════════════════', 'success');
    addConsoleLog(`⏱️  Duration: ${minutes}m ${seconds}s`, 'info');
    addConsoleLog(`📊 Resources Created: ${totalResources}`, 'info');
    addConsoleLog(`📦 Modules Deployed: ${selectedModules.length}`, 'info');
    addConsoleLog('', 'info');
    addConsoleLog('Next steps:', 'info');
    addConsoleLog('1. Check AWS Console for deployed resources', 'info');
    addConsoleLog('2. Review CloudWatch logs for application status', 'info');
    addConsoleLog('3. Access your Self-Service Portal URL', 'info');
    
    // Show summary
    const summary = document.getElementById('deployment-summary');
    summary.classList.add('show');
    document.getElementById('summary-time').textContent = `${minutes}m ${seconds}s`;
    document.getElementById('summary-resources').textContent = totalResources;
    document.getElementById('summary-modules').textContent = selectedModules.length;
    
    deployBtn.disabled = false;
    deployBtn.classList.remove('deploying');
    deployBtn.innerHTML = '<i class="fas fa-redo"></i> <span>Deploy Again</span>';
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Play buzzer sound
function playBuzzer(duration = 3000) {
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = 800; // Buzzer frequency
    oscillator.type = 'square'; // Square wave for buzzer sound
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration / 1000);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + duration / 1000);
}

// Validate AWS credentials format
function validateAWSCredentials(accessKey, secretKey) {
    // AWS Access Key ID format: 20 characters, starts with AKIA
    const accessKeyPattern = /^AKIA[0-9A-Z]{16}$/;
    
    // AWS Secret Access Key format: 40 characters, base64-like
    const secretKeyPattern = /^[A-Za-z0-9/+=]{40}$/;
    
    const isAccessKeyValid = accessKeyPattern.test(accessKey);
    const isSecretKeyValid = secretKeyPattern.test(secretKey);
    
    return {
        valid: isAccessKeyValid && isSecretKeyValid,
        accessKeyValid: isAccessKeyValid,
        secretKeyValid: isSecretKeyValid
    };
}

// Show credential error in workflow
function showCredentialError(validation) {
    const moduleProgress = document.getElementById('module-progress');
    
    // Clear existing status
    moduleProgress.innerHTML = '';
    
    // Create error indicator
    const errorIndicator = document.createElement('div');
    errorIndicator.className = 'module-status error';
    errorIndicator.style.cssText = 'animation: shake 0.5s; background: #FEE2E2; border-left: 4px solid #EF4444; padding: 12px; margin-bottom: 8px; border-radius: 8px;';
    
    let errorMessage = '<i class="fas fa-times-circle" style="color: #EF4444;"></i> <strong>AWS Credentials Invalid</strong><br>';
    
    if (!validation.accessKeyValid) {
        errorMessage += '<small style="color: #991B1B;">• Access Key ID format is invalid (must be 20 chars starting with AKIA)</small><br>';
    }
    
    if (!validation.secretKeyValid) {
        errorMessage += '<small style="color: #991B1B;">• Secret Access Key format is invalid (must be 40 chars)</small>';
    }
    
    errorIndicator.innerHTML = errorMessage;
    moduleProgress.appendChild(errorIndicator);
    
    // Add shake animation if not exists
    if (!document.getElementById('shake-animation')) {
        const style = document.createElement('style');
        style.id = 'shake-animation';
        style.textContent = `
            @keyframes shake {
                0%, 100% { transform: translateX(0); }
                10%, 30%, 50%, 70%, 90% { transform: translateX(-10px); }
                20%, 40%, 60%, 80% { transform: translateX(10px); }
            }
        `;
        document.head.appendChild(style);
    }
}

// Form submission
document.getElementById('deploy-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    if (!window.selectedModules || window.selectedModules.length === 0) {
        addConsoleLog('❌ Please select at least one module to deploy', 'error');
        return;
    }
    
    // Store credentials before clearing console
    const awsAccessKey = document.getElementById('aws-access-key').value;
    const awsSecretKey = document.getElementById('aws-secret-key').value;
    const awsRegion = document.getElementById('aws-region').value;
    const projectName = document.getElementById('project-name').value;
    const environment = document.getElementById('environment').value;
    
    const config = {
        awsAccessKey: awsAccessKey,
        awsSecretKey: awsSecretKey,
        awsRegion: awsRegion,
        projectName: projectName,
        environment: environment,
        modules: window.selectedModules,
        tier: localStorage.getItem('univai_mode') === 'demo' ? 'demo' : 'free'
    };
    
    // Get current mode
    const currentMode = localStorage.getItem('univai_mode');
    
    // Validate AWS credentials format ONLY if NOT in demo mode
    if (currentMode !== 'demo') {
        const validation = validateAWSCredentials(config.awsAccessKey, config.awsSecretKey);
        
        if (!validation.valid) {
            // Show error in console
            addConsoleLog('═══════════════════════════════════════', 'error');
            addConsoleLog('❌ AWS CREDENTIALS VALIDATION FAILED', 'error');
            addConsoleLog('═══════════════════════════════════════', 'error');
            
            if (!validation.accessKeyValid) {
                addConsoleLog('✗ AWS Access Key ID format is invalid', 'error');
                addConsoleLog('  Expected: 20 characters starting with "AKIA"', 'info');
                addConsoleLog('  Example: AKIAIOSFODNN7EXAMPLE', 'info');
            }
            
            if (!validation.secretKeyValid) {
                addConsoleLog('✗ AWS Secret Access Key format is invalid', 'error');
                addConsoleLog('  Expected: 40 characters (base64-like)', 'info');
                addConsoleLog('  Example: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY', 'info');
            }
            
            addConsoleLog('', 'error');
            addConsoleLog('⚠️  Please check your AWS credentials and try again', 'warning');
            addConsoleLog('💡 Tip: You can find your credentials in AWS IAM Console', 'info');
            
            // Show error indicator in workflow
            showCredentialError(validation);
            
            // Play buzzer sound for 3 seconds
            playBuzzer(3000);
            
            // Update progress to error state
            updateProgress(0, 'Credential validation failed');
            document.getElementById('progress-fill').style.background = '#EF4444';
            
            return;
        }
        
        // If valid, show success message
        addConsoleLog('✓ AWS credentials format validated', 'success');
    }
    
    // Clear previous logs (but keep credentials in form)
    const consoleEl = document.getElementById('console');
    consoleEl.innerHTML = '';
    document.getElementById('module-progress').innerHTML = '';
    document.getElementById('deployment-summary').classList.remove('show');
    updateProgress(0, 'Initializing deployment...');
    
    // Initialize module statuses
    window.selectedModules.forEach(moduleId => {
        updateModuleStatus(moduleId, 'pending');
    });
    
    // Check mode from localStorage
    const mode = localStorage.getItem('univai_mode');
    
    if (mode === 'demo') {
        // DEMO MODE - Using test credentials (free)
        addConsoleLog('🔧 DEMO MODE ACTIVATED', 'warning');
        addConsoleLog('Using test credentials - No real AWS resources will be created', 'info');
        addConsoleLog('All features unlocked for free testing', 'info');
    } else {
        // REAL MODE - Deploy to actual AWS
        addConsoleLog('🚀 Starting REAL deployment to AWS...', 'info');
        addConsoleLog('⚠️  Backend integration coming soon - Running simulation', 'warning');
    }
    
    // Run deployment simulation (same flow for both modes)
    await runDemoDeployment(config);
    
    /* TODO: Enable when backend is ready
    // Disable deploy button
    const deployBtn = document.getElementById('deploy-btn');
    deployBtn.disabled = true;
    deployBtn.classList.add('deploying');
    deployBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> <span>Deploying...</span>';
    
    try {
        // Check if socket.io is loaded
        if (typeof io === 'undefined') {
            throw new Error('Socket.IO library not loaded. Please refresh the page and try again.');
        }
        
        // Connect to Railway backend via WebSocket
        const socket = io('https://cloud-infrastructure-automation-production.up.railway.app', {
            timeout: 10000,
            reconnection: false
        });
        
        // Set connection timeout
        const connectionTimeout = setTimeout(() => {
            socket.close();
            throw new Error('Backend connection timeout. Please check your internet connection and try again.');
        }, 10000);
        
        socket.on('connect', () => {
            clearTimeout(connectionTimeout);
            addConsoleLog('✅ Connected to CloudStack deployment backend', 'success');
            addConsoleLog('📡 Establishing secure connection to AWS...', 'info');
            
            // Emit deployment request
            socket.emit('deploy', config);
        });
        
        socket.on('connect_error', (error) => {
            clearTimeout(connectionTimeout);
            addConsoleLog('❌ Failed to connect to deployment backend', 'error');
            addConsoleLog(`Error: ${error.message}`, 'error');
            addConsoleLog('', 'error');
            addConsoleLog('Possible causes:', 'warning');
            addConsoleLog('• Backend server is temporarily unavailable', 'info');
            addConsoleLog('• Your internet connection is unstable', 'info');
            addConsoleLog('• Firewall is blocking the connection', 'info');
            addConsoleLog('', 'info');
            addConsoleLog('💡 Please try again in a few moments', 'info');
            
            updateProgress(0, 'Connection failed');
            document.getElementById('progress-fill').style.background = '#EF4444';
            
            deployBtn.disabled = false;
            deployBtn.classList.remove('deploying');
            deployBtn.innerHTML = '<i class="fas fa-rocket"></i> <span>Start Deployment</span>';
        });
        
        socket.on('log', (data) => {
            addConsoleLog(data.message, data.type);
        });
        
        socket.on('progress', (data) => {
            updateProgress(data.percent, data.status);
        });
        
        socket.on('module-status', (data) => {
            updateModuleStatus(data.moduleId, data.status);
        });
        
        socket.on('complete', (data) => {
            const minutes = Math.floor(data.duration / 60);
            const seconds = data.duration % 60;
            
            addConsoleLog('', 'success');
            addConsoleLog('═══════════════════════════════════════', 'success');
            addConsoleLog('🎉 DEPLOYMENT SUCCESSFUL!', 'success');
            addConsoleLog('═══════════════════════════════════════', 'success');
            
            const summary = document.getElementById('deployment-summary');
            summary.classList.add('show');
            document.getElementById('summary-time').textContent = `${minutes}m ${seconds}s`;
            document.getElementById('summary-resources').textContent = data.totalResources;
            document.getElementById('summary-modules').textContent = data.modulesDeployed;
            
            // Save deployment to localStorage for dashboard
            saveDeployment({
                projectName: config.projectName,
                environment: config.environment,
                awsRegion: config.awsRegion,
                modules: config.modules,
                tier: config.tier,
                status: 'completed',
                timestamp: Date.now(),
                duration: `${minutes}m ${seconds}s`,
                resources: data.totalResources,
                isDemo: false
            });
            
            deployBtn.disabled = false;
            deployBtn.classList.remove('deploying');
            deployBtn.innerHTML = '<i class="fas fa-redo"></i> <span>Deploy Again</span>';
        });
        
        socket.on('error', (data) => {
            addConsoleLog('', 'error');
            addConsoleLog('═══════════════════════════════════════', 'error');
            addConsoleLog(`❌ DEPLOYMENT FAILED: ${data.message}`, 'error');
            addConsoleLog('═══════════════════════════════════════', 'error');
            
            // Save failed deployment
            saveDeployment({
                projectName: config.projectName,
                environment: config.environment,
                awsRegion: config.awsRegion,
                modules: config.modules,
                tier: config.tier,
                status: 'failed',
                timestamp: Date.now(),
                error: data.message,
                isDemo: false
            });
            
            updateProgress(0, 'Deployment failed');
            document.getElementById('progress-fill').style.background = '#EF4444';
            
            deployBtn.disabled = false;
            deployBtn.classList.remove('deploying');
            deployBtn.innerHTML = '<i class="fas fa-rocket"></i> <span>Start Deployment</span>';
        });
        
        socket.on('disconnect', () => {
            addConsoleLog('⚠️  Connection to backend lost', 'warning');
            addConsoleLog('Attempting to reconnect...', 'info');
        });
        
    } catch (error) {
        addConsoleLog('', 'error');
        addConsoleLog('═══════════════════════════════════════', 'error');
        addConsoleLog('❌ DEPLOYMENT INITIALIZATION FAILED', 'error');
        addConsoleLog('═══════════════════════════════════════', 'error');
        addConsoleLog(`Error: ${error.message}`, 'error');
        addConsoleLog('', 'info');
        addConsoleLog('Please check:', 'warning');
        addConsoleLog('• Your internet connection is stable', 'info');
        addConsoleLog('• No browser extensions are blocking connections', 'info');
        addConsoleLog('• Try refreshing the page and deploying again', 'info');
        
        updateProgress(0, 'Initialization failed');
        document.getElementById('progress-fill').style.background = '#EF4444';
        
        deployBtn.disabled = false;
        deployBtn.classList.remove('deploying');
        deployBtn.innerHTML = '<i class="fas fa-rocket"></i> <span>Start Deployment</span>';
    }
    */
});

// Initialize console
addConsoleLog(`Konsol Penerapan UnivAI Cloud v2.0`, 'info');
addConsoleLog(`Connected to CloudStack deployment platform`, 'success');
addConsoleLog(`Your tier: ${tierConfig.name} (${tierConfig.maxModules} modules max)`, 'info');

// Display pre-selected modules from pricing page
const checkPendingDeployment = sessionStorage.getItem('pendingDeployment');
if (checkPendingDeployment) {
    try {
        const deploymentData = JSON.parse(checkPendingDeployment);
        if (deploymentData.modules && deploymentData.modules.length > 0) {
            addConsoleLog('', 'info');
            addConsoleLog('═══════════════════════════════════════', 'success');
            addConsoleLog(`📦 ${deploymentData.modules.length} Module Terpilih dari Pricing`, 'success');
            addConsoleLog('═══════════════════════════════════════', 'success');
            addConsoleLog('', 'info');
            
            deploymentData.modules.forEach((moduleId, index) => {
                const module = MODULES[moduleId];
                if (module) {
                    addConsoleLog(`  ${index + 1}. ${module.name}`, 'info');
                    addConsoleLog(`     ${module.description}`, 'info');
                }
            });
            
            addConsoleLog('', 'info');
            addConsoleLog('═══════════════════════════════════════', 'info');
            addConsoleLog('⚙️  Konfigurasi:', 'info');
            addConsoleLog('═══════════════════════════════════════', 'info');
            addConsoleLog(`   • Environment: ${deploymentData.config?.environment || 'dev'}`, 'info');
            addConsoleLog(`   • Region: ${deploymentData.config?.region || 'single'}`, 'info');
            addConsoleLog(`   • Availability: ${deploymentData.config?.availability || 'standard'}`, 'info');
            addConsoleLog('', 'info');
            addConsoleLog('═══════════════════════════════════════', 'success');
            addConsoleLog(`💰 Total Biaya: ${deploymentData.tokens?.toFixed(1) || '0'} tokens`, 'success');
            addConsoleLog(`   ${formatRupiah(deploymentData.cost || 0)}`, 'success');
            addConsoleLog('═══════════════════════════════════════', 'success');
        }
    } catch (error) {
        console.error('Error displaying pending deployment:', error);
    }
}

addConsoleLog(`Ready to deploy to AWS region of your choice`, 'success');

// Workflow Visualization Functions
function updateWorkflowNode(nodeId, status) {
    const node = document.getElementById(`node-${nodeId}`);
    if (!node) return;
    
    // Remove all status classes
    node.classList.remove('running', 'completed', 'error');
    
    // Update node status class
    if (status === 'running') {
        node.classList.add('running');
    } else if (status === 'success') {
        node.classList.add('completed');
    } else if (status === 'error') {
        node.classList.add('error');
    }
    
    // Update status indicator
    const statusIndicator = node.querySelector('.node-status');
    if (statusIndicator) {
        statusIndicator.className = `node-status ${status}`;
        
        // Update icon based on status
        const icon = statusIndicator.querySelector('i');
        if (icon) {
            if (status === 'running') {
                icon.className = 'fas fa-spinner';
            } else if (status === 'success') {
                icon.className = 'fas fa-check';
            } else if (status === 'error') {
                icon.className = 'fas fa-times';
            } else {
                icon.className = 'fas fa-circle';
            }
        }
    }
}

function updateWorkflowConnector(connectorId, active) {
    const connector = document.getElementById(`connector-${connectorId}`);
    if (!connector) return;
    
    if (active) {
        connector.classList.add('active');
    } else {
        connector.classList.remove('active');
    }
}

async function animateWorkflow() {
    // Start
    updateWorkflowNode('start', 'running');
    await sleep(1000);
    updateWorkflowNode('start', 'success');
    updateWorkflowConnector(1, true);
    await sleep(500);
    
    // Validate
    updateWorkflowNode('validate', 'running');
    await sleep(2000);
    updateWorkflowNode('validate', 'success');
    updateWorkflowConnector(2, true);
    await sleep(500);
    
    // Provision
    updateWorkflowNode('provision', 'running');
    await sleep(3000);
    updateWorkflowNode('provision', 'success');
    updateWorkflowConnector(3, true);
    await sleep(500);
    
    // Deploy Modules
    updateWorkflowNode('modules', 'running');
    // This will run during module deployment
}

async function completeWorkflow() {
    updateWorkflowNode('modules', 'success');
    updateWorkflowConnector(4, true);
    await sleep(500);
    
    // Configure
    updateWorkflowNode('configure', 'running');
    await sleep(2000);
    updateWorkflowNode('configure', 'success');
    updateWorkflowConnector(5, true);
    await sleep(500);
    
    // Test
    updateWorkflowNode('test', 'running');
    await sleep(1500);
    updateWorkflowNode('test', 'success');
    updateWorkflowConnector(6, true);
    await sleep(500);
    
    // Complete
    updateWorkflowNode('complete', 'running');
    await sleep(1000);
    updateWorkflowNode('complete', 'success');
}

function resetWorkflow() {
    const nodes = ['start', 'validate', 'provision', 'modules', 'configure', 'test', 'complete'];
    nodes.forEach(nodeId => {
        updateWorkflowNode(nodeId, 'pending');
    });
    
    for (let i = 1; i <= 6; i++) {
        updateWorkflowConnector(i, false);
    }
}

// ============================================
// DEMO MODE DEPLOYMENT SIMULATION
// ============================================
async function runDemoDeployment(config) {
    const deployBtn = document.getElementById('deploy-btn');
    deployBtn.disabled = true;
    deployBtn.classList.add('deploying');
    deployBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> <span>Deploying...</span>';
    
    // Clear previous logs
    const console = document.getElementById('console');
    console.innerHTML = '';
    document.getElementById('module-progress').innerHTML = '';
    document.getElementById('deployment-summary').classList.remove('show');
    
    // Initialize module statuses
    config.modules.forEach(moduleId => {
        updateModuleStatus(moduleId, 'pending');
    });
    
    resetWorkflow();
    await sleep(500);
    
    // Start deployment simulation
    addConsoleLog('═══════════════════════════════════════', 'info');
    addConsoleLog('🚀 CloudStack Deployment Started', 'success');
    addConsoleLog('═══════════════════════════════════════', 'info');
    addConsoleLog(`Project: ${config.projectName}`, 'info');
    addConsoleLog(`Environment: ${config.environment}`, 'info');
    addConsoleLog(`Region: ${config.awsRegion}`, 'info');
    addConsoleLog(`Tier: ${config.tier}`, 'info');
    addConsoleLog(`Modules: ${config.modules.length} selected`, 'info');
    addConsoleLog('', 'info');
    
    updateProgress(5, 'Initializing deployment...');
    
    // Step 1: Start
    updateWorkflowNode('start', 'running');
    addConsoleLog('📍 Step 1: Initialization', 'info');
    await sleep(1000);
    addConsoleLog('✅ Deployment session initialized', 'success');
    updateWorkflowNode('start', 'success');
    updateWorkflowConnector(1, true);
    updateProgress(10, 'Validating configuration...');
    await sleep(500);
    
    // Step 2: Validate
    updateWorkflowNode('validate', 'running');
    addConsoleLog('', 'info');
    addConsoleLog('📍 Step 2: Validation', 'info');
    await sleep(800);
    addConsoleLog('🔐 Validating AWS credentials (Demo Mode)', 'info');
    await sleep(1000);
    addConsoleLog('✅ Credentials validated', 'success');
    await sleep(800);
    addConsoleLog('📋 Checking IAM permissions', 'info');
    await sleep(1000);
    addConsoleLog('✅ All permissions available', 'success');
    updateWorkflowNode('validate', 'success');
    updateWorkflowConnector(2, true);
    updateProgress(20, 'Provisioning infrastructure...');
    await sleep(500);
    
    // Step 3: Provision
    updateWorkflowNode('provision', 'running');
    addConsoleLog('', 'info');
    addConsoleLog('📍 Step 3: Infrastructure Provisioning', 'info');
    await sleep(1000);
    addConsoleLog('🏗️  Creating VPC and subnets', 'info');
    await sleep(1500);
    addConsoleLog('✅ VPC created: vpc-0abc123def456', 'success');
    await sleep(1000);
    addConsoleLog('🔒 Setting up security groups', 'info');
    await sleep(1200);
    addConsoleLog('✅ Security groups configured', 'success');
    await sleep(1000);
    addConsoleLog('⚡ Provisioning EC2 instances', 'info');
    await sleep(1800);
    addConsoleLog('✅ EC2 instances running', 'success');
    updateWorkflowNode('provision', 'success');
    updateWorkflowConnector(3, true);
    updateProgress(40, 'Deploying modules...');
    await sleep(500);
    
    // Step 4: Deploy Modules
    updateWorkflowNode('modules', 'running');
    addConsoleLog('', 'info');
    addConsoleLog('📍 Step 4: Module Deployment', 'info');
    
    const totalModules = config.modules.length;
    for (let i = 0; i < totalModules; i++) {
        const moduleId = config.modules[i];
        const moduleConfig = MODULES[moduleId];
        
        await sleep(800);
        addConsoleLog(``, 'info');
        addConsoleLog(`📦 Deploying module ${i + 1}/${totalModules}: ${moduleConfig.name}`, 'info');
        updateModuleStatus(moduleId, 'deploying');
        
        await sleep(1000);
        addConsoleLog(`   └─ Installing Terraform modules`, 'info');
        await sleep(1500);
        addConsoleLog(`   └─ Creating ${moduleConfig.resources} AWS resources`, 'info');
        await sleep(2000);
        addConsoleLog(`   └─ Configuring services`, 'info');
        await sleep(1500);
        addConsoleLog(`✅ ${moduleConfig.name} deployed successfully`, 'success');
        updateModuleStatus(moduleId, 'success');
        
        const progress = 40 + ((i + 1) / totalModules) * 30;
        updateProgress(progress, `Deployed ${i + 1}/${totalModules} modules`);
    }
    
    updateWorkflowNode('modules', 'success');
    updateWorkflowConnector(4, true);
    updateProgress(70, 'Configuring environment...');
    await sleep(500);
    
    // Step 5: Configure
    updateWorkflowNode('configure', 'running');
    addConsoleLog('', 'info');
    addConsoleLog('📍 Step 5: Configuration', 'info');
    await sleep(1000);
    addConsoleLog('⚙️  Applying environment settings', 'info');
    await sleep(1500);
    addConsoleLog('✅ Environment configured', 'success');
    await sleep(1000);
    addConsoleLog('🔗 Setting up networking', 'info');
    await sleep(1200);
    addConsoleLog('✅ Network routing configured', 'success');
    updateWorkflowNode('configure', 'success');
    updateWorkflowConnector(5, true);
    updateProgress(85, 'Running tests...');
    await sleep(500);
    
    // Step 6: Test
    updateWorkflowNode('test', 'running');
    addConsoleLog('', 'info');
    addConsoleLog('📍 Step 6: Testing & Verification', 'info');
    await sleep(1000);
    addConsoleLog('🧪 Running health checks', 'info');
    await sleep(1500);
    addConsoleLog('✅ All services healthy', 'success');
    await sleep(1000);
    addConsoleLog('🔍 Verifying endpoints', 'info');
    await sleep(1200);
    addConsoleLog('✅ All endpoints accessible', 'success');
    updateWorkflowNode('test', 'success');
    updateWorkflowConnector(6, true);
    updateProgress(95, 'Finalizing...');
    await sleep(500);
    
    // Step 7: Complete
    updateWorkflowNode('complete', 'running');
    await sleep(1000);
    updateWorkflowNode('complete', 'success');
    updateProgress(100, 'Deployment completed');
    
    // Calculate demo resources
    let totalResources = 0;
    config.modules.forEach(moduleId => {
        totalResources += MODULES[moduleId].resources;
    });
    
    addConsoleLog('', 'info');
    addConsoleLog('═══════════════════════════════════════', 'success');
    addConsoleLog('🎉 Deployment Completed Successfully!', 'success');
    addConsoleLog('═══════════════════════════════════════', 'success');
    addConsoleLog(`✨ Total resources created: ${totalResources}`, 'success');
    addConsoleLog(`⏱️  Deployment time: ${Math.floor(Math.random() * 3) + 2}m ${Math.floor(Math.random() * 60)}s`, 'success');
    addConsoleLog('', 'info');
    addConsoleLog('📊 Demo Mode Summary:', 'warning');
    addConsoleLog('   • No real AWS resources were created', 'warning');
    addConsoleLog('   • This is a simulation for testing purposes', 'warning');
    addConsoleLog('   • Use real AWS credentials for production', 'warning');
    
    // Show summary
    const summary = document.getElementById('deployment-summary');
    summary.classList.add('show');
    const deploymentTime = `${Math.floor(Math.random() * 3) + 2}m ${Math.floor(Math.random() * 60)}s`;
    document.getElementById('summary-time').textContent = deploymentTime;
    document.getElementById('summary-resources').textContent = totalResources;
    document.getElementById('summary-modules').textContent = config.modules.length;
    
    // Save deployment to localStorage for dashboard
    saveDeployment({
        projectName: config.projectName,
        environment: config.environment,
        awsRegion: config.awsRegion,
        modules: config.modules,
        tier: config.tier,
        status: 'completed',
        timestamp: Date.now(),
        duration: deploymentTime,
        resources: totalResources,
        isDemo: true
    });
    
    // Reset button
    deployBtn.disabled = false;
    deployBtn.classList.remove('deploying');
    deployBtn.innerHTML = '<i class="fas fa-redo"></i> <span>Deploy Again</span>';
}

// Save deployment to localStorage
function saveDeployment(deployment) {
    try {
        let deployments = JSON.parse(localStorage.getItem('univai_deployments') || '[]');
        deployments.unshift(deployment); // Add to beginning
        
        // Keep only last 50 deployments
        if (deployments.length > 50) {
            deployments = deployments.slice(0, 50);
        }
        
        localStorage.setItem('univai_deployments', JSON.stringify(deployments));
        console.log('✅ Deployment saved to localStorage');
    } catch (e) {
        console.error('Failed to save deployment:', e);
    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
// ============================================