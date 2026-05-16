const express = require('express');
const router  = express.Router();

const authRoutes      = require('../modules/auth/auth.routes');
const companyRoutes   = require('../modules/company/company.routes');
const vendorRoutes    = require('../modules/vendors/vendor.routes');
const customerRoutes  = require('../modules/customers/customer.routes');
const itemRoutes      = require('../modules/items/item.routes');
const purchaseRoutes  = require('../modules/purchase/purchaseBill.routes');
const salesRoutes     = require('../modules/sales/salesInvoice.routes');
const dashboardRoutes = require('../modules/dashboard/dashboard.routes');
const reportRoutes    = require('../modules/reports/report.routes');

// ─── Route Bindings ───────────────────────────────────────────────────────────
router.use('/auth',      authRoutes);
router.use('/companies', companyRoutes);
router.use('/vendors',   vendorRoutes);
router.use('/customers', customerRoutes);
router.use('/items',     itemRoutes);
router.use('/purchase',  purchaseRoutes);
router.use('/sales',     salesRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/reports',   reportRoutes);

module.exports = router;
