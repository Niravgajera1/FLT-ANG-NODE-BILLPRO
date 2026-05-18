const SalesInvoice = require('./salesInvoice.model');
const Customer    = require('../customers/customer.model');
const Item        = require('../items/item.model');
const { Inventory, StockMovement } = require('../inventory/inventory.model');
const Company     = require('../company/company.model');
const { calculateLineItemGST, calculateBillTotals, amountToWords, getSupplyType } = require('../../utils/gstCalculator');
const { generateBillNumber } = require('../../utils/billNumberGenerator');
const { createAuditLog } = require('../../middleware/auditLog');
const { INVOICE_TYPES, BILL_STATUS, SUPPLY_TYPES } = require('../../config/constants');
const mongoose = require('mongoose');

const processLineItems = (lineItems, supplyType, gstType) => {
  return lineItems.map(item => {
    const calc = calculateLineItemGST({
      quantity:        item.quantity,
      unitPrice:       item.unitPrice,
      discountPercent: item.discountPercent || 0,
      discountFlat:    item.discountFlat || 0,
      gstRate:         item.gstRate,
      cessRate:        item.cessRate || 0,
      supplyType,
      gstType,
    });
    return { ...item, ...calc };
  });
};

const updateInventoryOnSale = async (companyId, branchId, lineItems, referenceId, referenceNumber, userId, session) => {
  for (const item of lineItems) {
    if (!item.itemId) continue;
    const itemDoc = await Item.findById(item.itemId).session(session);
    if (!itemDoc || !itemDoc.trackInventory) continue;

    const inventoryQuery = { companyId, itemId: item.itemId, branchId: branchId || null };
    const inventory = await Inventory.findOne(inventoryQuery).session(session);
    if (!inventory) continue;

    const stockBefore = inventory.currentStock;
    const newStock    = stockBefore - item.quantity;

    if (newStock < 0) {
      // Allow negative stock (can be configured as strict/lenient)
      // throw new Error(`Insufficient stock for item: ${item.itemName}`);
    }

    inventory.currentStock = newStock;
    inventory.totalValue   = Math.max(0, newStock * inventory.avgCost);
    inventory.isLowStock   = newStock <= (inventory.reorderLevel || 0);
    await inventory.save({ session });

    await StockMovement.create([{
      companyId, itemId: item.itemId, branchId: branchId || null,
      movementType: 'sale',
      referenceType: 'SalesInvoice', referenceId, referenceNumber,
      quantity:  -item.quantity,  // Negative for outgoing
      unitCost:   inventory.avgCost,
      totalCost:  item.quantity * inventory.avgCost,
      stockBefore, stockAfter: newStock,
      avgCostAfter: inventory.avgCost,
      createdBy: userId,
    }], { session });
  }
};

