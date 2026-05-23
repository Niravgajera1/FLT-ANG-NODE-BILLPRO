const salesInvoiceService = require('./salesInvoice.service');
const { sendSuccess, sendCreated, sendPaginated } = require('../../utils/responseHelper');

const createSalesInvoice = async (req, res, next) => {
  try {
    const invoice = await salesInvoiceService.createSalesInvoice(req.companyId, req.user.id, req.body);
    return sendCreated(res, invoice, 'Invoice created successfully');
  } catch (err) { next(err); }
};

const getSalesInvoices = async (req, res, next) => {
  try {
    const { invoices, total, page, limit } = await salesInvoiceService.getSalesInvoices(req.companyId, req.query);
    return sendPaginated(res, invoices, { total, page, limit });
  } catch (err) { next(err); }
};

const getSalesInvoiceById = async (req, res, next) => {
  try {
    const invoice = await salesInvoiceService.getSalesInvoiceById(req.companyId, req.params.id);
    return sendSuccess(res, invoice);
  } catch (err) { next(err); }
};

const voidSalesInvoice = async (req, res, next) => {
  try {
    const result = await salesInvoiceService.voidSalesInvoice(req.companyId, req.params.id, req.user.id, req.body.reason);
    return sendSuccess(res, result);
  } catch (err) { next(err); }
};

const convertProformaToInvoice = async (req, res, next) => {
  try {
    const invoice = await salesInvoiceService.convertProformaToInvoice(req.companyId, req.params.id, req.user.id);
    return sendCreated(res, invoice, 'Proforma converted to invoice successfully');
  } catch (err) { next(err); }
};

const getReceivablesAging = async (req, res, next) => {
  try {
    const data = await salesInvoiceService.getReceivablesAging(req.companyId, req.query.asOfDate);
    return sendSuccess(res, data);
  } catch (err) { next(err); }
};

const updateSalesInvoice = async (req, res, next) => {
  try {
    const invoice = await salesInvoiceService.updateSalesInvoice(req.companyId, req.params.id, req.user.id, req.body);
    return sendSuccess(res, invoice, 'Invoice updated successfully');
  } catch (err) { next(err); }
};

const Company = require('../company/company.model');
const SalesInvoice = require('./salesInvoice.model');
const { generateInvoicePDF } = require('../../utils/pdfGenerator');

const downloadSalesInvoicePDF = async (req, res, next) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;

    const invoice = await SalesInvoice.findOne({ _id: id, companyId }).populate('customerId');
    if (!invoice) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({ success: false, message: 'Company not found' });
    }

    const customer = invoice.customerId;
    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer associated with this invoice was not found' });
    }

    const pdfBuffer = await generateInvoicePDF(invoice, company, customer);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="Invoice-${invoice.invoiceNumber}.pdf"`);
    return res.send(pdfBuffer);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createSalesInvoice, getSalesInvoices, getSalesInvoiceById,
  updateSalesInvoice, voidSalesInvoice, convertProformaToInvoice,
  getReceivablesAging, downloadSalesInvoicePDF,
};
