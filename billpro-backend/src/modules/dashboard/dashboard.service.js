const SalesInvoice = require('../sales/salesInvoice.model');
const PurchaseBill = require('../purchase/purchaseBill.model');
const Customer = require('../customers/customer.model');
const Vendor = require('../vendors/vendor.model');
const { Inventory } = require('../inventory/inventory.model');
const Item = require('../items/item.model');
const { INVOICE_TYPES, BILL_STATUS } = require('../../config/constants');
const mongoose = require('mongoose');
const dayjs = require('dayjs');

const toObjId = (id) => new mongoose.Types.ObjectId(id);

/**
 * Get date range for current and previous month
 */
const getMonthRange = (offset = 0) => {
  const now = dayjs().subtract(offset, 'month');
  return {
    start: now.startOf('month').toDate(),
    end: now.endOf('month').toDate(),
  };
};

/**
 * Get date range for financial year
 */
const getFYRange = (fyStartMonth = 4) => {
  const now = dayjs();
  const year = now.month() + 1 >= fyStartMonth ? now.year() : now.year() - 1;
  return {
    start: dayjs(`${year}-${String(fyStartMonth).padStart(2, '0')}-01`).startOf('month').toDate(),
    end: dayjs(`${year}-${String(fyStartMonth).padStart(2, '0')}-01`).add(1, 'year').subtract(1, 'day').endOf('day').toDate(),
  };
};

/**
 * Get custom date range and calculate previous period with matching duration
 */
const getCustomRangeAndPrev = (startDate, endDate) => {
  const start = dayjs(startDate).startOf('day').toDate();
  const end = dayjs(endDate).endOf('day').toDate();

  const durationMs = end.getTime() - start.getTime();
  const prevEnd = dayjs(start).subtract(1, 'millisecond').toDate();
  const prevStart = new Date(prevEnd.getTime() - durationMs);

  return {
    curr: { start, end },
    prev: { start: prevStart, end: prevEnd }
  };
};

