const vendorService = require('./vendor.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

const createVendor = async (req, res, next) => { try { return sendCreated(res, await vendorService.createVendor(req.companyId, req.body)); } catch (e) { next(e); } };
const getVendors = async (req, res, next) => { try { const { vendors, total, page, limit } = await vendorService.getVendors(req.companyId, req.query); return sendPaginated(res, vendors, { total, page, limit }); } catch (e) { next(e); } };
const getVendorById = async (req, res, next) => { try { return sendSuccess(res, await vendorService.getVendorById(req.companyId, req.params.id)); } catch (e) { next(e); } };
const updateVendor = async (req, res, next) => { try { return sendSuccess(res, await vendorService.updateVendor(req.companyId, req.params.id, req.body), 'Vendor updated'); } catch (e) { next(e); } };
const deleteVendor = async (req, res, next) => {
  try {
    const vendor = await vendorService.deleteVendor(req.companyId, req.params.id);
    const message = vendor.isActive ? 'Vendor activated successfully' : 'Vendor deactivated successfully';
    return sendSuccess(res, vendor, message);
  } catch (e) {
    next(e);
  }
};

module.exports = { createVendor, getVendors, getVendorById, updateVendor, deleteVendor };
