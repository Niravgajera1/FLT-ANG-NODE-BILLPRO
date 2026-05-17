const express = require('express');
const router = express.Router();
const itemService = require('./item.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');

router.use(authenticate, attachCompany);

router.route('/')
  .get(authorize(PERMISSIONS.MANAGE_ITEMS), async (req, res, next) => {
    try {
      const { items, total, page, limit } = await itemService.getItems(req.companyId, req.query);
      return sendPaginated(res, items, { total, page, limit });
    } catch (e) { next(e); }
  })
  .post(authorize(PERMISSIONS.MANAGE_ITEMS), async (req, res, next) => {
    try { return sendCreated(res, await itemService.createItem(req.companyId, req.body)); }
    catch (e) { next(e); }
  });

router.route('/:id')
  .get(authorize(PERMISSIONS.MANAGE_ITEMS), async (req, res, next) => {
    try { return sendSuccess(res, await itemService.getItemById(req.companyId, req.params.id)); }
    catch (e) { next(e); }
  })
  .put(authorize(PERMISSIONS.MANAGE_ITEMS), async (req, res, next) => {
    try { return sendSuccess(res, await itemService.updateItem(req.companyId, req.params.id, req.body), 'Item updated'); }
    catch (e) { next(e); }
  })
  .delete(authorize(PERMISSIONS.MANAGE_ITEMS), async (req, res, next) => {
    try { return sendSuccess(res, await itemService.deleteItem(req.companyId, req.params.id), 'Item deactivated'); }
    catch (e) { next(e); }
  });

module.exports = router;
