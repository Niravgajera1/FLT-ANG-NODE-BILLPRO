const { ROLE_PERMISSIONS } = require('../config/constants');
const { sendForbidden } = require('../utils/responseHelper');

/**
 * Role-Based Access Control middleware
 * Usage: authorize('create_sales_invoice')
 * Usage: authorize('view_reports', 'export_data')  ← any one of these
 */
const authorize = (...requiredPermissions) => {
  return (req, res, next) => {
    const userRole = req.user?.role;

    if (!userRole) {
      return sendForbidden(res, 'No role assigned');
    }

    const userPermissions = ROLE_PERMISSIONS[userRole] || [];

    // Check if user has ANY of the required permissions
    const hasPermission = requiredPermissions.some(p => userPermissions.includes(p));

    if (!hasPermission) {
      return sendForbidden(res, `Access denied: requires ${requiredPermissions.join(' or ')} permission`);
    }

    next();
  };
};

/**
 * Require ALL listed permissions
 */
const authorizeAll = (...requiredPermissions) => {
  return (req, res, next) => {
    const userRole = req.user?.role;
    const userPermissions = ROLE_PERMISSIONS[userRole] || [];
    const hasAll = requiredPermissions.every(p => userPermissions.includes(p));

    if (!hasAll) {
      return sendForbidden(res, 'Insufficient permissions');
    }
    next();
  };
};

/**
 * Restrict to specific roles only
 */
const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return sendForbidden(res, 'Role not authorized for this action');
    }
    next();
  };
};

module.exports = { authorize, authorizeAll, restrictTo };
