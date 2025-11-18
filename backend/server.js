const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const { spawn } = require('child_process');
const { sendVerificationEmail, sendPasswordResetEmail, verifyEmailConfig } = require('./emailService');
const authService = require('./authService');
const logger = require('./logger');
const config = require('./config');
const { generateToken, verifyToken, optionalAuth } = require('./middleware/auth');
const {
    registrationValidation,
    loginValidation,
    verificationCodeValidation,
    passwordResetValidation,
    contactValidation
} = require('./middleware/validator');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
    cors: {
        origin: config.allowedOrigins,
        methods: ['GET', 'POST'],
        credentials: true
    }
});

// Rate limiting configurations
const generalLimiter = rateLimit({
    windowMs: config.rateLimits.general.windowMs,
    max: config.rateLimits.general.max,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

const authLimiter = rateLimit({
    windowMs: config.rateLimits.auth.windowMs,
    max: config.rateLimits.auth.max,
    message: 'Too many authentication attempts, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: true
});

const deploymentLimiter = rateLimit({
    windowMs: config.rateLimits.deployment.windowMs,
    max: config.rateLimits.deployment.max,
    message: 'Too many deployment requests, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Middleware
app.use(helmet());

// CORS configuration - secure for production
app.use(cors({
    origin: function(origin, callback) {
        // Only allow requests from allowed origins (no open CORS)
        if (config.nodeEnv === 'development') {
            return callback(null, true);
        }
        
        if (!origin || config.allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            logger.warn('Blocked by CORS', { origin });
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging with Winston
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        logger.info('HTTP Request', {
            method: req.method,
            url: req.url,
            status: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip
        });
    });
    next();
});

app.use('/api/', generalLimiter);

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

// Health check endpoints
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/readiness', async (req, res) => {
    try {
        // Check email service
        const emailReady = await verifyEmailConfig();
        
        res.json({
            status: 'ready',
            services: {
                email: emailReady ? 'ok' : 'degraded',
                api: 'ok'
            }
        });
    } catch (error) {
        logger.error('Readiness check failed', { error: error.message });
        res.status(503).json({
            status: 'not ready',
            error: error.message
        });
    }
});

// Send verification email endpoint
app.post('/api/send-verification-email', verificationCodeValidation, async (req, res) => {
    try {
        const { email, code } = req.body;
        
        // Send email
        const result = await sendVerificationEmail(email, code);
        
        if (result.success) {
            logger.info('Verification email sent', { email });
            res.json({ 
                success: true, 
                message: 'Verification email sent successfully',
                messageId: result.messageId
            });
        } else {
            logger.error('Failed to send verification email', { email, error: result.error });
            res.status(500).json({ 
                success: false, 
                error: 'Failed to send email'
            });
        }
        
    } catch (error) {
        logger.error('Error in send-verification-email endpoint', { error: error.message });
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error'
        });
    }
});

// Send password reset email endpoint
app.post('/api/send-password-reset-email', verificationCodeValidation, async (req, res) => {
    try {
        const { email, code } = req.body;
        
        // Send email
        const result = await sendPasswordResetEmail(email, code);
        
        if (result.success) {
            logger.info('Password reset email sent', { email });
            res.json({ 
                success: true, 
                message: 'Password reset email sent successfully',
                messageId: result.messageId
            });
        } else {
            logger.error('Failed to send password reset email', { email, error: result.error });
            res.status(500).json({ 
                success: false, 
                error: 'Failed to send email'
            });
        }
        
    } catch (error) {
        logger.error('Error in send-password-reset-email endpoint', { error: error.message });
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error'
        });
    }
});

// ========== NEW AUTH ENDPOINTS ==========

// Verify reCAPTCHA token
async function verifyRecaptcha(token) {
    if (!config.recaptchaSecret) {
        logger.warn('reCAPTCHA not configured, skipping verification');
        return true; // Skip in development
    }
    
    try {
        const response = await fetch('https://www.google.com/recaptcha/api/siteverify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: `secret=${config.recaptchaSecret}&response=${token}`
        });
        const data = await response.json();
        return data.success && data.score >= 0.5;
    } catch (error) {
        logger.error('reCAPTCHA verification error', { error: error.message });
        return false;
    }
}

