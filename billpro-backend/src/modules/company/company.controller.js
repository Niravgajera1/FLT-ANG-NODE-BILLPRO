const companyService = require('./company.service');
const { sendSuccess, sendCreated } = require('../../utils/responseHelper');

const createCompany = async (req, res, next) => {
  try {
    const company = await companyService.createCompany(req.user.id, req.body);
    return sendCreated(res, company, 'Company created successfully');
  } catch (err) { next(err); }
};

const getCompany = async (req, res, next) => {
  try {
    const company = await companyService.getCompany(req.companyId, req.user.id);
    return sendSuccess(res, company);
  } catch (err) { next(err); }
};

const updateCompany = async (req, res, next) => {
  try {
    const company = await companyService.updateCompany(req.companyId, req.user.id, req.body);
    return sendSuccess(res, company, 'Company updated successfully');
  } catch (err) { next(err); }
};

const validateGSTIN = async (req, res, next) => {
  try {
    const result = await companyService.validateGSTINOnline(req.params.gstin);
    return sendSuccess(res, result);
  } catch (err) { next(err); }
};

const validateIFSC = async (req, res, next) => {
  try {
    const result = await companyService.validateIFSC(req.params.ifsc);
    return sendSuccess(res, result);
  } catch (err) { next(err); }
};

const addBranch = async (req, res, next) => {
  try {
    const company = await companyService.addBranch(req.companyId, req.user.id, req.body);
    return sendCreated(res, company, 'Branch added successfully');
  } catch (err) { next(err); }
};

const updateBranch = async (req, res, next) => {
  try {
    const company = await companyService.updateBranch(req.companyId, req.params.branchId, req.body);
    return sendSuccess(res, company, 'Branch updated');
  } catch (err) { next(err); }
};

const addBankAccount = async (req, res, next) => {
  try {
    const company = await companyService.addBankAccount(req.companyId, req.body);
    return sendCreated(res, company, 'Bank account added');
  } catch (err) { next(err); }
};

module.exports = {
  createCompany, getCompany, updateCompany,
  validateGSTIN, validateIFSC,
  addBranch, updateBranch, addBankAccount,
};
