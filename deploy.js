// Pricing tiers configuration
const PRICING_TIERS = {
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
        resources: 12
    },
    "aiops": {
        name: "AIOps",
        description: "AI-driven operations with 70% noise reduction",
        price: "$30-60K",
        resources: 18
    },
    "zero-trust": {
        name: "Zero Trust Security",
        description: "5-tier network segmentation",
        price: "$25-40K",
        resources: 15
    },
    "disaster-recovery": {
        name: "Disaster Recovery",
        description: "15-min RTO, cross-region failover",
        price: "$15-30K",
        resources: 22
    },
    "compliance": {
        name: "Advanced Compliance",
        description: "6 AWS Config rules with auto-remediation",
        price: "$20-35K",
        resources: 14
    },
    "finops": {
        name: "FinOps Optimization",
        description: "ML-powered cost optimization",
        price: "$10-20K",
        resources: 16
    },
    "multi-cloud": {
        name: "Multi-Cloud Support",
        description: "Unified API for AWS, Azure, GCP",
        price: "$20-50K",
        resources: 10
    },
    "gitops": {
        name: "GitOps & CI/CD",
        description: "Git as single source of truth",
        price: "$15-25K",
        resources: 12
    },
    "service-mesh": {
        name: "Service Mesh",
        description: "AWS App Mesh with mTLS",
        price: "$18-30K",
        resources: 8
    },
    "observability": {
        name: "Observability 2.0",
        description: "Unified metrics, logs, traces",
        price: "$15-25K",
        resources: 9
    }
};

// Get tier from URL parameter
const urlParams = new URLSearchParams(window.location.search);
const currentTier = urlParams.get('tier') || 'free';
const tierConfig = PRICING_TIERS[currentTier];

// Update tier badge
document.getElementById('tier-badge').textContent = tierConfig.name;
if (currentTier === 'ultimate') {
    document.getElementById('tier-badge').classList.add('ultimate');
} else if (currentTier === 'enterprise') {
    document.getElementById('tier-badge').classList.add('enterprise');
}

// Populate module selector
const moduleSelector = document.getElementById('module-selector');
let selectedModules = [];

Object.keys(MODULES).forEach(moduleId => {
    const module = MODULES[moduleId];
    const isAvailable = tierConfig.modules.includes(moduleId);
    
    const moduleOption = document.createElement('div');
    moduleOption.className = `module-option ${!isAvailable ? 'disabled' : ''}`;
    moduleOption.innerHTML = `
        <input type="checkbox" id="module-${moduleId}" value="${moduleId}" ${!isAvailable ? 'disabled' : ''}>
        <div class="module-info">
            <div class="module-name">${module.name}</div>
            <div class="module-desc">${module.description}</div>
        </div>
        <div class="module-price">${module.price}</div>
    `;
    
    if (isAvailable) {
        const checkbox = moduleOption.querySelector('input');
        checkbox.addEventListener('change', function() {
            if (this.checked) {
                if (selectedModules.length >= tierConfig.maxModules) {
                    this.checked = false;
                    showUpgradeNotice();
                    return;
                }
                selectedModules.push(moduleId);
                moduleOption.classList.add('selected');
            } else {
                selectedModules = selectedModules.filter(m => m !== moduleId);
                moduleOption.classList.remove('selected');
            }
            updateUpgradeNotice();
        });
    }
    
    moduleSelector.appendChild(moduleOption);
});

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
    if (selectedModules.length >= tierConfig.maxModules && currentTier !== 'ultimate') {
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
    
    const startTime = Date.now();
    
    addConsoleLog('🚀 Starting deployment process...', 'info');
    addConsoleLog(`Project: ${config.projectName}`, 'info');
    addConsoleLog(`Environment: ${config.environment}`, 'info');
    addConsoleLog(`Region: ${config.awsRegion}`, 'info');
    addConsoleLog(`Modules: ${selectedModules.length}`, 'info');
    
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

// Form submission
document.getElementById('deploy-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    if (selectedModules.length === 0) {
        addConsoleLog('❌ Please select at least one module to deploy', 'error');
        return;
    }
    
    const config = {
        awsAccessKey: document.getElementById('aws-access-key').value,
        awsSecretKey: document.getElementById('aws-secret-key').value,
        awsRegion: document.getElementById('aws-region').value,
        projectName: document.getElementById('project-name').value,
        environment: document.getElementById('environment').value,
        modules: selectedModules,
        tier: currentTier
    };
    
    // Clear previous logs
    const console = document.getElementById('console');
    console.innerHTML = '';
    document.getElementById('module-progress').innerHTML = '';
    document.getElementById('deployment-summary').classList.remove('show');
    updateProgress(0, 'Starting deployment...');
    
    // Initialize module statuses
    selectedModules.forEach(moduleId => {
        updateModuleStatus(moduleId, 'pending');
    });
    
    // Start deployment simulation
    await simulateDeployment(config);
    
    // In production, replace simulation with:
    /*
    const socket = io('https://your-heroku-backend.herokuapp.com');
    
    socket.emit('deploy', config);
    
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
        // Handle completion
    });
    */
});

// Initialize
addConsoleLog(`Connected to CloudStack deployment platform`, 'info');
addConsoleLog(`Your tier: ${tierConfig.name} (${tierConfig.maxModules} modules max)`, 'info');
addConsoleLog(`Ready to deploy to AWS region of your choice`, 'success');