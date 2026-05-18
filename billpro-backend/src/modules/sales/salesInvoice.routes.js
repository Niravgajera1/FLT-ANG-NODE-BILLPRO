const express = require('express');
const router = express.Router();
const ctrl = require('./salesInvoice.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { auditMiddleware } = require('../../middleware/auditLog');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany);

router.route('/')
  .get(authorize(PERMISSIONS.CREATE_SALES_INVOICE, PERMISSIONS.VIEW_REPORTS), ctrl.getSalesInvoices)
  .post(authorize(PERMISSIONS.CREATE_SALES_INVOICE), auditMiddleware('sales', 'CREATE'), ctrl.createSalesInvoice);

router.get('/aging', authorize(PERMISSIONS.VIEW_REPORTS), ctrl.getReceivablesAging);

router.route('/:id')
  .get(authorize(PERMISSIONS.CREATE_SALES_INVOICE, PERMISSIONS.VIEW_REPORTS), ctrl.getSalesInvoiceById)
  .delete(authorize(PERMISSIONS.DELETE_BILLS), auditMiddleware('sales', 'DELETE'), ctrl.voidSalesInvoice);

router.get('/:id/pdf', authorize(PERMISSIONS.CREATE_SALES_INVOICE, PERMISSIONS.VIEW_REPORTS), ctrl.downloadSalesInvoicePDF);

router.post('/:id/convert', authorize(PERMISSIONS.CREATE_SALES_INVOICE), ctrl.convertProformaToInvoice);

module.exports = router;
