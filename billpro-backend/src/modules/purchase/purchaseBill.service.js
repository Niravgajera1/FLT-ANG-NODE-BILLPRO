const PurchaseBill = require('./purchaseBill.model');
const Vendor       = require('../vendors/vendor.model');
const Item         = require('../items/item.model');
const { Inventory, StockMovement } = require('../inventory/inventory.model');
const { calculateLineItemGST, calculateBillTotals, amountToWords, getSupplyType } = require('../../utils/gstCalculator');
const { generateBillNumber } = require('../../utils/billNumberGenerator');
const { createAuditLog } = require('../../middleware/auditLog');
const Company = require('../company/company.model');
const mongoose = require('mongoose');
const { BILL_STATUS } = require('../../config/constants');

/**
 * Process line items — calculate GST for each line
 */
const processLineItems = (lineItems, supplyType, gstType) => {
  return lineItems.map(item => {
    const calc = calculateLineItemGST({
      quantity:       item.quantity,
      unitPrice:      item.unitPrice,
      discountPercent:item.discountPercent || 0,
      discountFlat:   item.discountFlat || 0,
      gstRate:        item.gstRate,
      cessRate:       item.cessRate || 0,
      supplyType,
      gstType,
      isRCM:          item.isRCM || false,
    });
    return { ...item, ...calc };
  });
};

/**
 * Update inventory on purchase (increment stock, recalculate WAC)
 */
const updateInventoryOnPurchase = async (companyId, branchId, lineItems, referenceId, referenceNumber, userId, session) => {
  for (const item of lineItems) {
    if (!item.itemId) continue;

    const itemDoc = await Item.findById(item.itemId).session(session);
    if (!itemDoc || !itemDoc.trackInventory) continue;

    const inventoryQuery = { companyId, itemId: item.itemId, branchId: branchId || null };
    let inventory = await Inventory.findOne(inventoryQuery).session(session);

    if (!inventory) {
      inventory = new Inventory({ ...inventoryQuery, currentStock: 0, avgCost: 0 });
    }

    const stockBefore  = inventory.currentStock;
    const totalCostOld = inventory.currentStock * inventory.avgCost;
    const totalCostNew = item.quantity * item.unitPrice;

    // Weighted Average Cost formula
    const newStock  = stockBefore + item.quantity;
    const newAvgCost = newStock > 0 ? (totalCostOld + totalCostNew) / newStock : item.unitPrice;

    inventory.currentStock = newStock;
    inventory.avgCost      = Math.round(newAvgCost * 100) / 100;
    inventory.totalValue   = Math.round(newStock * newAvgCost * 100) / 100;
    inventory.isLowStock   = newStock <= (inventory.reorderLevel || 0);
    await inventory.save({ session });

    // Log movement
    await StockMovement.create([{
      companyId,
      itemId:          item.itemId,
      branchId:        branchId || null,
      movementType:    'purchase',
      referenceType:   'PurchaseBill',
      referenceId,
      referenceNumber,
      quantity:        item.quantity,
      unitCost:        item.unitPrice,
      totalCost:       totalCostNew,
      stockBefore,
      stockAfter:      newStock,
      avgCostAfter:    inventory.avgCost,
      createdBy:       userId,
    }], { session });
  }
};

// ─── CRUD Operations ──────────────────────────────────────────────────────────

const createPurchaseBill = async (companyId, userId, data) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const company = await Company.findById(companyId).session(session);
    if (!company) throw Object.assign(new Error('Company not found'), { statusCode: 404 });

    const vendor = await Vendor.findOne({ _id: data.vendorId, companyId }).session(session);
    if (!vendor) throw Object.assign(new Error('Vendor not found'), { statusCode: 404 });

    // Determine supply type
    const supplyType = getSupplyType(
      company.registeredAddress?.stateCode,
      vendor.registeredAddress?.stateCode || data.placeOfSupply,
    );

    // Process line items with GST calculation
    const processedItems = processLineItems(data.lineItems, supplyType, company.gstType);
    const totals = calculateBillTotals(processedItems);

    // Generate bill number
    const billNumber = await generateBillNumber(
      companyId,
      'PB',
      company.fyStartMonth,
      company.invoiceSettings?.purchasePrefix
    );

    const bill = new PurchaseBill({
      companyId,
      branchId:   data.branchId,
      createdBy:  userId,
      billNumber,
      vendorBillNumber: data.vendorBillNumber,
      poReference: data.poReference,
      vendorId:   vendor._id,
      vendorName: vendor.name,
      vendorGSTIN:vendor.gstin,
      vendorBillDate: data.vendorBillDate,
      billDate:   data.billDate || new Date(),
      dueDate:    data.dueDate,
      supplyType,
      placeOfSupply: data.placeOfSupply,
      isRCM:      data.isRCM || false,
      lineItems:  processedItems,
      ...totals,
      amountInWords: amountToWords(totals.payableAmount),
      paymentTerms:  data.paymentTerms || vendor.paymentTerms,
      narration:  data.narration,
    });

    await bill.save({ session });

    // Update inventory
    await updateInventoryOnPurchase(companyId, data.branchId, processedItems, bill._id, billNumber, userId, session);

    await session.commitTransaction();

    await createAuditLog({
      userId:    userId.toString(),
      companyId: companyId.toString(),
      action:    'CREATE',
      module:    'purchase',
      recordId:  bill._id.toString(),
    });

    return bill;
  } catch (err) {
    await session.abortTransaction();
    throw err;
  } finally {
    session.endSession();
  }
};

