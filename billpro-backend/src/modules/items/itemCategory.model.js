const mongoose = require('mongoose');

const itemCategorySchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  name: { type: String, required: true, trim: true },
  description: { type: String, maxlength: 500 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

// Prevent duplicate category names under the same company
itemCategorySchema.index({ companyId: 1, name: 1 }, { unique: true });

const ItemCategory = mongoose.model('ItemCategory', itemCategorySchema);
module.exports = ItemCategory;
