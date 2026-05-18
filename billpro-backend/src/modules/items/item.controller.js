const itemService = require('./item.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

const createItem = async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (req.file) {
      data.image = req.file.filename;
    }
    const companyId = req.body.companyId || req.companyId;
    return sendCreated(res, await itemService.createItem(companyId, data));
  } catch (e) { next(e); }
};

const getItems = async (req, res, next) => {
  try {
    const { items, total, page, limit } = await itemService.getItems(req.companyId, req.query);
    return sendPaginated(res, items, { total, page, limit });
  } catch (e) { next(e); }
};

const getItemById = async (req, res, next) => {
  try {
    return sendSuccess(res, await itemService.getItemById(req.companyId, req.params.id));
  } catch (e) { next(e); }
};

const updateItem = async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (req.file) {
      data.image = req.file.filename;
    }
    return sendSuccess(res, await itemService.updateItem(req.companyId, req.params.id, data), 'Item updated');
  } catch (e) { next(e); }
};

const deleteItem = async (req, res, next) => {
  try {
    return sendSuccess(res, await itemService.deleteItem(req.companyId, req.params.id), 'Item deactivated');
  } catch (e) { next(e); }
};

module.exports = { createItem, getItems, getItemById, updateItem, deleteItem };