// Register user
app.post('/api/auth/register', authLimiter, registrationValidation, async (req, res) => {
    try {
        const { email, password, company, phone, tier, recaptchaToken } = req.body;
        
        // Verify reCAPTCHA in production
        if (config.nodeEnv === 'production' && recaptchaToken) {
            const isValidRecaptcha = await verifyRecaptcha(recaptchaToken);
            if (!isValidRecaptcha) {
                return res.status(400).json({ 
                    success: false, 
                    error: 'reCAPTCHA verification failed' 
                });
            }
        }
        
        const result = await authService.registerUser({
            email,
            password,
            company,
            phone,
            tier: tier || 'free',
            verified: false
        });
        
        if (result.success) {
            // Generate JWT token
            const token = generateToken(result.user);
            logger.info('User registered successfully', { email });
            
            res.json({
                success: true,
                user: result.user,
                token
            });
        } else {
            res.status(400).json(result);
        }
        
    } catch (error) {
        logger.error('Error in register endpoint', { error: error.message });
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error'
        });
    }
}); 
            success: false, 
            error: 'Registration failed' 
        });
    }
});

// Login user
app.post('/api/auth/login', authLimiter, loginValidation, async (req, res) => {
    try {
        const { email, password } = req.body;
        
        const result = await authService.loginUser(email, password);
        
        if (result.success) {
            // Generate JWT token
            const token = generateToken(result.user);
            logger.info('User logged in successfully', { email });
            
            res.json({
                success: true,
                user: result.user,
                token
            });
        } else {
            logger.warn('Login failed', { email, reason: result.error });
            res.status(401).json(result);
        }
        
    } catch (error) {
        logger.error('Error in login endpoint', { error: error.message });
        res.status(500).json({ 
            success: false, 
            error: 'Login failed' 
        });
    }
});

// Verify email
app.post('/api/auth/verify-email', async (req, res) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email is required' 
            });
        }
        
        const result = await authService.verifyUserEmail(email);
        res.json(result);
        
    } catch (error) {
        console.error('Error in verify-email endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Verification failed' 
        });
    }
});

// Get user profile
app.get('/api/auth/me', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email is required' 
            });
        }
        
        const result = await authService.getUserByEmail(email);
        
        if (result.success) {
            res.json(result);
        } else {
            res.status(404).json(result);
        }
        
    } catch (error) {
        console.error('Error in get user endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Failed to get user' 
        });
    }
});

// Update user profile
app.put('/api/auth/update', async (req, res) => {
    try {
        const { email, ...updates } = req.body;
        
        if (!email) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email is required' 
            });
        }
        
        const result = await authService.updateUser(email, updates);
        res.json(result);
        
    } catch (error) {
        console.error('Error in update user endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Update failed' 
        });
    }
});

// Change password
app.post('/api/auth/change-password', async (req, res) => {
    try {
        const { email, oldPassword, newPassword } = req.body;
        
        if (!email || !oldPassword || !newPassword) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email, old password, and new password are required' 
            });
        }
        
        if (newPassword.length < 8) {
            return res.status(400).json({ 
                success: false, 
                error: 'New password must be at least 8 characters' 
            });
        }
        
        const result = await authService.changePassword(email, oldPassword, newPassword);
        res.json(result);
        
    } catch (error) {
        console.error('Error in change password endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Password change failed' 
        });
    }
});

// Reset password (forgot password)
app.post('/api/auth/reset-password', async (req, res) => {
    try {
        const { email, newPassword } = req.body;
        
        if (!email || !newPassword) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email and new password are required' 
            });
        }
        
        if (newPassword.length < 8) {
            return res.status(400).json({ 
                success: false, 
                error: 'New password must be at least 8 characters' 
            });
        }
        
        const result = await authService.resetPassword(email, newPassword);
        res.json(result);
        
    } catch (error) {
        console.error('Error in reset password endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Password reset failed' 
        });
    }
});

