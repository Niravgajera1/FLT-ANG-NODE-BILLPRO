const express = require('express');
const router = express.Router();
const ctrl = require('./customer.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany);

router.route('/')
  .get(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.getCustomers)
  .post(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.createCustomer);

router.route('/:id')
  .get(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.getCustomerById)
  .put(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.updateCustomer)
  .delete(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.deleteCustomer);

router.route('/:id/toggle-status')
  .patch(authorize(PERMISSIONS.MANAGE_VENDORS_CUSTOMERS), ctrl.toggleCustomerStatus);

module.exports = router;
