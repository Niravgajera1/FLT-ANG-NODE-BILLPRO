const purchaseBillService = require('./purchaseBill.service');
const { sendSuccess, sendCreated, sendPaginated, sendError } = require('../../utils/responseHelper');

const createPurchaseBill = async (req, res, next) => {
  try {
    const bill = await purchaseBillService.createPurchaseBill(req.companyId, req.user.id, req.body);
    return sendCreated(res, bill, 'Purchase bill created successfully');
  } catch (err) { next(err); }
};

const getPurchaseBills = async (req, res, next) => {
  try {
    const { bills, total, page, limit } = await purchaseBillService.getPurchaseBills(req.companyId, req.query);
    return sendPaginated(res, bills, { total, page, limit });
  } catch (err) { next(err); }
};

const getPurchaseBillById = async (req, res, next) => {
  try {
    const bill = await purchaseBillService.getPurchaseBillById(req.companyId, req.params.id);
    return sendSuccess(res, bill);
  } catch (err) { next(err); }
};

const updatePurchaseBill = async (req, res, next) => {
  try {
    const bill = await purchaseBillService.updatePurchaseBill(req.companyId, req.params.id, req.user.id, req.body);
    return sendSuccess(res, bill, 'Purchase bill updated successfully');
  } catch (err) { next(err); }
};

const voidPurchaseBill = async (req, res, next) => {
  try {
    const result = await purchaseBillService.voidPurchaseBill(req.companyId, req.params.id, req.user.id, req.body.reason);
    return sendSuccess(res, result);
  } catch (err) { next(err); }
};

const getVendorOutstanding = async (req, res, next) => {
  try {
    const data = await purchaseBillService.getVendorOutstanding(req.companyId, req.query.vendorId);
    return sendSuccess(res, data);
  } catch (err) { next(err); }
};

module.exports = {
  createPurchaseBill, getPurchaseBills, getPurchaseBillById,
  updatePurchaseBill, voidPurchaseBill, getVendorOutstanding,
};
