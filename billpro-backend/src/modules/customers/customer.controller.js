const customerService = require('./customer.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

// Helper to get companyId from query, middleware, or user token
const getCompanyContext = (req) => {
    return req.query.companyId || req.companyId || req.user?.activeCompanyId;
};

const createCustomer = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const customer = await customerService.createCustomer(companyId, req.body);
        return sendCreated(res, { _id: customer._id }, 'Customer created successfully');
    } catch (e) {
        next(e);
    }
};

const getCustomers = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const { customers, total, page, limit } = await customerService.getCustomers(companyId, req.query);
        return sendPaginated(res, customers, { total, page, limit });
    } catch (e) {
        next(e);
    }
};

const getCustomerById = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const customer = await customerService.getCustomerById(companyId, req.params.id);
        return sendSuccess(res, customer);
    } catch (e) {
        next(e);
    }
};

const updateCustomer = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const customer = await customerService.updateCustomer(companyId, req.params.id, req.body);
        return sendSuccess(res, customer, 'Customer updated');
    } catch (e) {
        next(e);
    }
};

const deleteCustomer = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const customer = await customerService.deleteCustomer(companyId, req.params.id);
        return sendSuccess(res, customer, 'Customer deactivated');
    } catch (e) {
        next(e);
    }
};

const toggleCustomerStatus = async (req, res, next) => {
    try {
        const companyId = getCompanyContext(req);
        if (!companyId) {
            return res.status(400).json({ success: false, message: 'Company context required' });
        }
        const customer = await customerService.toggleCustomerStatus(companyId, req.params.id);
        const statusMsg = customer.isActive ? 'Customer activated successfully' : 'Customer deactivated successfully';
        return sendSuccess(res, customer, statusMsg);
    } catch (e) {
        next(e);
    }
};

module.exports = {
    createCustomer,
    getCustomers,
    getCustomerById,
    updateCustomer,
    deleteCustomer,
    toggleCustomerStatus
};
