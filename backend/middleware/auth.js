const jwt = require('jsonwebtoken');
const logger = require('../logger');

const JWT_SECRET = process.env.JWT_SECRET || 'change-this-secret-key-in-production';
const JWT_EXPIRY = process.env.JWT_EXPIRY || '24h';

// Generate JWT token
function generateToken(user) {
    return jwt.sign(
        { 
            email: user.email, 
            tier: user.tier,
            company: user.company 
        },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRY }
    );
}

// Verify JWT token middleware
function verifyToken(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
        return res.status(401).json({ 
            success: false, 
            error: 'Access token is required' 
        });
    }
    
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        logger.error('Token verification failed', { error: error.message });
        
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ 
                success: false, 
                error: 'Token has expired',
                expired: true
            });
        }
        
        return res.status(401).json({ 
            success: false, 
            error: 'Invalid token' 
        });
    }
}

// Optional auth - doesn't fail if no token
function optionalAuth(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (token) {
        try {
            const decoded = jwt.verify(token, JWT_SECRET);
            req.user = decoded;
        } catch (error) {
            // Silently fail for optional auth
            logger.debug('Optional auth failed', { error: error.message });
        }
    }
    
    next();
}

module.exports = {
    generateToken,
    verifyToken,
    optionalAuth
};
