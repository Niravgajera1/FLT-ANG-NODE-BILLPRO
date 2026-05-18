const express = require('express');
const router = express.Router();
const ctrl = require('./item.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');
const { itemUpload } = require('../../middleware/upload');

router.use(authenticate);

router.route('/')
  .get(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.getItems)
  .post(itemUpload.single('image'), attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.createItem);

router.route('/:id')
  .get(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.getItemById)
  .put(itemUpload.single('image'), attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.updateItem)
  .delete(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.deleteItem);

module.exports = router;
