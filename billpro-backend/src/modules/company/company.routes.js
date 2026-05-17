const express = require('express');
const router = express.Router();
const ctrl = require('./company.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize, restrictTo } = require('../../middleware/rbac.middleware');
const { auditMiddleware } = require('../../middleware/auditLog');
const { logoUpload } = require('../../middleware/upload');
const { PERMISSIONS, ROLES } = require('../../config/constants');
const { validate, schemas } = require('./company.validation');

router.use(authenticate);

// Company creation — no company context needed yet
router.post('/', validate(schemas.createCompany), auditMiddleware('company', 'CREATE'), ctrl.createCompany);


// All routes below require company context
router.use(attachCompany);

router.route('/')
  .get(ctrl.getCompany)
  .put(restrictTo(ROLES.COMPANY_ADMIN), validate(schemas.updateCompany), auditMiddleware('company', 'UPDATE'), ctrl.updateCompany);

// Validation utilities
// router.get('/validate/gstin/:gstin', ctrl.validateGSTIN);
// router.get('/validate/ifsc/:ifsc', ctrl.validateIFSC);

// Bank accounts
router.post('/bank-accounts', restrictTo(ROLES.COMPANY_ADMIN), ctrl.addBankAccount);

module.exports = router;
