const Company = require('./company.model');
const User = require('../users/user.model');
const { validateGSTIN, validatePAN } = require('../../utils/gstCalculator');
const { createAuditLog } = require('../../middleware/auditLog');
const axios = require('axios');
const logger = require('../../utils/logger');

const createCompany = async (userId, data) => {
  // Validate GSTIN if provided
  // if (data.gstin && !validateGSTIN(data.gstin)) {
  //   throw Object.assign(new Error('Invalid GSTIN format'), { statusCode: 400 });
  // }
  // if (data.pan && !validatePAN(data.pan)) {
  //   throw Object.assign(new Error('Invalid PAN format'), { statusCode: 400 });
  // }

  // Check company limit per plan (5 for basic)
  const user = await User.findById(userId).populate('companies.companyId');
  const existingCount = user.companies?.length || 0;
  if (existingCount >= 5) {
    throw Object.assign(new Error('Company limit reached for your plan. Upgrade to add more.'), { statusCode: 403 });
  }

  const company = await Company.create({ ...data, ownerId: userId });

  // Link company to user
  await User.updateOne(
    { _id: userId },
    {
      $push: { companies: { companyId: company._id, role: 'company_admin', isOwner: true } },
      $set: { activeCompanyId: company._id },
    }
  );

  await createAuditLog({ userId: userId.toString(), companyId: company._id.toString(), action: 'CREATE', module: 'company', recordId: company._id.toString() });
  return company;
};

const getCompany = async (companyId, userId) => {
  let targetCompanyId = companyId;

  // Fallback to activeCompanyId or first company associated with the user if companyId is not passed
  if (!targetCompanyId && userId) {
    const user = await User.findById(userId);
    if (user) {
      targetCompanyId = user.activeCompanyId || (user.companies && user.companies[0]?.companyId);
    }
  }

  if (!targetCompanyId) {
    throw Object.assign(new Error('Company ID is required'), { statusCode: 400 });
  }

  const company = await Company.findById(targetCompanyId);
  if (!company) throw Object.assign(new Error('Company not found'), { statusCode: 404 });
  
  return company;
};

const updateCompany = async (companyId, userId, data) => {
  // if (data.gstin && !validateGSTIN(data.gstin)) {
  //   throw Object.assign(new Error('Invalid GSTIN format'), { statusCode: 400 });
  // }

  const company = await Company.findByIdAndUpdate(
    companyId,
    { $set: data },
    { new: true, runValidators: true }
  );
  if (!company) throw Object.assign(new Error('Company not found'), { statusCode: 404 });

  await createAuditLog({ userId: userId.toString(), companyId: companyId.toString(), action: 'UPDATE', module: 'company', recordId: companyId });
  return company;
};

const uploadLogo = async (companyId, fileUrl) => {
  return Company.findByIdAndUpdate(
    companyId,
    { 'invoiceSettings.logoUrl': fileUrl },
    { new: true }
  );
};


/**
 * Validate GSTIN via GST Portal API
 */
// const validateGSTINOnline = async (gstin) => {
//   if (!validateGSTIN(gstin)) return { valid: false, reason: 'Invalid format' };

//   try {
//     // Integration with GSP/GSTN API
//     const response = await axios.get(`${process.env.GSTIN_VALIDATE_URL}/taxpayerapi/tp/${gstin}`, {
//       headers: { Authorization: `Bearer ${process.env.GSP_API_KEY}` },
//       timeout: 5000,
//     });
//     return { valid: true, data: response.data };
//   } catch (err) {
//     logger.warn('GSTIN online validation failed, falling back to format check:', err.message);
//     return { valid: true, offline: true, reason: 'GST portal unavailable — format validated only' };
//   }
// };

/**
 * Validate IFSC and get bank details
 */
// const validateIFSC = async (ifsc) => {
//   try {
//     const response = await axios.get(`${process.env.RAZORPAY_IFSC_URL}/${ifsc}`, { timeout: 5000 });
//     return { valid: true, data: response.data };
//   } catch (err) {
//     if (err.response?.status === 404) return { valid: false, reason: 'Invalid IFSC code' };
//     throw Object.assign(new Error('IFSC validation service unavailable'), { statusCode: 503 });
//   }
// };

const addBankAccount = async (companyId, bankData) => {
  const company = await Company.findById(companyId);
  if (!company) throw Object.assign(new Error('Company not found'), { statusCode: 404 });

  if (bankData.isDefault) {
    company.bankAccounts.forEach(b => b.isDefault = false);
  }
  company.bankAccounts.push(bankData);
  await company.save();
  return company;
};

module.exports = {
  createCompany, getCompany, updateCompany, uploadLogo,
  // validateGSTINOnline, validateIFSC, 
  addBankAccount,
};
