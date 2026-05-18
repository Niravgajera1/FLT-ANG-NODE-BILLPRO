const fs = require('fs');
const path = require('path');
const { sendSuccess } = require('../../utils/responseHelper');

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

const Item = require('../items/item.model');
const Customer = require('../customers/customer.model');

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
      const items = await Item.find({ companyId, isActive: true }).select('_id name').lean();
      return sendSuccess(res, items, 'Items list fetched successfully');
    } else if (type === 2) {
      const customers = await Customer.find({ companyId }).select('_id name').lean();
      return sendSuccess(res, customers, 'Customers list fetched successfully');
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid type parameter. Use type=1 for items or type=2 for customers.'
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
