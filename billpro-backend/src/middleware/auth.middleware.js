const jwt = require('jsonwebtoken');
const { isTokenBlacklisted } = require('../config/redis');
const { sendUnauthorized } = require('../utils/responseHelper');
const logger = require('../utils/logger');

/**
 * Verify JWT access token from Authorization header
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendUnauthorized(res, 'No token provided');
    }

    const token = authHeader.split(' ')[1];

    // Check if token is blacklisted (logged out)
    const blacklisted = await isTokenBlacklisted(token);
    if (blacklisted) {
      return sendUnauthorized(res, 'Token has been invalidated');
    }

    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    req.user = decoded;
    req.token = token;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendUnauthorized(res, 'Token expired');
    }
    if (err.name === 'JsonWebTokenError') {
      return sendUnauthorized(res, 'Invalid token');
    }
    logger.error('Auth middleware error:', err);
    return sendUnauthorized(res);
  }
};

/**
 * Extract company context from request
 * Attaches companyId to req from header or JWT payload
 */
const attachCompany = (req, res, next) => {
  const companyId = req.headers['x-company-id'] || req.user?.activeCompanyId;
  if (!companyId) {
    return res.status(400).json({ success: false, message: 'Company context required' });
  }
  req.companyId = companyId;
  next();
};

module.exports = { authenticate, attachCompany };
