const express = require('express');
const router  = express.Router();
const ctrl    = require('./vendor.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany);

router.route('/')
  .get(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS),  ctrl.getVendors)
  .post(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.createVendor);

router.route('/:id')
  .get(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS),    ctrl.getVendorById)
  .put(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS),    ctrl.updateVendor)
  .delete(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.deleteVendor);

module.exports = router;
