const { body, validationResult } = require('express-validator');

// Middleware to check validation results
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ 
            success: false, 
            errors: errors.array() 
        });
    }
    next();
};

// Email validation rules
const emailValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    validate
];

// Registration validation rules
const registrationValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    body('password')
        .isLength({ min: 8 })
        .withMessage('Password must be at least 8 characters')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
    body('company')
        .optional()
        .trim()
        .isLength({ max: 100 })
        .withMessage('Company name too long'),
    body('phone')
        .optional()
        .trim()
        .matches(/^[+\d\s\-()]+$/)
        .withMessage('Invalid phone number format'),
    body('tier')
        .optional()
        .isIn(['free', 'professional', 'enterprise', 'ultimate'])
        .withMessage('Invalid tier'),
    validate
];

// Login validation rules
const loginValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    body('password')
        .notEmpty()
        .withMessage('Password is required'),
    validate
];

// Verification code validation
const verificationCodeValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    body('code')
        .matches(/^\d{6}$/)
        .withMessage('Code must be 6 digits'),
    validate
];

// Password reset validation
const passwordResetValidation = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    body('code')
        .matches(/^\d{6}$/)
        .withMessage('Code must be 6 digits'),
    body('newPassword')
        .isLength({ min: 8 })
        .withMessage('Password must be at least 8 characters')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
    validate
];

// Contact form validation
const contactValidation = [
    body('name')
        .trim()
        .notEmpty()
        .withMessage('Name is required')
        .isLength({ max: 100 })
        .withMessage('Name too long'),
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email format'),
    body('message')
        .trim()
        .notEmpty()
        .withMessage('Message is required')
        .isLength({ min: 10, max: 1000 })
        .withMessage('Message must be between 10 and 1000 characters'),
    body('company')
        .optional()
        .trim()
        .isLength({ max: 100 })
        .withMessage('Company name too long'),
    validate
];

// Deployment config validation
const deploymentValidation = [
    body('modules')
        .isArray({ min: 1 })
        .withMessage('At least one module is required'),
    body('environment')
        .isIn(['dev', 'staging', 'prod'])
        .withMessage('Invalid environment'),
    body('region')
        .notEmpty()
        .withMessage('Region is required'),
    validate
];

module.exports = {
    emailValidation,
    registrationValidation,
    loginValidation,
    verificationCodeValidation,
    passwordResetValidation,
    contactValidation,
    deploymentValidation,
    validate
};
