const ExcelJS   = require('exceljs');
const SalesInvoice = require('../sales/salesInvoice.model');
const PurchaseBill = require('../purchase/purchaseBill.model');
const { INVOICE_TYPES } = require('../../config/constants');
const mongoose = require('mongoose');

// ─── Excel: Sales Register ────────────────────────────────────────────────────
const generateSalesRegisterExcel = async (companyId, { startDate, endDate }) => {
  const filter = {
    companyId: mongoose.Types.ObjectId(companyId),
    isVoid: false,
    invoiceType: INVOICE_TYPES.TAX_INVOICE,
  };
  if (startDate || endDate) {
    filter.invoiceDate = {};
    if (startDate) filter.invoiceDate.$gte = new Date(startDate);
    if (endDate)   filter.invoiceDate.$lte = new Date(endDate);
  }

  const invoices = await SalesInvoice.find(filter)
    .sort({ invoiceDate: 1 })
    .populate('customerId', 'name gstin')
    .lean();

  const workbook  = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Sales Register');

  worksheet.columns = [
    { header: 'Invoice No',       key: 'invoiceNumber',   width: 18 },
    { header: 'Date',             key: 'invoiceDate',     width: 14 },
    { header: 'Customer Name',    key: 'customerName',    width: 30 },
    { header: 'Customer GSTIN',   key: 'customerGSTIN',   width: 18 },
    { header: 'Place of Supply',  key: 'placeOfSupply',   width: 16 },
    { header: 'Taxable Value',    key: 'totalTaxableValue', width: 15 },
    { header: 'CGST',             key: 'totalCGST',       width: 12 },
    { header: 'SGST',             key: 'totalSGST',       width: 12 },
    { header: 'IGST',             key: 'totalIGST',       width: 12 },
    { header: 'Total Tax',        key: 'totalTax',        width: 12 },
    { header: 'Grand Total',      key: 'grandTotal',      width: 14 },
    { header: 'Status',           key: 'status',          width: 12 },
  ];

  // Style header row
  worksheet.getRow(1).font = { bold: true };
  worksheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E79' } };
  worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };

  invoices.forEach(inv => {
    worksheet.addRow({
      invoiceNumber:     inv.invoiceNumber,
      invoiceDate:       new Date(inv.invoiceDate).toLocaleDateString('en-IN'),
      customerName:      inv.customerName,
      customerGSTIN:     inv.customerGSTIN || '',
      placeOfSupply:     inv.placeOfSupply || '',
      totalTaxableValue: inv.totalTaxableValue,
      totalCGST:         inv.totalCGST,
      totalSGST:         inv.totalSGST,
      totalIGST:         inv.totalIGST,
      totalTax:          inv.totalTax,
      grandTotal:        inv.grandTotal,
      status:            inv.status,
    });
  });

  // Totals row
  const lastRow = worksheet.lastRow?.number || 1;
  const totalsRow = worksheet.addRow({
    invoiceNumber: 'TOTAL',
    totalTaxableValue: { formula: `SUM(F2:F${lastRow})` },
    totalCGST:         { formula: `SUM(G2:G${lastRow})` },
    totalSGST:         { formula: `SUM(H2:H${lastRow})` },
    totalIGST:         { formula: `SUM(I2:I${lastRow})` },
    totalTax:          { formula: `SUM(J2:J${lastRow})` },
    grandTotal:        { formula: `SUM(K2:K${lastRow})` },
  });
  totalsRow.font = { bold: true };
  totalsRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE699' } };

  return workbook.xlsx.writeBuffer();
};

