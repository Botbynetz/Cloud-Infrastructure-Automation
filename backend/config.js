require('dotenv').config();

// Validate required environment variables
const requiredEnvVars = ['JWT_SECRET'];

if (process.env.NODE_ENV === 'production') {
    requiredEnvVars.push('RESEND_API_KEY', 'RECAPTCHA_SECRET_KEY');
}

const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
    console.error(`❌ Missing required environment variables: ${missingVars.join(', ')}`);
    if (process.env.NODE_ENV === 'production') {
        process.exit(1);
    }
}

const config = {
    // Server
    port: process.env.PORT || 3000,
    host: process.env.HOST || '0.0.0.0',
    nodeEnv: process.env.NODE_ENV || 'development',
    
    // Frontend
    frontendUrl: process.env.FRONTEND_URL || 'https://botbynetz.github.io',
    
    // Security
    jwtSecret: process.env.JWT_SECRET,
    jwtExpiry: process.env.JWT_EXPIRY || '24h',
    recaptchaSecret: process.env.RECAPTCHA_SECRET_KEY,
    
    // Email
    resendApiKey: process.env.RESEND_API_KEY,
    emailFrom: process.env.EMAIL_FROM || 'CloudStack <noreply@resend.dev>',
    
    // Database
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    
    // AWS (for deployments)
    aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        region: process.env.AWS_DEFAULT_REGION || 'us-east-1'
    },
    
    // Rate Limiting
    rateLimits: {
        general: {
            windowMs: 15 * 60 * 1000, // 15 minutes
            max: 100
        },
        auth: {
            windowMs: 15 * 60 * 1000,
            max: 5 // Stricter for auth
        },
        deployment: {
            windowMs: 60 * 60 * 1000, // 1 hour
            max: 10
        }
    },
    
    // Deployment
    maxConcurrentDeployments: parseInt(process.env.MAX_CONCURRENT_DEPLOYMENTS || '5'),
    deploymentTimeout: parseInt(process.env.DEPLOYMENT_TIMEOUT || '3600000'),
    
    // Logging
    logLevel: process.env.LOG_LEVEL || 'info',
    
    // CORS
    allowedOrigins: [
        'http://localhost:3000',
        'http://localhost:5500',
        'http://127.0.0.1:5500',
        'https://botbynetz.github.io',
        process.env.FRONTEND_URL
    ].filter(Boolean),
    
    // Verification code expiry (15 minutes)
    verificationCodeExpiry: 15 * 60 * 1000
};

module.exports = config;
