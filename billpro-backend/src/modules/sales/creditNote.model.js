const mongoose = require('mongoose');
const { GST_RATES } = require('../../config/constants');

const lineItemSchema = new mongoose.Schema({
  itemId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
  itemName:    { type: String, required: true },
  hsnCode:     { type: String },
  quantity:    { type: Number, required: true, min: 0 },
  unit:        { type: String, default: 'pcs' },
  unitPrice:   { type: Number, required: true, min: 0 },
  gstRate:     { type: Number, enum: GST_RATES },
  taxableValue:{ type: Number, default: 0 },
  cgst:        { type: Number, default: 0 },
  sgst:        { type: Number, default: 0 },
  igst:        { type: Number, default: 0 },
  lineTotal:   { type: Number, default: 0 },
}, { _id: true });

// ─── Credit Note (Sales Return) ───────────────────────────────────────────────
const creditNoteSchema = new mongoose.Schema({
  companyId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  creditNoteNumber: { type: String, required: true },
  invoiceId:      { type: mongoose.Schema.Types.ObjectId, ref: 'SalesInvoice', required: true },
  customerId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true },
  creditNoteDate: { type: Date, required: true, default: Date.now },
  reason:         { type: String, required: true },

  lineItems:      [lineItemSchema],
  totalTaxableValue: { type: Number, default: 0 },
  totalCGST:      { type: Number, default: 0 },
  totalSGST:      { type: Number, default: 0 },
  totalIGST:      { type: Number, default: 0 },
  totalAmount:    { type: Number, required: true },

  // Inventory update
  updateInventory: { type: Boolean, default: true },
  inventoryUpdated: { type: Boolean, default: false },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
}, { timestamps: true });

creditNoteSchema.index({ companyId: 1, creditNoteDate: -1 });
creditNoteSchema.index({ companyId: 1, invoiceId: 1 });

// ─── Debit Note (Purchase Return) ─────────────────────────────────────────────
const debitNoteSchema = new mongoose.Schema({
  companyId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  debitNoteNumber:{ type: String, required: true },
  purchaseBillId: { type: mongoose.Schema.Types.ObjectId, ref: 'PurchaseBill', required: true },
  vendorId:       { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  debitNoteDate:  { type: Date, required: true, default: Date.now },
  reason:         { type: String, required: true },

  lineItems:      [lineItemSchema],
  totalTaxableValue: { type: Number, default: 0 },
  totalCGST:      { type: Number, default: 0 },
  totalSGST:      { type: Number, default: 0 },
  totalIGST:      { type: Number, default: 0 },
  totalAmount:    { type: Number, required: true },

  // ITC reversal
  itcReversal:    { type: Number, default: 0 },
  inventoryUpdated: { type: Boolean, default: false },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
}, { timestamps: true });

debitNoteSchema.index({ companyId: 1, debitNoteDate: -1 });
debitNoteSchema.index({ companyId: 1, purchaseBillId: 1 });

const CreditNote = mongoose.model('CreditNote', creditNoteSchema);
const DebitNote  = mongoose.model('DebitNote',  debitNoteSchema);

module.exports = { CreditNote, DebitNote };
