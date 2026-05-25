const express = require('express');
const router = express.Router();
const dashboardService = require('./dashboard.service');
const { sendSuccess } = require('../../utils/responseHelper');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany, authorize(PERMISSIONS.VIEW_DASHBOARD));

router.get('/summary', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getDashboardSummary(req.companyId, req.query.fyStartMonth, req.query.startDate, req.query.endDate)); } catch (e) { next(e); } });
router.get('/kpis', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getKPICards(req.companyId)); } catch (e) { next(e); } });
router.get('/sales-trend', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getMonthlySalesTrend(req.companyId, req.query.fyStartMonth)); } catch (e) { next(e); } });
router.get('/sales-vs-purchase', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getSalesVsPurchase(req.companyId, req.query.fyStartMonth)); } catch (e) { next(e); } });
router.get('/top-customers', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getTopCustomers(req.companyId, req.query.fyStartMonth, req.query.limit)); } catch (e) { next(e); } });
router.get('/invoice-status', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getInvoiceStatusDistribution(req.companyId, req.query.startDate, req.query.endDate)); } catch (e) { next(e); } });
router.get('/gst-summary', async (req, res, next) => { try { return sendSuccess(res, await dashboardService.getGSTSummary(req.companyId, req.query.fyStartMonth)); } catch (e) { next(e); } });

module.exports = router;
