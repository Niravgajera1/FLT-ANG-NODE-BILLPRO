const mongoose = require('mongoose');
const { PAYMENT_TERMS } = require('../../config/constants');

const addressSchema = new mongoose.Schema({
  label:  { type: String, default: 'Primary' },
  line1:  { type: String },
  line2:  { type: String },
  city:   { type: String },
  state:  { type: String },
  stateCode: { type: String },
  pinCode:{ type: String },
  country:{ type: String, default: 'India' },
  isDefault: { type: Boolean, default: false },
}, { _id: true });

const customerSchema = new mongoose.Schema({
  companyId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  customerCode: { type: String },   // Auto-generated e.g., CUS-0001

  // ── Identity ──────────────────────────────────────────────────────────────
  name:         { type: String, required: true, trim: true },
  displayName:  { type: String, trim: true },
  customerType: { type: String, enum: ['B2B', 'B2C', 'export'], default: 'B2B' },
  gstin:        { type: String, uppercase: true },
  pan:          { type: String, uppercase: true },
  isGSTRegistered: { type: Boolean, default: true },

  // ── Contact ───────────────────────────────────────────────────────────────
  contactPerson: { type: String },
  mobile:       { type: String },
  email:        { type: String, lowercase: true },
  altMobile:    { type: String },
  website:      { type: String },

  // ── Addresses ─────────────────────────────────────────────────────────────
  addresses: [addressSchema],

  // ── Financial ─────────────────────────────────────────────────────────────
  paymentTerms:  { type: String, enum: PAYMENT_TERMS, default: 'Net 30' },
  creditLimit:   { type: Number, default: 0, min: 0 },
  openingBalance:{ type: Number, default: 0 },
  openingBalanceDate: { type: Date },

  // ── Pricing ───────────────────────────────────────────────────────────────
  priceListId: { type: mongoose.Schema.Types.ObjectId },  // Custom price list
  discountPercent: { type: Number, default: 0, min: 0, max: 100 },

  // ── Classification ────────────────────────────────────────────────────────
  customerGroup: { type: String },
  tags:          [{ type: String }],
  salespersonId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  notes:         { type: String, maxlength: 500 },
  isActive:      { type: Boolean, default: true },

}, { timestamps: true });

customerSchema.index({ companyId: 1, name: 1 });
customerSchema.index({ companyId: 1, gstin: 1 });
customerSchema.index({ companyId: 1, customerType: 1 });
customerSchema.index({ companyId: 1, isActive: 1 });

const Customer = mongoose.model('Customer', customerSchema);
module.exports = Customer;
