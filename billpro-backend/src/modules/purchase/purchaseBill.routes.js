const express = require('express');
const router = express.Router();
const ctrl = require('./purchaseBill.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { auditMiddleware } = require('../../middleware/auditLog');
const { attachmentUpload } = require('../../middleware/upload');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany);

router.route('/')
  .get(authorize(PERMISSIONS.CREATE_PURCHASE_BILL, PERMISSIONS.VIEW_REPORTS), ctrl.getPurchaseBills)
  .post(authorize(PERMISSIONS.CREATE_PURCHASE_BILL), auditMiddleware('purchase', 'CREATE'), ctrl.createPurchaseBill);

router.route('/outstanding')
  .get(authorize(PERMISSIONS.VIEW_REPORTS), ctrl.getVendorOutstanding);

router.get('/:id/pdf', authorize(PERMISSIONS.CREATE_PURCHASE_BILL, PERMISSIONS.VIEW_REPORTS), ctrl.downloadPurchaseBillPDF);

router.route('/:id')
  .get(authorize(PERMISSIONS.CREATE_PURCHASE_BILL, PERMISSIONS.VIEW_REPORTS), ctrl.getPurchaseBillById)
  .put(authorize(PERMISSIONS.CREATE_PURCHASE_BILL), auditMiddleware('purchase', 'UPDATE'), ctrl.updatePurchaseBill)
  .delete(authorize(PERMISSIONS.DELETE_BILLS), auditMiddleware('purchase', 'DELETE'), ctrl.voidPurchaseBill);

module.exports = router;
