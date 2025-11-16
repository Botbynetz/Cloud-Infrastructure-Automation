// Configuration for CloudStack deployment platform
const CONFIG = {
    // Backend URL (Railway deployment)
    BACKEND_URL: 'https://cloud-infrastructure-automation-production.up.railway.app',
    
    // Feature flags
    USE_WEBSOCKET: true,  // WebSocket enabled for Railway backend
    USE_SIMULATION: false,  // Using real Railway backend
    
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