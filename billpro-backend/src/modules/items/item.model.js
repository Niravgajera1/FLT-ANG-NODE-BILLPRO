const mongoose = require('mongoose');
const { GST_RATES } = require('../../config/constants');

const itemSchema = new mongoose.Schema({
  companyId:  { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  itemCode:   { type: String },  // Auto-generated

  // ── Identity ──────────────────────────────────────────────────────────────
  name:         { type: String, required: true, trim: true },
  description:  { type: String, maxlength: 500 },
  itemType:     { type: String, enum: ['product', 'service'], required: true, default: 'product' },

  // ── Classification ────────────────────────────────────────────────────────
  hsnCode:    { type: String },   // For products
  sacCode:    { type: String },   // For services
  category:   { type: String },
  brand:      { type: String },
  unit:       { type: String, default: 'pcs' }, // pcs, kg, ltr, mtr, box, etc.

  // ── Pricing ───────────────────────────────────────────────────────────────
  sellingPrice:  { type: Number, min: 0, default: 0 },
  purchasePrice: { type: Number, min: 0, default: 0 },
  mrp:           { type: Number, min: 0 },
  priceInclGST:  { type: Boolean, default: false }, // If price includes GST

  // ── GST ───────────────────────────────────────────────────────────────────
  gstRate:    { type: Number, enum: GST_RATES, default: 18 },
  cessRate:   { type: Number, default: 0, min: 0 },
  isExempt:   { type: Boolean, default: false },
  itcEligibility: { type: String, enum: ['full', 'partial', 'blocked'], default: 'full' },

  // ── Inventory ─────────────────────────────────────────────────────────────
  trackInventory:   { type: Boolean, default: true },
  openingStock:     { type: Number, default: 0 },
  currentStock:     { type: Number, default: 0 },
  reorderLevel:     { type: Number, default: 0 },
  reorderQuantity:  { type: Number, default: 0 },
  warehouseLocation:{ type: String },
  batchTracking:    { type: Boolean, default: false },

  // ── Valuation ─────────────────────────────────────────────────────────────
  valuationMethod:  { type: String, enum: ['WAC', 'FIFO'], default: 'WAC' },
  avgCost:          { type: Number, default: 0 }, // Weighted Average Cost

  // ── Status ────────────────────────────────────────────────────────────────
  isActive:   { type: Boolean, default: true },
  imageUrl:   { type: String },
  notes:      { type: String },

}, { timestamps: true });

itemSchema.index({ companyId: 1, name: 1 });
itemSchema.index({ companyId: 1, hsnCode: 1 });
itemSchema.index({ companyId: 1, itemType: 1, isActive: 1 });
// Text search index
itemSchema.index({ name: 'text', description: 'text', hsnCode: 'text', sacCode: 'text' });

const Item = mongoose.model('Item', itemSchema);
module.exports = Item;
