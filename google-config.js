// Google OAuth Configuration
// Get your Google Client ID from: https://console.cloud.google.com/apis/credentials
// 
// Steps to get Google Client ID:
// 1. Go to https://console.cloud.google.com/
// 2. Create a new project or select existing project
// 3. Enable Google+ API
// 4. Go to Credentials -> Create Credentials -> OAuth 2.0 Client ID
// 5. Application type: Web application
// 6. Authorized JavaScript origins:
//    - https://botbynetz.github.io
//    - http://localhost:5500 (for local testing)
// 7. Authorized redirect URIs:
//    - https://botbynetz.github.io/Cloud-Infrastructure-Automation/auth.html
//    - http://localhost:5500/auth.html
// 8. Copy the Client ID and paste below

const GOOGLE_CONFIG = {
    // Google OAuth Client ID
    CLIENT_ID: '1080531524270-1o4h5dg2iloeapla3729i5bm843q8mbu.apps.googleusercontent.com',
    
    // Authorized domains (for security)
    AUTHORIZED_DOMAINS: [
        'botbynetz.github.io',
        'localhost'
    ]
};

// Export config
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GOOGLE_CONFIG;
}
