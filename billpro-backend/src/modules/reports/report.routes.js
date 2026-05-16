const express = require('express');
const router  = express.Router();
const reportService = require('./report.service');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany, authorize(PERMISSIONS.VIEW_REPORTS));

// Sales Register — Excel
router.get('/sales-register/excel', async (req, res, next) => {
  try {
    const buffer = await reportService.generateSalesRegisterExcel(req.companyId, req.query);
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="sales-register.xlsx"');
    res.send(buffer);
  } catch (e) { next(e); }
});

// Purchase Register — Excel
router.get('/purchase-register/excel', async (req, res, next) => {
  try {
    const buffer = await reportService.generatePurchaseRegisterExcel(req.companyId, req.query);
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="purchase-register.xlsx"');
    res.send(buffer);
  } catch (e) { next(e); }
});

// GSTR-1 JSON export
router.get('/gstr1/json', async (req, res, next) => {
  try {
    const json = await reportService.generateGSTR1JSON(req.companyId, req.query);
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', 'attachment; filename="GSTR1.json"');
    res.send(json);
  } catch (e) { next(e); }
});

module.exports = router;
