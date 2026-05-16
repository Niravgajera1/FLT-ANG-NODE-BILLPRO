const customerService = require('./customer.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

const createCustomer  = async (req, res, next) => { try { return sendCreated(res, await customerService.createCustomer(req.companyId, req.body)); } catch (e) { next(e); } };
const getCustomers    = async (req, res, next) => { try { const { customers, total, page, limit } = await customerService.getCustomers(req.companyId, req.query); return sendPaginated(res, customers, { total, page, limit }); } catch (e) { next(e); } };
const getCustomerById = async (req, res, next) => { try { return sendSuccess(res, await customerService.getCustomerById(req.companyId, req.params.id)); } catch (e) { next(e); } };
const updateCustomer  = async (req, res, next) => { try { return sendSuccess(res, await customerService.updateCustomer(req.companyId, req.params.id, req.body), 'Customer updated'); } catch (e) { next(e); } };
const deleteCustomer  = async (req, res, next) => { try { return sendSuccess(res, await customerService.deleteCustomer(req.companyId, req.params.id), 'Customer deactivated'); } catch (e) { next(e); } };

module.exports = { createCustomer, getCustomers, getCustomerById, updateCustomer, deleteCustomer };