// ─── Excel: Purchase Register ─────────────────────────────────────────────────
const generatePurchaseRegisterExcel = async (companyId, { startDate, endDate }) => {
  const filter = { companyId: mongoose.Types.ObjectId(companyId), isVoid: false };
  if (startDate || endDate) {
    filter.billDate = {};
    if (startDate) filter.billDate.$gte = new Date(startDate);
    if (endDate)   filter.billDate.$lte = new Date(endDate);
  }

  const bills = await PurchaseBill.find(filter).sort({ billDate: 1 }).populate('vendorId', 'name gstin').lean();

  const workbook  = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Purchase Register');

  worksheet.columns = [
    { header: 'Bill No (Internal)', key: 'billNumber',       width: 18 },
    { header: 'Vendor Bill No',     key: 'vendorBillNumber', width: 18 },
    { header: 'Bill Date',          key: 'billDate',         width: 14 },
    { header: 'Vendor Name',        key: 'vendorName',       width: 30 },
    { header: 'Vendor GSTIN',       key: 'vendorGSTIN',      width: 18 },
    { header: 'Taxable Value',      key: 'totalTaxableValue',width: 15 },
    { header: 'CGST',               key: 'totalCGST',        width: 12 },
    { header: 'SGST',               key: 'totalSGST',        width: 12 },
    { header: 'IGST',               key: 'totalIGST',        width: 12 },
    { header: 'Grand Total',        key: 'grandTotal',       width: 14 },
    { header: 'ITC Amount',         key: 'totalITC',         width: 12 },
    { header: 'Status',             key: 'status',           width: 12 },
  ];

  worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  worksheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E79' } };

  bills.forEach(bill => {
    worksheet.addRow({
      billNumber:        bill.billNumber,
      vendorBillNumber:  bill.vendorBillNumber || '',
      billDate:          new Date(bill.billDate).toLocaleDateString('en-IN'),
      vendorName:        bill.vendorName,
      vendorGSTIN:       bill.vendorGSTIN || '',
      totalTaxableValue: bill.totalTaxableValue,
      totalCGST:         bill.totalCGST,
      totalSGST:         bill.totalSGST,
      totalIGST:         bill.totalIGST,
      grandTotal:        bill.grandTotal,
      totalITC:          bill.totalITC || 0,
      status:            bill.status,
    });
  });

  return workbook.xlsx.writeBuffer();
};

// ─── GSTR-1 JSON Export ───────────────────────────────────────────────────────
const generateGSTR1JSON = async (companyId, { startDate, endDate }) => {
  const invoices = await SalesInvoice.find({
    companyId: mongoose.Types.ObjectId(companyId),
    isVoid: false,
    invoiceType: INVOICE_TYPES.TAX_INVOICE,
    invoiceDate: { $gte: new Date(startDate), $lte: new Date(endDate) },
  }).lean();

  // B2B invoices (GST-registered customers)
  const b2b = invoices
    .filter(inv => inv.customerGSTIN)
    .map(inv => ({
      ctin: inv.customerGSTIN,
      inv: [{
        inum: inv.invoiceNumber,
        idt:  new Date(inv.invoiceDate).toLocaleDateString('en-IN', { day: '2-digit', month: '2-digit', year: 'numeric' }),
        val:  inv.grandTotal,
        pos:  inv.placeOfSupply,
        rchrg: inv.isRCM ? 'Y' : 'N',
        itms: inv.lineItems?.map(item => ({
          num:  1,
          itm_det: {
            txval: item.taxableValue,
            rt:    item.gstRate,
            csamt: item.cess || 0,
            camt:  item.cgst,
            samt:  item.sgst,
            iamt:  item.igst,
          },
        })) || [],
      }],
    }));

  // B2C invoices (unregistered customers)
  const b2cInvoices = invoices.filter(inv => !inv.customerGSTIN);

  return JSON.stringify({
    version: '1.1',
    gstin:   '',       // Filled by caller
    fp:      new Date(startDate).toLocaleDateString('en-IN', { month: '2-digit', year: 'numeric' }).replace('/', ''),
    b2b,
    b2cs: b2cInvoices.map(inv => ({
      pos:  inv.placeOfSupply,
      typ:  'OE',
      txval: inv.totalTaxableValue,
      rt:   18,
      iamt: inv.totalIGST,
      csamt: 0,
    })),
  }, null, 2);
};

module.exports = {
  generateSalesRegisterExcel,
  generatePurchaseRegisterExcel,
  generateGSTR1JSON,
};
