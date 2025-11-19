// Pricing tiers configuration
const PRICING_TIERS = {
    free: {
        name: "Free",
        modules: ["self-service-portal"],
        maxModules: 1,
        color: "#6B7280"
    },

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
    return DEMO_MODE && (
        accessKey === TEST_CREDENTIALS.accessKey || 
        accessKey === 'test' || 
        accessKey.includes('EXAMPLE')
    );
}
// ============================================

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
    
    // Check for demo mode
    if (isDemoMode(config.awsAccessKey, config.awsSecretKey)) {
        addConsoleLog('🔧 DEMO MODE ACTIVATED', 'warning');
        addConsoleLog('Using test credentials - No real AWS resources will be created', 'info');
        await runDemoDeployment(config);
        return;
    }
    
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
    
    // Connect to Railway backend via WebSocket
    const socket = io('https://cloud-infrastructure-automation-production.up.railway.app');
    
    socket.on('connect', () => {
        addConsoleLog('✅ Connected to CloudStack backend', 'success');
        
        // Emit deployment request
        socket.emit('deploy', config);
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
        
        const summary = document.getElementById('deployment-summary');
        summary.classList.add('show');
        document.getElementById('summary-time').textContent = `${minutes}m ${seconds}s`;
        document.getElementById('summary-resources').textContent = data.totalResources;
        document.getElementById('summary-modules').textContent = data.modulesDeployed;
        
        const deployBtn = document.getElementById('deploy-btn');
        deployBtn.disabled = false;
        deployBtn.classList.remove('deploying');
        deployBtn.innerHTML = '<i class="fas fa-redo"></i> <span>Deploy Again</span>';
    });
    
    socket.on('error', (data) => {
        addConsoleLog(`❌ Error: ${data.message}`, 'error');
        
        const deployBtn = document.getElementById('deploy-btn');
        deployBtn.disabled = false;
        deployBtn.classList.remove('deploying');
        deployBtn.innerHTML = '<i class="fas fa-rocket"></i> <span>Start Deployment</span>';
    });
    
    socket.on('disconnect', () => {
        addConsoleLog('⚠️  Disconnected from backend', 'warning');
    });
});

// Initialize
addConsoleLog(`Connected to CloudStack deployment platform`, 'info');
addConsoleLog(`Your tier: ${tierConfig.name} (${tierConfig.maxModules} modules max)`, 'info');
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
    document.getElementById('summary-time').textContent = `${Math.floor(Math.random() * 3) + 2}m ${Math.floor(Math.random() * 60)}s`;
    document.getElementById('summary-resources').textContent = totalResources;
    document.getElementById('summary-modules').textContent = config.modules.length;
    
    // Reset button
    deployBtn.disabled = false;
    deployBtn.classList.remove('deploying');
    deployBtn.innerHTML = '<i class="fas fa-redo"></i> <span>Deploy Again</span>';
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
// ============================================