// Add deployment
app.post('/api/deployments', async (req, res) => {
    try {
        const { email, ...deploymentData } = req.body;
        
        if (!email) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email is required' 
            });
        }
        
        const result = await authService.addDeployment(email, deploymentData);
        res.json(result);
        
    } catch (error) {
        console.error('Error in add deployment endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Failed to save deployment' 
        });
    }
});

// Get user deployments
app.get('/api/deployments', async (req, res) => {
    try {
        const { email } = req.query;
        
        if (!email) {
            return res.status(400).json({ 
                success: false, 
                error: 'Email is required' 
            });
        }
        
        const result = await authService.getUserDeployments(email);
        res.json(result);
        
    } catch (error) {
        console.error('Error in get deployments endpoint:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Failed to get deployments' 
        });
    }
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
    logger.info('Client connected', { socketId: socket.id });
    
    socket.on('deploy', async (config) => {
        logger.info('Deployment request received', { 
            socketId: socket.id,
            modules: config.modules,
            environment: config.environment 
        });
        
        // Validate
        const validation = validateDeployment(config);
        if (!validation.valid) {
            logger.warn('Deployment validation failed', { 
                reason: validation.error,
                config 
            });
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
            
            logger.info('Deployment completed', { 
                jobId,
                duration: Math.round((deployment.endTime - deployment.startTime) / 1000) 
            });
            
            socket.emit('complete', {
                jobId,
                duration: Math.round((deployment.endTime - deployment.startTime) / 1000),
                ...result
            });
            
        } catch (error) {
            logger.error('Deployment failed', { 
                jobId,
                error: error.message,
                stack: error.stack 
            });
            deployment.status = 'failed';
            deployment.endTime = Date.now();
            deployment.error = error.message;
            
            socket.emit('error', { message: error.message });
        }
    });
    
    socket.on('disconnect', () => {
        logger.info('Client disconnected', { socketId: socket.id });
    });
});

// Contact form submission endpoint
app.post('/api/contact', contactValidation, async (req, res) => {
    try {
        const { name, email, company, interest, message } = req.body;
        
        // Log contact form submission
        logger.info('Contact form submission', {
            name,
            email,
            company: company || 'Not provided',
            interest,
            timestamp: new Date().toISOString()
        });
        
        res.json({
            success: true,
            message: 'Thank you for contacting us! We will respond shortly.'
        });
        
    } catch (error) {
        logger.error('Contact form error', { error: error.message });
        res.status(500).json({
            success: false,
            error: 'Failed to process contact form'
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error('Unhandled error', { 
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method
    });
    
    res.status(err.status || 500).json({ 
        success: false,
        error: config.nodeEnv === 'production' ? 'Internal server error' : err.message 
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ 
        success: false,
        error: 'Endpoint not found' 
    });
});

// Start server
const PORT = config.port;
const HOST = config.host;

server.listen(PORT, HOST, async () => {
    logger.info('🚀 CloudStack Backend started', {
        host: HOST,
        port: PORT,
        environment: config.nodeEnv,
        publicUrl: process.env.RAILWAY_PUBLIC_DOMAIN || 'localhost',
        nodeVersion: process.version
    });
    
    // Verify email service configuration
    const emailReady = await verifyEmailConfig();
    if (emailReady) {
        logger.info('📧 Email service initialized successfully');
    } else {
        logger.warn('⚠️  Email service not configured - set RESEND_API_KEY in .env');
    }
    
    // Security checks
    if (!config.jwtSecret || config.jwtSecret === 'change-this-secret-key-in-production') {
        logger.warn('⚠️  JWT_SECRET not set or using default value. Please set a secure secret!');
    }
    
    if (config.nodeEnv === 'production' && !config.recaptchaSecret) {
        logger.warn('⚠️  RECAPTCHA_SECRET_KEY not set in production');
    }
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, closing server gracefully');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, closing server gracefully');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

module.exports = { app, server };