// ─── KPI Cards ────────────────────────────────────────────────────────────────
const getKPICards = async (companyId, startDate, endDate) => {
  const companyObjId = toObjId(companyId);
  let currRange, prevRange;

  if (startDate && endDate) {
    const ranges = getCustomRangeAndPrev(startDate, endDate);
    currRange = ranges.curr;
    prevRange = ranges.prev;
  } else {
    currRange = getMonthRange(0);
    prevRange = getMonthRange(1);
  }

  const [
    currSales, prevSales,
    currPurchase, prevPurchase,
    totalReceivable, totalPayable,
    overdueReceivable, overduePayable,
    currInvoiceCount, currBillCount,
    inventoryValue,
    activeCustomers, activeVendors,
    overdueInvoices,
  ] = await Promise.all([
    // Current period sales
    SalesInvoice.aggregate([
      { $match: { companyId: companyObjId, invoiceDate: { $gte: currRange.start, $lte: currRange.end }, isVoid: false, invoiceType: INVOICE_TYPES.TAX_INVOICE } },
      { $group: { _id: null, total: { $sum: '$grandTotal' }, profit: { $sum: { $subtract: ['$grandTotal', '$totalTaxableValue'] } } } },
    ]),
    // Previous period sales
    SalesInvoice.aggregate([
      { $match: { companyId: companyObjId, invoiceDate: { $gte: prevRange.start, $lte: prevRange.end }, isVoid: false, invoiceType: INVOICE_TYPES.TAX_INVOICE } },
      { $group: { _id: null, total: { $sum: '$grandTotal' } } },
    ]),
    // Current period purchase
    PurchaseBill.aggregate([
      { $match: { companyId: companyObjId, billDate: { $gte: currRange.start, $lte: currRange.end }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$grandTotal' } } },
    ]),
    // Previous period purchase
    PurchaseBill.aggregate([
      { $match: { companyId: companyObjId, billDate: { $gte: prevRange.start, $lte: prevRange.end }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$grandTotal' } } },
    ]),
    // Total receivable (all unpaid invoices)
    SalesInvoice.aggregate([
      { $match: { companyId: companyObjId, balanceDue: { $gt: 0 }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$balanceDue' } } },
    ]),
    // Total payable (all unpaid bills)
    PurchaseBill.aggregate([
      { $match: { companyId: companyObjId, balanceDue: { $gt: 0 }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$balanceDue' } } },
    ]),
    // Overdue receivables
    SalesInvoice.aggregate([
      { $match: { companyId: companyObjId, balanceDue: { $gt: 0 }, dueDate: { $lt: new Date() }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$balanceDue' }, count: { $sum: 1 } } },
    ]),
    // Overdue payables
    PurchaseBill.aggregate([
      { $match: { companyId: companyObjId, balanceDue: { $gt: 0 }, dueDate: { $lt: new Date() }, isVoid: false } },
      { $group: { _id: null, total: { $sum: '$balanceDue' } } },
    ]),
    // Invoice count this period
    SalesInvoice.countDocuments({ companyId: companyObjId, invoiceDate: { $gte: currRange.start, $lte: currRange.end }, isVoid: false }),
    // Bill count this period
    PurchaseBill.countDocuments({ companyId: companyObjId, billDate: { $gte: currRange.start, $lte: currRange.end }, isVoid: false }),
    // Inventory value
    Inventory.aggregate([
      { $match: { companyId: companyObjId } },
      { $group: { _id: null, total: { $sum: '$totalValue' } } },
    ]),
    // Active customers this period
    SalesInvoice.distinct('customerId', { companyId: companyObjId, isVoid: false, invoiceDate: { $gte: currRange.start, $lte: currRange.end } }),
    // Active vendors this period
    PurchaseBill.distinct('vendorId', { companyId: companyObjId, isVoid: false, billDate: { $gte: currRange.start, $lte: currRange.end } }),
    // Overdue invoices
    SalesInvoice.aggregate([
      { $match: { companyId: companyObjId, balanceDue: { $gt: 0 }, dueDate: { $lt: new Date() }, isVoid: false } },
      { $group: { _id: null, count: { $sum: 1 }, value: { $sum: '$balanceDue' } } },
    ]),
  ]);

  const cs = currSales[0]?.total || 0;
  const ps = prevSales[0]?.total || 0;
  const cp = currPurchase[0]?.total || 0;
  const pp = prevPurchase[0]?.total || 0;
  const pct = (curr, prev) => prev > 0 ? Math.round(((curr - prev) / prev) * 100) : null;

  return {
    totalSales: { value: cs, change: pct(cs, ps), prevValue: ps },
    totalPurchases: { value: cp, change: pct(cp, pp), prevValue: pp },
    grossProfit: { value: cs - cp, change: null },
    netReceivable: { value: totalReceivable[0]?.total || 0, overdue: overdueReceivable[0]?.total || 0 },
    netPayable: { value: totalPayable[0]?.total || 0, overdue: overduePayable[0]?.total || 0 },
    totalInvoices: { value: currInvoiceCount },
    totalBills: { value: currBillCount },
    inventoryValue: { value: inventoryValue[0]?.total || 0 },
    activeCustomers: { value: activeCustomers.length },
    activeVendors: { value: activeVendors.length },
    overdueInvoices: { count: overdueInvoices[0]?.count || 0, value: overdueInvoices[0]?.value || 0 },
    gstPayable: { value: (currSales[0]?.total || 0) * 0.18 }, // Approximate — real calc needs GST breakdown
  };
};

// ─── Monthly Sales Trend ──────────────────────────────────────────────────────
const getMonthlySalesTrend = async (companyId, fyStartMonth = 4, startDate, endDate) => {
  let start, end;
  if (startDate && endDate) {
    start = dayjs(startDate).startOf('day').toDate();
    end = dayjs(endDate).endOf('day').toDate();
  } else {
    const range = getFYRange(fyStartMonth);
    start = range.start;
    end = range.end;
  }

  return SalesInvoice.aggregate([
    {
      $match: {
        companyId: toObjId(companyId),
        invoiceDate: { $gte: start, $lte: end },
        isVoid: false,
        invoiceType: INVOICE_TYPES.TAX_INVOICE,
      },
    },
    {
      $group: {
        _id: { year: { $year: '$invoiceDate' }, month: { $month: '$invoiceDate' } },
        sales: { $sum: '$grandTotal' },
        invoices: { $sum: 1 },
        taxAmount: { $sum: '$totalTax' },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } },
  ]);
};

// ─── Sales vs Purchase (Bar Chart) ───────────────────────────────────────────
const getSalesVsPurchase = async (companyId, fyStartMonth = 4, startDate, endDate) => {
  let start, end;
  if (startDate && endDate) {
    start = dayjs(startDate).startOf('day').toDate();
    end = dayjs(endDate).endOf('day').toDate();
  } else {
    const range = getFYRange(fyStartMonth);
    start = range.start;
    end = range.end;
  }
  const cid = toObjId(companyId);

  const [salesData, purchaseData] = await Promise.all([
    SalesInvoice.aggregate([
      { $match: { companyId: cid, invoiceDate: { $gte: start, $lte: end }, isVoid: false, invoiceType: INVOICE_TYPES.TAX_INVOICE } },
      { $group: { _id: { year: { $year: '$invoiceDate' }, month: { $month: '$invoiceDate' } }, total: { $sum: '$grandTotal' } } },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]),
    PurchaseBill.aggregate([
      { $match: { companyId: cid, billDate: { $gte: start, $lte: end }, isVoid: false } },
      { $group: { _id: { year: { $year: '$billDate' }, month: { $month: '$billDate' } }, total: { $sum: '$grandTotal' } } },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]),
  ]);

  return { salesData, purchaseData };
};

// ─── Top 10 Customers by Revenue ─────────────────────────────────────────────
const getTopCustomers = async (companyId, fyStartMonth = 4, limit = 10, startDate, endDate) => {
  let start, end;
  if (startDate && endDate) {
    start = dayjs(startDate).startOf('day').toDate();
    end = dayjs(endDate).endOf('day').toDate();
  } else {
    const range = getFYRange(fyStartMonth);
    start = range.start;
    end = range.end;
  }

  return SalesInvoice.aggregate([
    {
      $match: {
        companyId: toObjId(companyId),
        invoiceDate: { $gte: start, $lte: end },
        isVoid: false,
        invoiceType: INVOICE_TYPES.TAX_INVOICE,
      },
    },
    {
      $group: {
        _id: '$customerId',
        customerName: { $first: '$customerName' },
        totalRevenue: { $sum: '$grandTotal' },
        invoiceCount: { $sum: 1 },
      },
    },
    { $sort: { totalRevenue: -1 } },
    { $limit: parseInt(limit) },
  ]);
};

// ─── Invoice Status Distribution (Donut) ─────────────────────────────────────
const getInvoiceStatusDistribution = async (companyId, startDate, endDate) => {
  const filter = { companyId: toObjId(companyId), isVoid: false, invoiceType: INVOICE_TYPES.TAX_INVOICE };
  if (startDate || endDate) {
    filter.invoiceDate = {};
    if (startDate) filter.invoiceDate.$gte = new Date(startDate);
    if (endDate) filter.invoiceDate.$lte = new Date(endDate);
  }

  return SalesInvoice.aggregate([
    { $match: filter },
    { $group: { _id: '$status', count: { $sum: 1 }, value: { $sum: '$grandTotal' } } },
  ]);
};

// ─── GST Summary ─────────────────────────────────────────────────────────────
const getGSTSummary = async (companyId, fyStartMonth = 4) => {
  const { start, end } = getFYRange(fyStartMonth);
  return SalesInvoice.aggregate([
    {
      $match: {
        companyId: toObjId(companyId),
        invoiceDate: { $gte: start, $lte: end },
        isVoid: false,
        invoiceType: INVOICE_TYPES.TAX_INVOICE,
      },
    },
    {
      $group: {
        _id: { year: { $year: '$invoiceDate' }, month: { $month: '$invoiceDate' } },
        totalCGST: { $sum: '$totalCGST' },
        totalSGST: { $sum: '$totalSGST' },
        totalIGST: { $sum: '$totalIGST' },
        totalTax: { $sum: '$totalTax' },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } },
  ]);
};

// ─── Recent Sales Invoices ────────────────────────────────────────────────────
const getRecentSalesInvoices = async (companyId, limit = 5, startDate, endDate) => {
  const query = { companyId: toObjId(companyId), isVoid: false };
  if (startDate && endDate) {
    query.invoiceDate = {
      $gte: dayjs(startDate).startOf('day').toDate(),
      $lte: dayjs(endDate).endOf('day').toDate()
    };
  }
  return SalesInvoice.find(query)
    .sort({ invoiceDate: -1, createdAt: -1 })
    .select('invoiceNumber customerName invoiceDate dueDate grandTotal status balanceDue paidAmount')
    .limit(parseInt(limit));
};

// ─── Recent Purchase Bills ─────────────────────────────────────────────────────
const getRecentPurchaseBills = async (companyId, limit = 5, startDate, endDate) => {
  const query = { companyId: toObjId(companyId), isVoid: false };
  if (startDate && endDate) {
    query.billDate = {
      $gte: dayjs(startDate).startOf('day').toDate(),
      $lte: dayjs(endDate).endOf('day').toDate()
    };
  }
  return PurchaseBill.find(query)
    .sort({ billDate: -1, createdAt: -1 })
    .select('billNumber vendorBillNumber vendorName billDate dueDate grandTotal status balanceDue paidAmount')
    .limit(parseInt(limit));
};

// ─── Low Stock Alerts ──────────────────────────────────────────────────────────
const getLowStockAlerts = async (companyId, limit = 5) => {
  return Item.find({
    companyId: toObjId(companyId),
    trackInventory: true,
    isActive: true,
    $expr: { $lte: ['$currentStock', '$reorderLevel'] }
  })
    .select('name itemCode currentStock reorderLevel unit sellingPrice purchasePrice')
    .limit(parseInt(limit));
};

// ─── Top Selling Products ──────────────────────────────────────────────────────
const getTopSellingProducts = async (companyId, fyStartMonth = 4, limit = 5, startDate, endDate) => {
  let start, end;
  if (startDate && endDate) {
    start = dayjs(startDate).startOf('day').toDate();
    end = dayjs(endDate).endOf('day').toDate();
  } else {
    const range = getFYRange(fyStartMonth);
    start = range.start;
    end = range.end;
  }

  return SalesInvoice.aggregate([
    {
      $match: {
        companyId: toObjId(companyId),
        invoiceDate: { $gte: start, $lte: end },
        isVoid: false,
        invoiceType: INVOICE_TYPES.TAX_INVOICE,
      }
    },
    { $unwind: '$lineItems' },
    {
      $group: {
        _id: '$lineItems.itemId',
        name: { $first: '$lineItems.itemName' },
        totalQuantity: { $sum: '$lineItems.quantity' },
        totalRevenue: { $sum: '$lineItems.lineTotal' },
        avgUnitPrice: { $avg: '$lineItems.unitPrice' }
      }
    },
    { $sort: { totalRevenue: -1 } },
    { $limit: parseInt(limit) }
  ]);
};

// ─── Unified Dashboard Summary ───────────────────────────────────────────────
const getDashboardSummary = async (companyId, fyStartMonth = 4, startDate, endDate) => {
  const fyMonth = parseInt(fyStartMonth) || 4;

  const [
    kpis,
    salesTrend,
    salesVsPurchase,
    topCustomers,
    invoiceStatus,
    recentSalesInvoices,
    recentPurchaseBills,
    lowStockAlerts,
    topSellingProducts
  ] = await Promise.all([
    getKPICards(companyId, startDate, endDate),
    getMonthlySalesTrend(companyId, fyMonth, startDate, endDate),
    getSalesVsPurchase(companyId, fyMonth, startDate, endDate),
    getTopCustomers(companyId, fyMonth, 5, startDate, endDate),
    getInvoiceStatusDistribution(companyId, startDate, endDate),
    getRecentSalesInvoices(companyId, 5, startDate, endDate),
    getRecentPurchaseBills(companyId, 5, startDate, endDate),
    getLowStockAlerts(companyId, 5),
    getTopSellingProducts(companyId, fyMonth, 5, startDate, endDate)
  ]);

  return {
    kpis,
    salesTrend,
    salesVsPurchase,
    topCustomers,
    invoiceStatus,
    recentSalesInvoices,
    recentPurchaseBills,
    lowStockAlerts,
    topSellingProducts
  };
};

module.exports = {
  getKPICards,
  getMonthlySalesTrend,
  getSalesVsPurchase,
  getTopCustomers,
  getInvoiceStatusDistribution,
  getGSTSummary,
  getRecentSalesInvoices,
  getRecentPurchaseBills,
  getLowStockAlerts,
  getTopSellingProducts,
  getDashboardSummary,
};