// ─── Create Invoice ───────────────────────────────────────────────────────────
const createSalesInvoice = async (companyId, userId, data) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const company  = await Company.findById(companyId).session(session);
    if (!company) throw Object.assign(new Error('Company not found'), { statusCode: 404 });

    const customer = await Customer.findOne({ _id: data.customerId, companyId }).session(session);
    if (!customer) throw Object.assign(new Error('Customer not found'), { statusCode: 404 });

    // Determine supply type
    const isExport = data.invoiceType === INVOICE_TYPES.EXPORT_INVOICE || customer.customerType === 'export';
    const defaultAddress = customer.addresses?.find(a => a.isDefault) || customer.addresses?.[0];
    const customerStateCode = defaultAddress?.stateCode || data.placeOfSupply;
    const supplyType = getSupplyType(company.registeredAddress?.stateCode, customerStateCode, isExport);

    const processedItems = processLineItems(data.lineItems, supplyType, company.gstType);
    const totals = calculateBillTotals(processedItems);

    const invoiceType = data.invoiceType || INVOICE_TYPES.TAX_INVOICE;
    const prefix = invoiceType === INVOICE_TYPES.PROFORMA ? 'QT' :
                   invoiceType === INVOICE_TYPES.DELIVERY_CHALLAN ? 'DC' : 'INV';

    const invoiceNumber = await generateBillNumber(
      companyId, prefix, company.fyStartMonth, company.invoiceSettings?.prefix
    );

    const invoice = new SalesInvoice({
      companyId,
      branchId:    data.branchId,
      createdBy:   userId,
      salespersonId: data.salespersonId,
      invoiceNumber,
      invoiceType,
      customerPONumber: data.customerPONumber,
      customerId:  customer._id,
      customerName:customer.name,
      customerGSTIN: customer.gstin,
      billingAddress:  data.billingAddress  || defaultAddress,
      shippingAddress: data.shippingAddress || defaultAddress,
      invoiceDate: data.invoiceDate || new Date(),
      dueDate:     data.dueDate,
      supplyType,
      placeOfSupply: data.placeOfSupply || customerStateCode,
      dispatchFrom:  data.dispatchFrom,
      isRCM:   data.isRCM || false,
      isExport,
      exportType:  data.exportType,
      lineItems:   processedItems,
      ...totals,
      amountInWords: amountToWords(totals.payableAmount),
      paymentTerms: data.paymentTerms || customer.paymentTerms,
      termsAndConditions: data.termsAndConditions || company.invoiceSettings?.defaultTerms,
      notes:       data.notes || company.invoiceSettings?.defaultNotes,
      // Proforma-specific
      validUntil:      invoiceType === INVOICE_TYPES.PROFORMA ? data.validUntil : undefined,
      quotationStatus: invoiceType === INVOICE_TYPES.PROFORMA ? 'pending' : undefined,
    });

    await invoice.save({ session });

    // Decrement inventory (skip for proforma & delivery challan)
    if (![INVOICE_TYPES.PROFORMA, INVOICE_TYPES.DELIVERY_CHALLAN].includes(invoiceType)) {
      await updateInventoryOnSale(companyId, data.branchId, processedItems, invoice._id, invoiceNumber, userId, session);
    }

    await session.commitTransaction();
    await createAuditLog({ userId: userId.toString(), companyId: companyId.toString(), action: 'CREATE', module: 'sales', recordId: invoice._id.toString() });
    return invoice;

  } catch (err) {
    await session.abortTransaction();
    throw err;
  } finally {
    session.endSession();
  }
};

// ─── Convert Proforma to Tax Invoice ─────────────────────────────────────────
const convertProformaToInvoice = async (companyId, proformaId, userId) => {
  const proforma = await SalesInvoice.findOne({ _id: proformaId, companyId, invoiceType: INVOICE_TYPES.PROFORMA });
  if (!proforma) throw Object.assign(new Error('Proforma not found'), { statusCode: 404 });
  if (proforma.convertedToInvoiceId) throw Object.assign(new Error('Already converted to invoice'), { statusCode: 400 });

  const invoiceData = proforma.toObject();
  delete invoiceData._id;
  invoiceData.invoiceType = INVOICE_TYPES.TAX_INVOICE;
  invoiceData.invoiceDate = new Date();

  const invoice = await createSalesInvoice(companyId, userId, {
    ...invoiceData,
    customerId: proforma.customerId,
  });

  proforma.convertedToInvoiceId = invoice._id;
  proforma.quotationStatus = 'accepted';
  await proforma.save();

  return invoice;
};

