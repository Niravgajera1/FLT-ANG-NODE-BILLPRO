const mongoose = require('mongoose');
const { PAYMENT_TERMS } = require('../../config/constants');

const vendorSchema = new mongoose.Schema({
  companyId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  vendorCode:   { type: String },   // Auto-generated e.g., VND-0001

  // ── Identity ──────────────────────────────────────────────────────────────
  name:         { type: String, required: true, trim: true },
  displayName:  { type: String, trim: true },
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
  registeredAddress: {
    line1:  { type: String },
    line2:  { type: String },
    city:   { type: String },
    state:  { type: String },
    stateCode: { type: String },
    pinCode:{ type: String },
    country:{ type: String, default: 'India' },
  },
  billingAddress: {
    line1:  { type: String },
    line2:  { type: String },
    city:   { type: String },
    state:  { type: String },
    stateCode: { type: String },
    pinCode:{ type: String },
  },

  // ── Financial ─────────────────────────────────────────────────────────────
  paymentTerms:  { type: String, enum: PAYMENT_TERMS, default: 'Net 30' },
  creditLimit:   { type: Number, default: 0, min: 0 },
  openingBalance:{ type: Number, default: 0 },
  openingBalanceDate: { type: Date },

  // ── Bank Details ──────────────────────────────────────────────────────────
  bankName:      { type: String },
  accountNumber: { type: String },
  ifscCode:      { type: String },
  accountType:   { type: String },

  // ── RCM ───────────────────────────────────────────────────────────────────
  isRCMApplicable: { type: Boolean, default: false },

  // ── Classification ────────────────────────────────────────────────────────
  tags:          [{ type: String }],
  notes:         { type: String, maxlength: 500 },
  isActive:      { type: Boolean, default: true },

}, { timestamps: true });

vendorSchema.index({ companyId: 1, name: 1 });
vendorSchema.index({ companyId: 1, gstin: 1 });
vendorSchema.index({ companyId: 1, isActive: 1 });

const Vendor = mongoose.model('Vendor', vendorSchema);
module.exports = Vendor;
