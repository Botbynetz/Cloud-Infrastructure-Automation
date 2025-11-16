const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');
const { spawn } = require('child_process');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
    cors: {
        origin: process.env.FRONTEND_URL || '*',
        methods: ['GET', 'POST']
    }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Pricing tier configuration
const PRICING_TIERS = {
    free: { maxDeployments: 1, maxModules: 1, modules: ['self-service-portal'] },
    professional: { maxDeployments: 10, maxModules: 3, modules: ['self-service-portal', 'observability', 'gitops', 'service-mesh', 'finops'] },
    enterprise: { maxDeployments: 50, maxModules: 7, modules: ['self-service-portal', 'observability', 'gitops', 'zero-trust', 'disaster-recovery', 'compliance', 'finops', 'service-mesh'] },
    ultimate: { maxDeployments: -1, maxModules: 10, modules: ['all'] }
};

// Module definitions
const MODULES = {
    'self-service-portal': { name: 'Self-Service Portal', resources: 12, duration: 180 },
    'aiops': { name: 'AIOps', resources: 18, duration: 300 },
    'zero-trust': { name: 'Zero Trust Security', resources: 15, duration: 240 },
    'disaster-recovery': { name: 'Disaster Recovery', resources: 22, duration: 420 },
    'compliance': { name: 'Advanced Compliance', resources: 14, duration: 210 },
    'finops': { name: 'FinOps Optimization', resources: 16, duration: 270 },
    'multi-cloud': { name: 'Multi-Cloud Support', resources: 10, duration: 180 },
    'gitops': { name: 'GitOps & CI/CD', resources: 12, duration: 200 },
    'service-mesh': { name: 'Service Mesh', resources: 8, duration: 150 },
    'observability': { name: 'Observability 2.0', resources: 9, duration: 160 }
};

// In-memory deployment tracking (use PostgreSQL in production)
const deployments = new Map();

// Serve test page
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/test.html');
});

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', version: '1.0.0' });
});

// Get deployment status
app.get('/api/deploy/:jobId/status', (req, res) => {
    const deployment = deployments.get(req.params.jobId);
    if (!deployment) {
        return res.status(404).json({ error: 'Deployment not found' });
    }
    res.json(deployment);
});

// Validate tier and modules
function validateDeployment(config) {
    const tier = PRICING_TIERS[config.tier] || PRICING_TIERS.free;
    
    // Check module count
    if (config.modules.length > tier.maxModules) {
        return { valid: false, error: `${config.tier} tier limited to ${tier.maxModules} modules` };
    }
    
    // Check module availability
    if (tier.modules[0] !== 'all') {
        for (const moduleId of config.modules) {
            if (!tier.modules.includes(moduleId)) {
                return { valid: false, error: `Module ${moduleId} not available in ${config.tier} tier` };
            }
        }
    }
    
    return { valid: true };
}

// Execute Terraform deployment (simulated)
async function executeTerraform(config, socket) {
    const steps = [
        { message: '🚀 Starting deployment process...', type: 'info', progress: 0 },
        { message: `Project: ${config.projectName}`, type: 'info', progress: 0 },
        { message: `Environment: ${config.environment}`, type: 'info', progress: 0 },
        { message: `Region: ${config.awsRegion}`, type: 'info', progress: 0 },
        { message: `Modules: ${config.modules.length}`, type: 'info', progress: 0 },
        { message: '✓ AWS credentials validated', type: 'success', progress: 5, delay: 1000 },
        { message: '✓ Initializing Terraform backend...', type: 'info', progress: 10, delay: 1500 },
        { message: '✓ Backend initialized successfully', type: 'success', progress: 15, delay: 500 }
    ];
    
    // Send initial steps
    for (const step of steps) {
        await sleep(step.delay || 0);
        socket.emit('log', { message: step.message, type: step.type });
        if (step.progress > 0) {
            socket.emit('progress', { percent: step.progress, status: step.message });
        }
    }
    
    // Deploy each module
    let totalResources = 0;
    const baseProgress = 15;
    const progressPerModule = 75 / config.modules.length;
    
    for (let i = 0; i < config.modules.length; i++) {
        const moduleId = config.modules[i];
        const module = MODULES[moduleId];
        const progress = baseProgress + (progressPerModule * i);
        
        socket.emit('module-status', { moduleId, status: 'running' });
        socket.emit('log', { message: `📦 Deploying module: ${module.name}...`, type: 'info' });
        socket.emit('progress', { percent: Math.round(progress), status: `Deploying ${module.name}...` });
        
        await sleep(2000);
        
        socket.emit('log', { message: `  → Creating ${module.resources} AWS resources...`, type: 'info' });
        await sleep(1500);
        
        socket.emit('log', { message: `  → Configuring security groups...`, type: 'info' });
        await sleep(1000);
        
        socket.emit('log', { message: `  → Setting up monitoring...`, type: 'info' });
        await sleep(1000);
        
        socket.emit('log', { message: `✓ ${module.name} deployed successfully!`, type: 'success' });
        socket.emit('module-status', { moduleId, status: 'success' });
        totalResources += module.resources;
        
        await sleep(500);
    }
    
    // Finalization
    socket.emit('progress', { percent: 90, status: 'Finalizing deployment...' });
    socket.emit('log', { message: '🔧 Running post-deployment checks...', type: 'info' });
    await sleep(1500);
    
    socket.emit('log', { message: '✓ Health checks passed', type: 'success' });
    await sleep(500);
    
    socket.emit('log', { message: '✓ Monitoring configured', type: 'success' });
    await sleep(500);
    
    socket.emit('log', { message: '✓ Outputs generated', type: 'success' });
    await sleep(500);
    
    socket.emit('progress', { percent: 100, status: 'Deployment complete!' });
    
    socket.emit('log', { message: '', type: 'info' });
    socket.emit('log', { message: '═══════════════════════════════════════', type: 'success' });
    socket.emit('log', { message: '🎉 DEPLOYMENT SUCCESSFUL!', type: 'success' });
    socket.emit('log', { message: '═══════════════════════════════════════', type: 'success' });
    socket.emit('log', { message: `📊 Resources Created: ${totalResources}`, type: 'info' });
    socket.emit('log', { message: `📦 Modules Deployed: ${config.modules.length}`, type: 'info' });
    
    return { success: true, totalResources, modulesDeployed: config.modules.length };
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// WebSocket connection
io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    
    socket.on('deploy', async (config) => {
        console.log('Deployment request:', config);
        
        // Validate
        const validation = validateDeployment(config);
        if (!validation.valid) {
            socket.emit('error', { message: validation.error });
            return;
        }
        
        // Create deployment job
        const jobId = uuidv4();
        const deployment = {
            jobId,
            config,
            status: 'running',
            startTime: Date.now(),
            endTime: null
        };
        deployments.set(jobId, deployment);
        
        socket.emit('job-created', { jobId });
        
        try {
            // Execute deployment
            const result = await executeTerraform(config, socket);
            
            // Update deployment
            deployment.status = 'completed';
            deployment.endTime = Date.now();
            deployment.result = result;
            
            socket.emit('complete', {
                jobId,
                duration: Math.round((deployment.endTime - deployment.startTime) / 1000),
                ...result
            });
            
        } catch (error) {
            console.error('Deployment error:', error);
            deployment.status = 'failed';
            deployment.endTime = Date.now();
            deployment.error = error.message;
            
            socket.emit('error', { message: error.message });
        }
    });
    
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 CloudStack Backend running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = { app, server };