// ─── List Invoices ────────────────────────────────────────────────────────────
const getSalesInvoices = async (companyId, query = {}) => {
  const {
    page = 1, limit = 20, status, customerId, invoiceType,
    startDate, endDate, search, sortBy = 'invoiceDate', sortOrder = -1,
    salespersonId,
  } = query;

  const filter = { companyId, isVoid: { $ne: true } };
  if (status)      filter.status      = status;
  if (customerId)  filter.customerId  = customerId;
  if (invoiceType) filter.invoiceType = invoiceType;
  if (salespersonId) filter.salespersonId = salespersonId;
  if (startDate || endDate) {
    filter.invoiceDate = {};
    if (startDate) filter.invoiceDate.$gte = new Date(startDate);
    if (endDate)   filter.invoiceDate.$lte = new Date(endDate);
  }
  if (search) {
    filter.$or = [
      { invoiceNumber:  { $regex: search, $options: 'i' } },
      { customerName:   { $regex: search, $options: 'i' } },
    ];
  }

  const [invoices, total] = await Promise.all([
    SalesInvoice.find(filter)
      .sort({ [sortBy]: sortOrder })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .populate('customerId', 'name gstin mobile email')
      .lean(),
    SalesInvoice.countDocuments(filter),
  ]);

  return { invoices, total, page: parseInt(page), limit: parseInt(limit) };
};

const getSalesInvoiceById = async (companyId, invoiceId) => {
  const invoice = await SalesInvoice.findOne({ _id: invoiceId, companyId })
    .populate('customerId')
    .populate('createdBy', 'fullName email')
    .populate('salespersonId', 'fullName');
  if (!invoice) throw Object.assign(new Error('Invoice not found'), { statusCode: 404 });
  return invoice;
};

const voidSalesInvoice = async (companyId, invoiceId, userId, reason) => {
  const invoice = await SalesInvoice.findOne({ _id: invoiceId, companyId });
  if (!invoice) throw Object.assign(new Error('Invoice not found'), { statusCode: 404 });
  if (invoice.isVoid) throw Object.assign(new Error('Invoice already voided'), { statusCode: 400 });
  if (invoice.status === BILL_STATUS.PAID) throw Object.assign(new Error('Cannot void a paid invoice'), { statusCode: 400 });

  invoice.isVoid    = true;
  invoice.voidReason= reason;
  invoice.status    = BILL_STATUS.VOID;
  await invoice.save();

  await createAuditLog({ userId: userId.toString(), companyId: companyId.toString(), action: 'DELETE', module: 'sales', recordId: invoiceId });
  return { message: 'Invoice voided successfully' };
};

/**
 * Customer receivables aging report
 * Buckets: 0-30, 31-60, 61-90, 90+ days
 */
const getReceivablesAging = async (companyId, asOfDate = new Date()) => {
  const asOf = new Date(asOfDate);
  return SalesInvoice.aggregate([
    {
      $match: {
        companyId: mongoose.Types.ObjectId(companyId),
        isVoid: false,
        balanceDue: { $gt: 0 },
        invoiceType: INVOICE_TYPES.TAX_INVOICE,
      },
    },
    {
      $addFields: {
        daysOverdue: {
          $divide: [{ $subtract: [asOf, '$dueDate'] }, 1000 * 60 * 60 * 24],
        },
      },
    },
    {
      $group: {
        _id: '$customerId',
        customerName: { $first: '$customerName' },
        current:  { $sum: { $cond: [{ $lte: ['$daysOverdue', 0]  }, '$balanceDue', 0] } },
        days30:   { $sum: { $cond: [{ $and: [{ $gt: ['$daysOverdue', 0] }, { $lte: ['$daysOverdue', 30] }]  }, '$balanceDue', 0] } },
        days60:   { $sum: { $cond: [{ $and: [{ $gt: ['$daysOverdue', 30] }, { $lte: ['$daysOverdue', 60] }] }, '$balanceDue', 0] } },
        days90:   { $sum: { $cond: [{ $and: [{ $gt: ['$daysOverdue', 60] }, { $lte: ['$daysOverdue', 90] }] }, '$balanceDue', 0] } },
        above90:  { $sum: { $cond: [{ $gt: ['$daysOverdue', 90] }, '$balanceDue', 0] } },
        total:    { $sum: '$balanceDue' },
      },
    },
    { $sort: { total: -1 } },
  ]);
};

module.exports = {
  createSalesInvoice,
  getSalesInvoices,
  getSalesInvoiceById,
  voidSalesInvoice,
  convertProformaToInvoice,
  getReceivablesAging,
};
