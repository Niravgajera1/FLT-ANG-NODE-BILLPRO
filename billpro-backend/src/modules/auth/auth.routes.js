const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { authRateLimiter, otpRateLimiter } = require('../../middleware/rateLimiter');
const { validate, schemas } = require('./auth.validation');

// ─── Public Routes ────────────────────────────────────────────────────────────
router.post('/register',         authRateLimiter, validate(schemas.register),       authController.register);
router.post('/verify-otp',       otpRateLimiter,  validate(schemas.verifyOTP),      authController.verifyOTP);
router.post('/login',            authRateLimiter, validate(schemas.login),          authController.login);
router.post('/login/otp',        otpRateLimiter,  validate(schemas.loginOTP),       authController.sendLoginOTP);
router.post('/login/otp/verify', otpRateLimiter,                                   authController.verifyLoginOTP);
router.post('/refresh',                                                             authController.refreshToken);
router.post('/forgot-password',  authRateLimiter, validate(schemas.forgotPassword), authController.forgotPassword);
router.post('/reset-password',   authRateLimiter, validate(schemas.resetPassword),  authController.resetPassword);

// ─── Protected Routes ─────────────────────────────────────────────────────────
router.use(authenticate);
router.get('/me',                                                                   authController.getMe);
router.post('/logout',                                                              authController.logout);
router.post('/change-password',  validate(schemas.changePassword),                 authController.changePassword);

module.exports = router;