const getPurchaseBills = async (companyId, query = {}) => {
  const {
    page = 1, limit = 20, status, vendorId, startDate, endDate,
    search, sortBy = 'billDate', sortOrder = -1,
  } = query;

  const filter = { companyId, isVoid: false };
  if (status)   filter.status   = status;
  if (vendorId) filter.vendorId = vendorId;
  if (startDate || endDate) {
    filter.billDate = {};
    if (startDate) filter.billDate.$gte = new Date(startDate);
    if (endDate)   filter.billDate.$lte = new Date(endDate);
  }
  if (search) {
    filter.$or = [
      { billNumber: { $regex: search, $options: 'i' } },
      { vendorBillNumber: { $regex: search, $options: 'i' } },
      { vendorName: { $regex: search, $options: 'i' } },
    ];
  }

  const [bills, total] = await Promise.all([
    PurchaseBill.find(filter)
      .sort({ [sortBy]: sortOrder })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .populate('vendorId', 'name gstin')
      .lean(),
    PurchaseBill.countDocuments(filter),
  ]);

  return { bills, total, page: parseInt(page), limit: parseInt(limit) };
};

const getPurchaseBillById = async (companyId, billId) => {
  const bill = await PurchaseBill.findOne({ _id: billId, companyId })
    .populate('vendorId')
    .populate('createdBy', 'fullName email');
  if (!bill) throw Object.assign(new Error('Purchase bill not found'), { statusCode: 404 });
  return bill;
};

const updatePurchaseBill = async (companyId, billId, userId, data) => {
  const bill = await PurchaseBill.findOne({ _id: billId, companyId });
  if (!bill) throw Object.assign(new Error('Purchase bill not found'), { statusCode: 404 });
  if (bill.status === BILL_STATUS.PAID) throw Object.assign(new Error('Cannot edit a paid bill'), { statusCode: 400 });
  if (bill.isVoid) throw Object.assign(new Error('Cannot edit a voided bill'), { statusCode: 400 });

  // Recalculate if line items changed
  if (data.lineItems) {
    const company = await Company.findById(companyId);
    const vendor  = await Vendor.findById(bill.vendorId);
    const supplyType = getSupplyType(company.registeredAddress?.stateCode, vendor.registeredAddress?.stateCode);
    const processedItems = processLineItems(data.lineItems, supplyType, company.gstType);
    const totals = calculateBillTotals(processedItems);
    Object.assign(bill, { lineItems: processedItems, ...totals, amountInWords: amountToWords(totals.payableAmount) });
  }

  Object.assign(bill, {
    vendorBillNumber: data.vendorBillNumber ?? bill.vendorBillNumber,
    vendorBillDate:   data.vendorBillDate   ?? bill.vendorBillDate,
    dueDate:          data.dueDate          ?? bill.dueDate,
    narration:        data.narration        ?? bill.narration,
  });

  await bill.save();
  await createAuditLog({ userId: userId.toString(), companyId: companyId.toString(), action: 'UPDATE', module: 'purchase', recordId: billId });
  return bill;
};

const voidPurchaseBill = async (companyId, billId, userId, reason) => {
  const bill = await PurchaseBill.findOne({ _id: billId, companyId });
  if (!bill) throw Object.assign(new Error('Purchase bill not found'), { statusCode: 404 });
  if (bill.isVoid) throw Object.assign(new Error('Bill already voided'), { statusCode: 400 });
  if (bill.status === BILL_STATUS.PAID) throw Object.assign(new Error('Cannot void a paid bill'), { statusCode: 400 });

  bill.isVoid    = true;
  bill.voidReason= reason;
  bill.voidedAt  = new Date();
  bill.voidedBy  = userId;
  bill.status    = BILL_STATUS.VOID;
  await bill.save();

  await createAuditLog({ userId: userId.toString(), companyId: companyId.toString(), action: 'DELETE', module: 'purchase', recordId: billId });
  return { message: 'Bill voided successfully' };
};

/**
 * Vendor outstanding report
 */
const getVendorOutstanding = async (companyId, vendorId) => {
  const match = { companyId: mongoose.Types.ObjectId(companyId), isVoid: false };
  if (vendorId) match.vendorId = mongoose.Types.ObjectId(vendorId);

  return PurchaseBill.aggregate([
    { $match: match },
    {
      $group: {
        _id: '$vendorId',
        totalAmount:  { $sum: '$grandTotal' },
        paidAmount:   { $sum: '$paidAmount' },
        balanceDue:   { $sum: '$balanceDue' },
        billCount:    { $sum: 1 },
        overdueAmount: {
          $sum: { $cond: [{ $and: [{ $lt: ['$dueDate', new Date()] }, { $gt: ['$balanceDue', 0] }] }, '$balanceDue', 0] },
        },
      },
    },
    { $lookup: { from: 'vendors', localField: '_id', foreignField: '_id', as: 'vendor' } },
    { $unwind: '$vendor' },
    { $project: { vendorName: '$vendor.name', vendorGSTIN: '$vendor.gstin', totalAmount: 1, paidAmount: 1, balanceDue: 1, billCount: 1, overdueAmount: 1 } },
    { $sort: { balanceDue: -1 } },
  ]);
};

module.exports = {
  createPurchaseBill,
  getPurchaseBills,
  getPurchaseBillById,
  updatePurchaseBill,
  voidPurchaseBill,
  getVendorOutstanding,
};
