const express = require('express');
const router = express.Router();
const ctrl = require('./item.controller');
const categoryCtrl = require('./itemCategory.controller');
const { authenticate, attachCompany } = require('../../middleware/auth.middleware');
const { authorize } = require('../../middleware/rbac.middleware');
const { PERMISSIONS } = require('../../config/constants');
const { itemUpload } = require('../../middleware/upload');

router.use(authenticate);

router.post('/categories/add', attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), categoryCtrl.createCategory);
router.get('/categories/list', attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), categoryCtrl.getCategories);
router.get('/categories/details/:id', attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), categoryCtrl.getCategoryById);
router.put('/categories/update/:id', attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), categoryCtrl.updateCategory);
router.delete('/categories/delete/:id', attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), categoryCtrl.deleteCategory);

router.route('/')
  .get(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.getItems)
  .post(itemUpload.single('image'), attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.createItem);

router.route('/:id')
  .get(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.getItemById)
  .put(itemUpload.single('image'), attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.updateItem)
  .delete(attachCompany, authorize(PERMISSIONS.MANAGE_ITEMS), ctrl.deleteItem);

module.exports = router;
