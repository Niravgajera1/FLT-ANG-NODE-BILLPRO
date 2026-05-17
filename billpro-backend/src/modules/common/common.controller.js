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

module.exports = {
  getCommonData,
};
