const mongoose = require('mongoose');
const { BILL_STATUS, GST_RATES, SUPPLY_TYPES, ITC_TYPES } = require('../../config/constants');

const lineItemSchema = new mongoose.Schema({
  itemId: { type: mongoose.Schema.Types.ObjectId, ref: 'Item' },
  itemName: { type: String, required: true },  // Snapshot at time of bill
  description: { type: String },
  hsnCode: { type: String },
  sacCode: { type: String },
  quantity: { type: Number, required: true, min: 0 },
  unit: { type: String, default: 'pcs' },
  unitPrice: { type: Number, required: true, min: 0 },

  // Discount
  discountPercent: { type: Number, default: 0, min: 0, max: 100 },
  discountFlat: { type: Number, default: 0, min: 0 },
  discountAmount: { type: Number, default: 0 },

  // GST
  gstRate: { type: Number, default: 18 },
  cessRate: { type: Number, default: 0 },
  taxableValue: { type: Number, default: 0 },
  cgst: { type: Number, default: 0 },
  sgst: { type: Number, default: 0 },
  igst: { type: Number, default: 0 },
  cess: { type: Number, default: 0 },
  totalTax: { type: Number, default: 0 },
  lineTotal: { type: Number, default: 0 },

  // ITC
  // itcEligibility: { type: String, enum: Object.values(ITC_TYPES), default: ITC_TYPES.FULL },

  // Batch tracking
  batchNumber: { type: String },
  batchExpiry: { type: Date },
}, { _id: true });

const purchaseBillSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  branchId: { type: mongoose.Schema.Types.ObjectId },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // ── Bill Numbers ─────────────────────────────────────────────────────────
  billNumber: { type: String, required: true },   // Internal: PB-2025-26-0001
  vendorBillNumber: { type: String },                   // Vendor's original bill number
  poReference: { type: String },

  // ── Vendor ────────────────────────────────────────────────────────────────
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  vendorName: { type: String },   // Snapshot
  vendorGSTIN: { type: String },
  vendorAddress: { type: Object },

  // ── Dates ─────────────────────────────────────────────────────────────────
  vendorBillDate: { type: Date, required: true },
  billDate: { type: Date, required: true, default: Date.now },
  dueDate: { type: Date },

  // ── Supply Details ────────────────────────────────────────────────────────
  supplyType: { type: String, enum: Object.values(SUPPLY_TYPES), default: SUPPLY_TYPES.INTRA_STATE },
  placeOfSupply: { type: String },
  isRCM: { type: Boolean, default: false },

  // ── Line Items ────────────────────────────────────────────────────────────
  lineItems: { type: [lineItemSchema], required: true, validate: v => v.length > 0 },

  // ── Totals ────────────────────────────────────────────────────────────────
  subTotal: { type: Number, default: 0 },
  totalDiscount: { type: Number, default: 0 },
  totalTaxableValue: { type: Number, default: 0 },
  totalCGST: { type: Number, default: 0 },
  totalSGST: { type: Number, default: 0 },
  totalIGST: { type: Number, default: 0 },
  totalCess: { type: Number, default: 0 },
  totalTax: { type: Number, default: 0 },
  roundOff: { type: Number, default: 0 },
  grandTotal: { type: Number, required: true },
  amountInWords: { type: String },

  // ── ITC ───────────────────────────────────────────────────────────────────
  totalITC: { type: Number, default: 0 },
  blockedITC: { type: Number, default: 0 },

  // ── Payment ───────────────────────────────────────────────────────────────
  status: { type: String, enum: Object.values(BILL_STATUS), default: BILL_STATUS.SAVED },
  paidAmount: { type: Number, default: 0 },
  balanceDue: { type: Number, default: 0 },
  paymentTerms: { type: String },

  // ── Attachments ───────────────────────────────────────────────────────────
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String,
    uploadedAt: { type: Date, default: Date.now },
  }],

  // ── Debit Notes linked to this bill ───────────────────────────────────────
  debitNoteIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'DebitNote' }],

  narration: { type: String, maxlength: 500 },
  tags: [{ type: String }],
  isVoid: { type: Boolean, default: false },
  voidReason: { type: String },
  voidedAt: { type: Date },
  voidedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: true });

// ─── Indexes ──────────────────────────────────────────────────────────────────
purchaseBillSchema.index({ companyId: 1, billDate: -1 });
purchaseBillSchema.index({ companyId: 1, vendorId: 1 });
purchaseBillSchema.index({ companyId: 1, status: 1 });
purchaseBillSchema.index({ companyId: 1, billNumber: 1 }, { unique: true });
purchaseBillSchema.index({ companyId: 1, dueDate: 1 });

purchaseBillSchema.pre('save', function () {
  this.balanceDue = Math.max(0, this.grandTotal - this.paidAmount);
  if (this.paidAmount >= this.grandTotal) this.status = BILL_STATUS.PAID;
  else if (this.paidAmount > 0) this.status = BILL_STATUS.PARTIALLY_PAID;
});

const PurchaseBill = mongoose.model('PurchaseBill', purchaseBillSchema);
module.exports = PurchaseBill;
