// Frontend Configuration
// This file contains environment-specific configuration for the frontend

const API_CONFIG = {
    // Backend API URLs by environment
    BACKEND_URL: (() => {
        const hostname = window.location.hostname;
        
        // Production
        if (hostname === 'botbynetz.github.io') {
            return 'https://cloud-infrastructure-automation-production.up.railway.app';
        }
        
        // Local development
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return 'http://localhost:3000';
        }
        
        // Default fallback
        return 'https://cloud-infrastructure-automation-production.up.railway.app';
    })(),
    
    // API endpoints
    ENDPOINTS: {
        // Auth
        REGISTER: '/api/auth/register',
        LOGIN: '/api/auth/login',
        VERIFY_EMAIL: '/api/auth/verify-email',
        GET_USER: '/api/auth/user',
        UPDATE_USER: '/api/auth/user',
        CHANGE_PASSWORD: '/api/auth/change-password',
        RESET_PASSWORD: '/api/auth/reset-password',
        
        // Email
        SEND_VERIFICATION: '/api/send-verification-email',
        SEND_RESET_EMAIL: '/api/send-password-reset-email',
        
        // Deployments
        ADD_DEPLOYMENT: '/api/deploy/add',
        GET_DEPLOYMENTS: '/api/deploy/list',
        
        // Contact
        CONTACT: '/api/contact',
        
        // Health
        HEALTH: '/health',
        READINESS: '/readiness'
    },
    
    // Request timeout (ms)
    TIMEOUT: 30000,
    
    // Retry configuration
    MAX_RETRIES: 3,
    RETRY_DELAY: 1000
};

// Helper function to make API calls
async function apiCall(endpoint, options = {}) {
    const url = `${API_CONFIG.BACKEND_URL}${endpoint}`;
    
    const defaultOptions = {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json'
        },
        ...options
    };
    
    // Add JWT token if available
    const token = localStorage.getItem('auth_token');
    if (token) {
        defaultOptions.headers['Authorization'] = `Bearer ${token}`;
    }
    
    try {
        const response = await fetch(url, defaultOptions);
        const data = await response.json();
        
        // Handle token expiration
        if (response.status === 401 && data.expired) {
            // Token expired, clear auth and redirect to login
            localStorage.removeItem('auth_token');
            localStorage.removeItem('univai_user');
            window.location.href = '/auth.html';
            return;
        }
        
        return {
            ok: response.ok,
            status: response.status,
            data
        };
    } catch (error) {
        console.error('API call failed', { endpoint, error: error.message });
        throw error;
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { API_CONFIG, apiCall };
}
