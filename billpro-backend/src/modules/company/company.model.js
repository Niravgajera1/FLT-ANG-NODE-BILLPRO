const mongoose = require('mongoose');
const { BUSINESS_TYPES, GST_TYPES, PAYMENT_TERMS } = require('../../config/constants');

const addressSchema = new mongoose.Schema({
  line1: { type: String, required: true, maxlength: 200 },
  line2: { type: String, maxlength: 200 },
  city: { type: String, required: true },
  state: { type: String, required: true },
  stateCode: { type: String },
  pinCode: { type: String, required: true, match: /^[1-9][0-9]{5}$/ },
  country: { type: String, default: 'India' },
}, { _id: false });

const bankDetailsSchema = new mongoose.Schema({
  bankName: { type: String },
  accountHolderName: { type: String },
  accountNumber: { type: String },
  ifscCode: { type: String },
  accountType: { type: String, enum: ['savings', 'current', 'overdraft'] },
  branchName: { type: String },
  branchAddress: { type: String },
  upiId: { type: String },
  isDefault: { type: Boolean, default: false },
}, { _id: true });

// const branchSchema = new mongoose.Schema({
//   name: { type: String, required: true },
//   gstin: { type: String },
//   address: addressSchema,
//   mobile: { type: String },
//   email: { type: String },
//   isDefault: { type: Boolean, default: false },
//   isActive: { type: Boolean, default: true },
// }, { timestamps: true });

const companySchema = new mongoose.Schema({
  // ── Ownership ─────────────────────────────────────────────────────────────
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // ── Legal Info ────────────────────────────────────────────────────────────
  legalName: { type: String, required: true, trim: true, maxlength: 200 },
  tradeName: { type: String, trim: true, maxlength: 100 },
  businessType: { type: String, enum: BUSINESS_TYPES, required: true },
  gstin: { type: String, uppercase: true, sparse: true },
  pan: { type: String, uppercase: true, required: true },
  fssaiNumber: { type: String },

  // ── GST Config ────────────────────────────────────────────────────────────
  gstType: { type: String, enum: Object.values(GST_TYPES), default: GST_TYPES.REGULAR },
  isGSTRegistered: { type: Boolean, default: true },
  tcsEnabled: { type: Boolean, default: false },
  tdsEnabled: { type: Boolean, default: false },
  rcmVendors: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Vendor' }],

  // ── Business Category ─────────────────────────────────────────────────────
  businessCategory: {
    type: String,
    enum: ['Retail', 'Wholesale', 'Service', 'Manufacturing', 'Other'],
    required: true,
  },
  industryType: { type: String },

  // ── Contact ───────────────────────────────────────────────────────────────
  mobile: { type: String, required: true },
  email: { type: String, required: true },
  website: { type: String },

  // ── Address ───────────────────────────────────────────────────────────────
  registeredAddress: { type: addressSchema, required: true },

  // ── Financial Year ────────────────────────────────────────────────────────
  fyStartMonth: { type: Number, default: 4, min: 1, max: 12 }, // 4 = April

  // ── Invoice Settings ──────────────────────────────────────────────────────
  // invoiceSettings: {
  //   prefix: { type: String, default: 'INV' },
  //   purchasePrefix: { type: String, default: 'PB' },
  //   nextInvoiceNumber: { type: Number, default: 1 },
  //   defaultPaymentTerms: { type: String, enum: PAYMENT_TERMS, default: 'Net 30' },
  //   defaultNotes: { type: String, maxlength: 500 },
  //   defaultTerms: { type: String, maxlength: 1000 },
  //   showSignature: { type: Boolean, default: true },
  //   showLogo: { type: Boolean, default: true },
  //   logoUrl: { type: String },
  //   signatureUrl: { type: String },
  // },

  // ── Bank Accounts ─────────────────────────────────────────────────────────
  bankAccounts: [bankDetailsSchema],

  // ── Branches ──────────────────────────────────────────────────────────────
  // branches: [branchSchema],

  // ── Subscription ─────────────────────────────────────────────────────────
  // plan: { type: String, enum: ['basic', 'professional', 'enterprise'], default: 'basic' },
  // planExpiry: { type: Date },
  // isActive: { type: Boolean, default: true },

}, { timestamps: true });

// ─── Indexes ──────────────────────────────────────────────────────────────────
companySchema.index({ ownerId: 1 });
companySchema.index({ pan: 1 });

const Company = mongoose.model('Company', companySchema);
module.exports = Company;
