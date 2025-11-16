// Configuration for CloudStack deployment platform
const CONFIG = {
    // Backend URL (update after Heroku deployment)
    BACKEND_URL: process.env.NODE_ENV === 'production' 
        ? 'https://cloudstack-deploy-api.herokuapp.com'  // Update this after creating Heroku app
        : 'http://localhost:3000',
    
    // Feature flags
    USE_WEBSOCKET: false,  // Set to true after backend deployed
    USE_SIMULATION: true,  // Set to false when using real backend
    
    // Pricing tiers
    TIERS: {
        free: {
            name: "Free",
            modules: ["self-service-portal"],
            maxModules: 1,
            maxDeployments: 1,
            price: 0
        },
        professional: {
            name: "Professional",
            modules: ["self-service-portal", "observability", "gitops", "service-mesh", "finops"],
            maxModules: 3,
            maxDeployments: 10,
            price: 299
        },
        enterprise: {
            name: "Enterprise",
            modules: ["self-service-portal", "observability", "gitops", "zero-trust", "disaster-recovery", "compliance", "finops", "service-mesh"],
            maxModules: 7,
            maxDeployments: 50,
            price: 999
        },
        ultimate: {
            name: "Ultimate",
            modules: ["self-service-portal", "aiops", "zero-trust", "disaster-recovery", "compliance", "finops", "multi-cloud", "gitops", "service-mesh", "observability"],
            maxModules: 10,
            maxDeployments: -1,  // unlimited
            price: 2499
        }
    }
};

// Export for use in deploy.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CONFIG;
}