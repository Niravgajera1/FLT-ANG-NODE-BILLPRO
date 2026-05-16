const mongoose = require('mongoose');
const { BILL_STATUS, INVOICE_TYPES, GST_RATES, SUPPLY_TYPES } = require('../../config/constants');

const lineItemSchema = new mongoose.Schema({
  itemId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
  itemName:    { type: String, required: true },
  description: { type: String },
  hsnCode:     { type: String },
  sacCode:     { type: String },
  quantity:    { type: Number, required: true, min: 0 },
  unit:        { type: String, default: 'pcs' },
  unitPrice:   { type: Number, required: true, min: 0 },
  mrp:         { type: Number },

  discountPercent: { type: Number, default: 0 },
  discountFlat:    { type: Number, default: 0 },
  discountAmount:  { type: Number, default: 0 },

  gstRate:      { type: Number, enum: GST_RATES, default: 18 },
  cessRate:     { type: Number, default: 0 },
  taxableValue: { type: Number, default: 0 },
  cgst:         { type: Number, default: 0 },
  sgst:         { type: Number, default: 0 },
  igst:         { type: Number, default: 0 },
  cess:         { type: Number, default: 0 },
  totalTax:     { type: Number, default: 0 },
  lineTotal:    { type: Number, default: 0 },
}, { _id: true });

const salesInvoiceSchema = new mongoose.Schema({
  companyId:  { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  branchId:   { type: mongoose.Schema.Types.ObjectId },
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  salespersonId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // ── Invoice Identity ──────────────────────────────────────────────────────
  invoiceNumber: { type: String, required: true },
  invoiceType:   { type: String, enum: Object.values(INVOICE_TYPES), default: INVOICE_TYPES.TAX_INVOICE },
  customerPONumber: { type: String },

  // ── Customer ──────────────────────────────────────────────────────────────
  customerId:      { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true },
  customerName:    { type: String },  // Snapshot
  customerGSTIN:   { type: String },
  billingAddress:  { type: Object },
  shippingAddress: { type: Object },

  // ── Dates ─────────────────────────────────────────────────────────────────
  invoiceDate: { type: Date, required: true, default: Date.now },
  dueDate:     { type: Date },
  supplyDate:  { type: Date },

  // ── Supply Details ────────────────────────────────────────────────────────
  supplyType:    { type: String, enum: Object.values(SUPPLY_TYPES), default: SUPPLY_TYPES.INTRA_STATE },
  placeOfSupply: { type: String },
  dispatchFrom:  { type: String },
  isRCM:         { type: Boolean, default: false },

  // ── Export ────────────────────────────────────────────────────────────────
  isExport:      { type: Boolean, default: false },
  exportType:    { type: String, enum: ['with_tax', 'without_tax', 'LUT', 'bond'] },
  shippingBillNo:{ type: String },
  portCode:      { type: String },

  // ── Line Items ────────────────────────────────────────────────────────────
  lineItems: { type: [lineItemSchema], required: true, validate: v => v.length > 0 },

  // ── Totals ────────────────────────────────────────────────────────────────
  subTotal:          { type: Number, default: 0 },
  totalDiscount:     { type: Number, default: 0 },
  totalTaxableValue: { type: Number, default: 0 },
  totalCGST:         { type: Number, default: 0 },
  totalSGST:         { type: Number, default: 0 },
  totalIGST:         { type: Number, default: 0 },
  totalCess:         { type: Number, default: 0 },
  totalTax:          { type: Number, default: 0 },
  roundOff:          { type: Number, default: 0 },
  grandTotal:        { type: Number, required: true },
  amountInWords:     { type: String },

  // ── E-Invoice (IRP) ───────────────────────────────────────────────────────
  irn:           { type: String },           // Invoice Reference Number from IRP
  qrCode:        { type: String },           // QR code data
  ackNumber:     { type: String },           // IRP acknowledgment number
  ackDate:       { type: Date },
  eInvoiceStatus:{ type: String, enum: ['pending', 'generated', 'cancelled', 'not_applicable'], default: 'not_applicable' },

  // ── E-Way Bill ────────────────────────────────────────────────────────────
  ewbNumber:     { type: String },
  ewbDate:       { type: Date },
  ewbExpiryDate: { type: Date },
  vehicleNumber: { type: String },
  transporterName: { type: String },
  transportMode: { type: String, enum: ['road', 'rail', 'air', 'ship'] },

  // ── Payment ───────────────────────────────────────────────────────────────
  status:       { type: String, enum: Object.values(BILL_STATUS), default: BILL_STATUS.SAVED },
  paidAmount:   { type: Number, default: 0 },
  balanceDue:   { type: Number, default: 0 },
  paymentTerms: { type: String },

  // ── For Proforma ──────────────────────────────────────────────────────────
  validUntil:      { type: Date },
  quotationStatus: { type: String, enum: ['pending', 'accepted', 'rejected', 'expired'] },
  convertedToInvoiceId: { type: mongoose.Schema.Types.ObjectId, ref: 'SalesInvoice' },

  // ── Credit Notes ──────────────────────────────────────────────────────────
  creditNoteIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CreditNote' }],

  // ── Settings ──────────────────────────────────────────────────────────────
  termsAndConditions: { type: String },
  notes:              { type: String },
  attachments: [{
    fileName: String,
    fileUrl:  String,
    mimeType: String,
  }],

  isVoid:     { type: Boolean, default: false },
  voidReason: { type: String },

}, { timestamps: true });

// ─── Indexes ──────────────────────────────────────────────────────────────────
salesInvoiceSchema.index({ companyId: 1, invoiceDate: -1 });
salesInvoiceSchema.index({ companyId: 1, customerId: 1 });
salesInvoiceSchema.index({ companyId: 1, status: 1 });
salesInvoiceSchema.index({ companyId: 1, invoiceNumber: 1 }, { unique: true });
salesInvoiceSchema.index({ companyId: 1, dueDate: 1 });
salesInvoiceSchema.index({ companyId: 1, invoiceType: 1 });
salesInvoiceSchema.index({ irn: 1 }, { sparse: true });

salesInvoiceSchema.pre('save', function (next) {
  this.balanceDue = Math.max(0, this.grandTotal - this.paidAmount);
  if (this.paidAmount >= this.grandTotal) this.status = BILL_STATUS.PAID;
  else if (this.paidAmount > 0) this.status = BILL_STATUS.PARTIALLY_PAID;
  next();
});

const SalesInvoice = mongoose.model('SalesInvoice', salesInvoiceSchema);
module.exports = SalesInvoice;
