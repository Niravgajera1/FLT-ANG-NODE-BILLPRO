const itemCategoryService = require('./itemCategory.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

const createCategory = async (req, res, next) => {
  try {
    const companyId = req.body.companyId || req.companyId;
    const category = await itemCategoryService.createCategory(companyId, req.body);
    return sendCreated(res, category, 'Item Category created successfully');
  } catch (err) { next(err); }
};

const getCategories = async (req, res, next) => {
  try {
    const { categories, total, page, limit } = await itemCategoryService.getCategories(req.companyId, req.query);
    return sendPaginated(res, categories, { total, page, limit });
  } catch (err) { next(err); }
};

const getCategoryById = async (req, res, next) => {
  try {
    const category = await itemCategoryService.getCategoryById(req.companyId, req.params.id);
    return sendSuccess(res, category);
  } catch (err) { next(err); }
};

const updateCategory = async (req, res, next) => {
  try {
    const category = await itemCategoryService.updateCategory(req.companyId, req.params.id, req.body);
    return sendSuccess(res, category, 'Item Category updated successfully');
  } catch (err) { next(err); }
};

const deleteCategory = async (req, res, next) => {
  try {
    const category = await itemCategoryService.deleteCategory(req.companyId, req.params.id);
    return sendSuccess(res, category, 'Item Category deleted/deactivated successfully');
  } catch (err) { next(err); }
};

module.exports = {
  createCategory,
  getCategories,
  getCategoryById,
  updateCategory,
  deleteCategory
};
