const mongoose = require('mongoose');

// ─── Inventory (current stock levels) ────────────────────────────────────────
const inventorySchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  itemId: { type: mongoose.Schema.Types.ObjectId, ref: 'Item', required: true },
  // branchId: { type: mongoose.Schema.Types.ObjectId },

  currentStock: { type: Number, default: 0 },
  avgCost: { type: Number, default: 0 },   // Weighted Average Cost
  totalValue: { type: Number, default: 0 },   // currentStock * avgCost
  reorderLevel: { type: Number, default: 0 },
  isLowStock: { type: Boolean, default: false },

}, { timestamps: true });

inventorySchema.index({ companyId: 1, itemId: 1, branchId: 1 }, { unique: true });

// ─── Stock Movement (transaction log) ─────────────────────────────────────────
const stockMovementSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  itemId: { type: mongoose.Schema.Types.ObjectId, ref: 'Item', required: true },
  // branchId:     { type: mongoose.Schema.Types.ObjectId },

  movementType: {
    type: String,
    enum: ['purchase', 'sale', 'purchase_return', 'sale_return', 'adjustment', 'opening'],
    required: true,
  },
  referenceType: { type: String }, // 'PurchaseBill' | 'SalesInvoice' | 'DebitNote' | 'CreditNote'
  referenceId: { type: mongoose.Schema.Types.ObjectId },
  referenceNumber: { type: String },

  quantity: { type: Number, required: true },   // Positive = in, Negative = out
  unitCost: { type: Number, default: 0 },
  totalCost: { type: Number, default: 0 },

  // Stock snapshot after this movement
  stockBefore: { type: Number },
  stockAfter: { type: Number },
  avgCostAfter: { type: Number },

  batchNumber: { type: String },
  notes: { type: String },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: true });

stockMovementSchema.index({ companyId: 1, itemId: 1, createdAt: -1 });
stockMovementSchema.index({ companyId: 1, movementType: 1 });
stockMovementSchema.index({ referenceId: 1 });

const Inventory = mongoose.model('Inventory', inventorySchema);
const StockMovement = mongoose.model('StockMovement', stockMovementSchema);

module.exports = { Inventory, StockMovement };
