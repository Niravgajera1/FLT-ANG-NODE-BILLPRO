const fs = require('fs');
const path = require('path');
const { sendSuccess } = require('../../utils/responseHelper');
const Item = require('../items/item.model');
const Customer = require('../customers/customer.model');
const Vendor = require('../vendors/vendor.model');
const ItemCategory = require('../items/itemCategory.model');

const getCommonData = (req, res, next) => {
  try {
    const jsonPath = path.join(__dirname, 'common.json');
    const rawData = fs.readFileSync(jsonPath, 'utf8');
    const commonData = JSON.parse(rawData);

    const { type } = req.params;

    if (!type) {
      return sendSuccess(res, commonData, 'All common static data fetched');
    }

    if (commonData[type]) {
      return sendSuccess(res, commonData[type], `Fetched static data for ${type}`);
    } else {
      return res.status(404).json({
        success: false,
        message: `Static data type '${type}' not found`,
        availableTypes: Object.keys(commonData)
      });
    }
  } catch (err) {
    next(err);
  }
};



const getOptionsList = async (req, res, next) => {
  try {
    const { companyId } = req.params;
    const type = parseInt(req.query.type, 10);

    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID is required in request parameters'
      });
    }

    if (type === 1) {
      const query = { companyId, isActive: true };
      if (req.query.forType !== undefined) {
        const forType = parseInt(req.query.forType, 10);
        if (forType === 1) {
          query.is_selling = true;
        } else if (forType === 2) {
          query.is_selling = false;
        }
      }
      const items = await Item.find(query).select('_id name').lean();
      return sendSuccess(res, items, 'Items list fetched successfully');
    } else if (type === 2) {
      const customers = await Customer.find({ companyId }).select('_id name').lean();
      return sendSuccess(res, customers, 'Customers list fetched successfully');
    } else if (type === 3) {
      const vendors = await Vendor.find({ companyId }).select('_id name').lean();
      return sendSuccess(res, vendors, 'Vendors list fetched successfully');
    } else if (type === 4) {
      const categories = await ItemCategory.find({ companyId, isActive: true }).select('_id name').lean();
      return sendSuccess(res, categories, 'Categories list fetched successfully');
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid type parameter. Use type=1 for items, type=2 for customers, type=3 for vendors, or type=4 for item categories.'
      });
    }
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCommonData,
  getOptionsList,
};
