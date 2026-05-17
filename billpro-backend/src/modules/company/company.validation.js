const Joi = require('joi');
const { BUSINESS_TYPES, GST_TYPES } = require('../../config/constants');

const addressSchema = Joi.object({
  line1: Joi.string().max(200).required(),
  line2: Joi.string().max(200).optional().allow(''),
  city: Joi.string().required(),
  state: Joi.string().required(),
  stateCode: Joi.string().optional().allow(''),
  pinCode: Joi.string().pattern(/^[1-9][0-9]{5}$/).required().messages({
    'string.pattern.base': 'Enter a valid 6-digit Indian PIN code',
  }),
  country: Joi.string().default('India').optional(),
});

const bankAccountSchema = Joi.object({
  bankName: Joi.string().optional().allow(''),
  accountHolderName: Joi.string().optional().allow(''),
  accountNumber: Joi.string().optional().allow(''),
  ifscCode: Joi.string().optional().allow(''),
  accountType: Joi.string().valid('savings', 'current', 'overdraft').optional(),
  branchName: Joi.string().optional().allow(''),
  branchAddress: Joi.string().optional().allow(''),
  upiId: Joi.string().optional().allow(''),
  isDefault: Joi.boolean().default(false),
});

const schemas = {
  createCompany: Joi.object({
    legalName: Joi.string().max(200).required(),
    tradeName: Joi.string().max(100).optional().allow(''),
    businessType: Joi.string().valid(...BUSINESS_TYPES).required(),
    gstin: Joi.string().optional().allow(''),
    pan: Joi.string().required(),
    fssaiNumber: Joi.string().optional().allow(''),
    gstType: Joi.string().valid(...Object.values(GST_TYPES)).default(GST_TYPES.REGULAR),
    isGSTRegistered: Joi.boolean().default(true),
    businessCategory: Joi.string().valid('Retail', 'Wholesale', 'Service', 'Manufacturing', 'Other').required(),
    industryType: Joi.string().optional().allow(''),
    mobile: Joi.string().pattern(/^[6-9]\d{9}$/).required().messages({
      'string.pattern.base': 'Enter a valid 10-digit Indian mobile number',
    }),
    email: Joi.string().email().required(),
    website: Joi.string().uri().optional().allow(''),
    registeredAddress: addressSchema.required(),
    tcsEnabled: Joi.boolean().optional(),
    tdsEnabled: Joi.boolean().optional(),
    fyStartMonth: Joi.number().min(1).max(12).optional(),
    bankAccounts: Joi.array().items(bankAccountSchema).optional(),
  }),

  updateCompany: Joi.object({
    legalName: Joi.string().max(200).optional(),
    tradeName: Joi.string().max(100).optional().allow(''),
    businessType: Joi.string().valid(...BUSINESS_TYPES).optional(),
    gstin: Joi.string().optional().allow(''),
    pan: Joi.string().optional(),
    fssaiNumber: Joi.string().optional().allow(''),
    gstType: Joi.string().valid(...Object.values(GST_TYPES)).optional(),
    isGSTRegistered: Joi.boolean().optional(),
    businessCategory: Joi.string().valid('Retail', 'Wholesale', 'Service', 'Manufacturing', 'Other').optional(),
    industryType: Joi.string().optional().allow(''),
    mobile: Joi.string().pattern(/^[6-9]\d{9}$/).optional().messages({
      'string.pattern.base': 'Enter a valid 10-digit Indian mobile number',
    }),
    email: Joi.string().email().optional(),
    website: Joi.string().uri().optional().allow(''),
    registeredAddress: addressSchema.optional(),
    bankAccounts: Joi.array().items(bankAccountSchema).optional(),
  })
};

const validate = (schema) => (req, res, next) => {
  // Use stripUnknown: true to remove fields not defined in the schema
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(d => ({ field: d.path.join('.'), message: d.message })),
    });
  }
  
  // Reassign req.body with the sanitized and validated value
  req.body = value;
  next();
};

module.exports = { schemas, validate };
