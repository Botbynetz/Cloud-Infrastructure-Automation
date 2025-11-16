const bcrypt = require('bcrypt');
const fs = require('fs').promises;
const path = require('path');

const SALT_ROUNDS = 10;
const USERS_FILE = path.join(__dirname, 'data', 'users.json');
const DEPLOYMENTS_FILE = path.join(__dirname, 'data', 'deployments.json');

// Ensure data directory exists
async function ensureDataDir() {
    const dataDir = path.join(__dirname, 'data');
    try {
        await fs.mkdir(dataDir, { recursive: true });
    } catch (error) {
        console.error('Error creating data directory:', error);
    }
}

// Load users from file
async function loadUsers() {
    try {
        const data = await fs.readFile(USERS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        // File doesn't exist or is empty, return empty array
        return [];
    }
}

// Save users to file
async function saveUsers(users) {
    await ensureDataDir();
    await fs.writeFile(USERS_FILE, JSON.stringify(users, null, 2), 'utf8');
}

// Hash password
async function hashPassword(password) {
    return await bcrypt.hash(password, SALT_ROUNDS);
}

// Compare password
async function comparePassword(password, hash) {
    return await bcrypt.compare(password, hash);
}

// Register new user
async function registerUser(userData) {
    try {
        const users = await loadUsers();
        
        // Check if email already exists
        const existingUser = users.find(u => u.email === userData.email);
        if (existingUser) {
            return { success: false, error: 'Email already registered' };
        }
        
        // Hash password
        const hashedPassword = await hashPassword(userData.password);
        
        // Create new user
        const newUser = {
            id: Date.now().toString(),
            email: userData.email,
            password: hashedPassword,
            company: userData.company || '',
            phone: userData.phone || '',
            tier: userData.tier || 'free',
            verified: userData.verified || false,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            lastLogin: null,
            deploymentCount: 0,
            settings: {
                notifications: true,
                twoFactorEnabled: false
            }
        };
        
        users.push(newUser);
        await saveUsers(users);
        
        // Return user without password
        const { password, ...userWithoutPassword } = newUser;
        return { success: true, user: userWithoutPassword };
        
    } catch (error) {
        console.error('Error registering user:', error);
        return { success: false, error: 'Registration failed' };
    }
}

// Login user
async function loginUser(email, password) {
    try {
        const users = await loadUsers();
        
        // Find user
        const user = users.find(u => u.email === email);
        if (!user) {
            return { success: false, error: 'Invalid email or password' };
        }
        
        // Check if verified
        if (!user.verified) {
            return { success: false, error: 'Please verify your email first' };
        }
        
        // Compare password
        const isValid = await comparePassword(password, user.password);
        if (!isValid) {
            return { success: false, error: 'Invalid email or password' };
        }
        
        // Update last login
        user.lastLogin = new Date().toISOString();
        await saveUsers(users);
        
        // Return user without password
        const { password: _, ...userWithoutPassword } = user;
        return { success: true, user: userWithoutPassword };
        
    } catch (error) {
        console.error('Error logging in user:', error);
        return { success: false, error: 'Login failed' };
    }
}

// Get user by email
async function getUserByEmail(email) {
    try {
        const users = await loadUsers();
        const user = users.find(u => u.email === email);
        if (!user) {
            return { success: false, error: 'User not found' };
        }
        
        const { password, ...userWithoutPassword } = user;
        return { success: true, user: userWithoutPassword };
    } catch (error) {
        console.error('Error getting user:', error);
        return { success: false, error: 'Failed to get user' };
    }
}

// Update user
async function updateUser(email, updates) {
    try {
        const users = await loadUsers();
        const userIndex = users.findIndex(u => u.email === email);
        
        if (userIndex === -1) {
            return { success: false, error: 'User not found' };
        }
        
        // Don't allow email or password updates through this function
        const { email: _, password: __, ...allowedUpdates } = updates;
        
        users[userIndex] = {
            ...users[userIndex],
            ...allowedUpdates,
            updatedAt: new Date().toISOString()
        };
        
        await saveUsers(users);
        
        const { password, ...userWithoutPassword } = users[userIndex];
        return { success: true, user: userWithoutPassword };
        
    } catch (error) {
        console.error('Error updating user:', error);
        return { success: false, error: 'Update failed' };
    }
}

// Change password
async function changePassword(email, oldPassword, newPassword) {
    try {
        const users = await loadUsers();
        const userIndex = users.findIndex(u => u.email === email);
        
        if (userIndex === -1) {
            return { success: false, error: 'User not found' };
        }
        
        // Verify old password
        const isValid = await comparePassword(oldPassword, users[userIndex].password);
        if (!isValid) {
            return { success: false, error: 'Current password is incorrect' };
        }
        
        // Hash new password
        const hashedPassword = await hashPassword(newPassword);
        users[userIndex].password = hashedPassword;
        users[userIndex].updatedAt = new Date().toISOString();
        
        await saveUsers(users);
        
        return { success: true, message: 'Password changed successfully' };
        
    } catch (error) {
        console.error('Error changing password:', error);
        return { success: false, error: 'Password change failed' };
    }
}

// Reset password (for forgot password flow)
async function resetPassword(email, newPassword) {
    try {
        const users = await loadUsers();
        const userIndex = users.findIndex(u => u.email === email);
        
        if (userIndex === -1) {
            return { success: false, error: 'User not found' };
        }
        
        // Hash new password
        const hashedPassword = await hashPassword(newPassword);
        users[userIndex].password = hashedPassword;
        users[userIndex].updatedAt = new Date().toISOString();
        
        await saveUsers(users);
        
        return { success: true, message: 'Password reset successfully' };
        
    } catch (error) {
        console.error('Error resetting password:', error);
        return { success: false, error: 'Password reset failed' };
    }
}

// Verify user email
async function verifyUserEmail(email) {
    try {
        const users = await loadUsers();
        const userIndex = users.findIndex(u => u.email === email);
        
        if (userIndex === -1) {
            return { success: false, error: 'User not found' };
        }
        
        users[userIndex].verified = true;
        users[userIndex].updatedAt = new Date().toISOString();
        
        await saveUsers(users);
        
        const { password, ...userWithoutPassword } = users[userIndex];
        return { success: true, user: userWithoutPassword };
        
    } catch (error) {
        console.error('Error verifying user:', error);
        return { success: false, error: 'Verification failed' };
    }
}

// Load deployments
async function loadDeployments() {
    try {
        const data = await fs.readFile(DEPLOYMENTS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        return [];
    }
}

// Save deployments
async function saveDeployments(deployments) {
    await ensureDataDir();
    await fs.writeFile(DEPLOYMENTS_FILE, JSON.stringify(deployments, null, 2), 'utf8');
}

// Add deployment
async function addDeployment(email, deploymentData) {
    try {
        const deployments = await loadDeployments();
        
        const newDeployment = {
            id: Date.now().toString(),
            userId: email,
            ...deploymentData,
            createdAt: new Date().toISOString()
        };
        
        deployments.push(newDeployment);
        await saveDeployments(deployments);
        
        // Update user deployment count
        const users = await loadUsers();
        const userIndex = users.findIndex(u => u.email === email);
        if (userIndex !== -1) {
            users[userIndex].deploymentCount += 1;
            await saveUsers(users);
        }
        
        return { success: true, deployment: newDeployment };
        
    } catch (error) {
        console.error('Error adding deployment:', error);
        return { success: false, error: 'Failed to save deployment' };
    }
}

// Get user deployments
async function getUserDeployments(email) {
    try {
        const deployments = await loadDeployments();
        const userDeployments = deployments.filter(d => d.userId === email);
        return { success: true, deployments: userDeployments };
    } catch (error) {
        console.error('Error getting deployments:', error);
        return { success: false, error: 'Failed to get deployments' };
    }
}

module.exports = {
    registerUser,
    loginUser,
    getUserByEmail,
    updateUser,
    changePassword,
    resetPassword,
    verifyUserEmail,
    addDeployment,
    getUserDeployments,
    hashPassword,
    comparePassword
};
