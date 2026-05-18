const puppeteer = require('puppeteer');

/**
 * Compile sales invoice data into a stunning, print-ready HTML and convert it to a PDF buffer using Puppeteer
 * @param {Object} invoice - The sales invoice document
 * @param {Object} company - The company profile document
 * @param {Object} customer - The customer profile document
 * @returns {Promise<Buffer>} - Resolves to a PDF buffer
 */
const generateInvoicePDF = async (invoice, company, customer) => {
  // Address formatter helper
  const formatAddress = (addr) => {
    if (!addr) return '';
    return [
      addr.line1,
      addr.line2,
      addr.city ? `${addr.city}, ${addr.state || ''} ${addr.pinCode || ''}` : '',
      addr.country || 'India'
    ].filter(Boolean).join('<br/>');
  };

  const companyAddressHtml = formatAddress(company.registeredAddress);
  const billingAddressHtml = formatAddress(invoice.billingAddress);
  const shippingAddressHtml = formatAddress(invoice.shippingAddress);

  // Line items rows generator
  const lineItemsHtml = invoice.lineItems.map((item, index) => {
    return `
      <tr>
        <td style="text-align: center; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">${index + 1}</td>
        <td style="border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">
          <div style="font-weight: bold; color: #1e293b;">${item.itemName}</div>
          ${item.description ? `<div style="font-size: 10px; color: #64748b; margin-top: 2px;">${item.description}</div>` : ''}
        </td>
        <td style="text-align: center; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">${item.hsnCode || item.sacCode || '-'}</td>
        <td style="text-align: right; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">${item.quantity} ${item.unit || 'pcs'}</td>
        <td style="text-align: right; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">₹${item.unitPrice.toFixed(2)}</td>
        <td style="text-align: right; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">${item.discountPercent > 0 ? `${item.discountPercent}%` : '-'}</td>
        <td style="text-align: right; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">${item.gstRate}%</td>
        <td style="text-align: right; font-weight: bold; color: #0f172a; border-bottom: 1px solid #e2e8f0; padding: 10px 8px; vertical-align: top;">₹${item.lineTotal.toFixed(2)}</td>
      </tr>
    `;
  }).join('');

  // Extract the primary or first bank account
  const bank = company.bankAccounts?.find(b => b.isDefault) || company.bankAccounts?.[0] || {};
  const bankHtml = bank.bankName ? `
    <div style="margin-top: 20px; padding: 15px; border: 1px solid #e2e8f0; border-radius: 6px; background-color: #f8fafc; font-size: 11px; max-width: 400px;">
      <h3 style="margin-top: 0; margin-bottom: 8px; font-size: 12px; color: #334155; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px;">Bank Details</h3>
      <table style="width: 100%; border-collapse: collapse; font-size: 11px; color: #475569;">
        <tr>
          <td style="padding: 2px 0; border: none; font-weight: bold; width: 120px;">Bank Name:</td>
          <td style="padding: 2px 0; border: none;">${bank.bankName}</td>
        </tr>
        <tr>
          <td style="padding: 2px 0; border: none; font-weight: bold;">Account Holder:</td>
          <td style="padding: 2px 0; border: none;">${bank.accountHolderName || company.legalName}</td>
        </tr>
        <tr>
          <td style="padding: 2px 0; border: none; font-weight: bold;">Account Number:</td>
          <td style="padding: 2px 0; border: none; font-family: monospace;">${bank.accountNumber}</td>
        </tr>
        <tr>
          <td style="padding: 2px 0; border: none; font-weight: bold;">IFSC Code:</td>
          <td style="padding: 2px 0; border: none; font-family: monospace;">${bank.ifscCode}</td>
        </tr>
        ${bank.upiId ? `
        <tr>
          <td style="padding: 2px 0; border: none; font-weight: bold;">UPI ID:</td>
          <td style="padding: 2px 0; border: none; font-family: monospace;">${bank.upiId}</td>
        </tr>` : ''}
      </table>
    </div>
  ` : '';

  // Main HTML template compilation
  const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Invoice - ${invoice.invoiceNumber}</title>
  <style>
    body {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      color: #334155;
      font-size: 12px;
      line-height: 1.5;
      margin: 0;
      padding: 30px;
      box-sizing: border-box;
      background-color: #ffffff;
    }
    .header-container {
      display: flex;
      justify-content: space-between;
      border-bottom: 2px solid #0f172a;
      padding-bottom: 20px;
      margin-bottom: 25px;
    }
    .company-logo-section {
      max-width: 60%;
    }
    .company-name {
      font-size: 20px;
      font-weight: bold;
      color: #0f172a;
      margin: 0 0 5px 0;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .company-details {
      font-size: 11px;
      color: #64748b;
      line-height: 1.4;
    }
    .invoice-title-section {
      text-align: right;
    }
    .invoice-title {
      font-size: 26px;
      font-weight: 800;
      color: #0f172a;
      margin: 0 0 5px 0;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .invoice-meta-table {
      border-collapse: collapse;
      margin-top: 10px;
      font-size: 11px;
    }
    .invoice-meta-table td {
      padding: 3px 0 3px 15px;
      border: none;
      text-align: right;
    }
    .addresses-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 30px;
      margin-bottom: 30px;
    }
    .address-box {
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      padding: 15px;
      background-color: #fafbfc;
      min-height: 100px;
    }
    .address-title {
      font-size: 11px;
      font-weight: bold;
      color: #64748b;
      text-transform: uppercase;
      margin-bottom: 8px;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 4px;
      letter-spacing: 0.5px;
    }
    .address-content {
      font-size: 12px;
      color: #334155;
      line-height: 1.4;
    }
    .items-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 30px;
      font-size: 11px;
    }
    .items-table th {
      background-color: #0f172a;
      color: #ffffff;
      font-weight: bold;
      text-align: left;
      padding: 10px 8px;
      text-transform: uppercase;
      font-size: 10px;
      letter-spacing: 0.5px;
    }
    .totals-section {
      display: flex;
      justify-content: space-between;
      margin-top: 20px;
    }
    .totals-table {
      width: 320px;
      border-collapse: collapse;
      font-size: 11px;
    }
    .totals-table td {
      padding: 6px 8px;
      border-bottom: 1px solid #f1f5f9;
    }
    .totals-table tr.grand-total-row {
      background-color: #f8fafc;
      font-size: 13px;
      font-weight: bold;
      color: #0f172a;
      border-top: 1px solid #cbd5e1;
      border-bottom: 2px solid #0f172a;
    }
    .amount-words {
      margin-top: 15px;
      padding: 10px;
      border-left: 3px solid #cbd5e1;
      background-color: #f8fafc;
      font-style: italic;
      font-size: 11px;
      color: #475569;
    }
    .footer-section {
      margin-top: 50px;
      border-top: 1px solid #e2e8f0;
      padding-top: 15px;
      font-size: 10px;
      color: #94a3b8;
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
    }
    .signature-box {
      text-align: center;
      width: 180px;
    }
    .signature-line {
      border-top: 1px dashed #94a3b8;
      margin-top: 40px;
      padding-top: 5px;
      font-weight: bold;
      color: #475569;
    }
  </style>
</head>
<body>

  <div class="header-container">
    <div class="company-logo-section">
      <div class="company-name">${company.tradeName || company.legalName}</div>
      <div class="company-details">
        <strong>${company.legalName}</strong><br/>
        ${companyAddressHtml}<br/>
        Email: ${company.email} | Mobile: ${company.mobile}<br/>
        ${company.gstin ? `<strong>GSTIN:</strong> ${company.gstin} | ` : ''}<strong>PAN:</strong> ${company.pan}
      </div>
    </div>
    <div class="invoice-title-section">
      <div class="invoice-title">${invoice.invoiceType === 'proforma' ? 'Proforma Invoice' : 'Tax Invoice'}</div>
      <table class="invoice-meta-table" style="float: right;">
        <tr>
          <td><strong>Invoice No:</strong></td>
          <td style="color: #0f172a; font-weight: bold; font-size: 12px;">${invoice.invoiceNumber}</td>
        </tr>
        <tr>
          <td><strong>Date:</strong></td>
          <td>${new Date(invoice.invoiceDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
        </tr>
        <tr>
          <td><strong>Due Date:</strong></td>
          <td>${invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : '-'}</td>
        </tr>
        ${invoice.customerPONumber ? `
        <tr>
          <td><strong>PO Number:</strong></td>
          <td>${invoice.customerPONumber}</td>
        </tr>` : ''}
      </table>
    </div>
  </div>

  <div class="addresses-grid">
    <div class="address-box">
      <div class="address-title">Billed To</div>
      <div class="address-content">
        <strong>${invoice.customerName || customer.name}</strong><br/>
        ${billingAddressHtml}<br/>
        ${invoice.customerGSTIN ? `<strong>GSTIN:</strong> ${invoice.customerGSTIN}` : customer.gstin ? `<strong>GSTIN:</strong> ${customer.gstin}` : ''}
      </div>
    </div>
    <div class="address-box">
      <div class="address-title">Shipped To</div>
      <div class="address-content">
        <strong>${invoice.customerName || customer.name}</strong><br/>
        ${shippingAddressHtml || billingAddressHtml}<br/>
      </div>
    </div>
  </div>

  <table class="items-table">
    <thead>
      <tr>
        <th style="width: 5%; text-align: center;">#</th>
        <th style="width: 45%;">Item / Description</th>
        <th style="width: 10%; text-align: center;">HSN/SAC</th>
        <th style="width: 10%; text-align: right;">Qty</th>
        <th style="width: 10%; text-align: right;">Rate</th>
        <th style="width: 8%; text-align: right;">Discount</th>
        <th style="width: 7%; text-align: right;">GST</th>
        <th style="width: 12%; text-align: right;">Amount</th>
      </tr>
    </thead>
    <tbody>
      ${lineItemsHtml}
    </tbody>
  </table>

  <div class="totals-section">
    <div>
      ${bankHtml}
      ${invoice.notes ? `
        <div style="margin-top: 15px; max-width: 400px; font-size: 11px;">
          <strong>Notes:</strong><br/>
          <span style="color: #64748b;">${invoice.notes}</span>
        </div>` : ''}
      ${invoice.termsAndConditions ? `
        <div style="margin-top: 10px; max-width: 400px; font-size: 11px;">
          <strong>Terms & Conditions:</strong><br/>
          <span style="color: #64748b;">${invoice.termsAndConditions}</span>
        </div>` : ''}
    </div>
    
    <div>
      <table class="totals-table">
        <tr>
          <td>Sub Total:</td>
          <td style="text-align: right;">₹${invoice.subTotal.toFixed(2)}</td>
        </tr>
        ${invoice.totalDiscount > 0 ? `
        <tr>
          <td>Discount:</td>
          <td style="text-align: right; color: #dc2626;">-₹${invoice.totalDiscount.toFixed(2)}</td>
        </tr>` : ''}
        ${invoice.totalCGST > 0 ? `
        <tr>
          <td>CGST:</td>
          <td style="text-align: right;">₹${invoice.totalCGST.toFixed(2)}</td>
        </tr>` : ''}
        ${invoice.totalSGST > 0 ? `
        <tr>
          <td>SGST:</td>
          <td style="text-align: right;">₹${invoice.totalSGST.toFixed(2)}</td>
        </tr>` : ''}
        ${invoice.totalIGST > 0 ? `
        <tr>
          <td>IGST:</td>
          <td style="text-align: right;">₹${invoice.totalIGST.toFixed(2)}</td>
        </tr>` : ''}
        ${invoice.roundOff !== 0 ? `
        <tr>
          <td>Round Off:</td>
          <td style="text-align: right;">₹${invoice.roundOff.toFixed(2)}</td>
        </tr>` : ''}
        <tr class="grand-total-row">
          <td>Grand Total:</td>
          <td style="text-align: right;">₹${invoice.grandTotal.toFixed(2)}</td>
        </tr>
      </table>
      ${invoice.amountInWords ? `
      <div class="amount-words">
        <strong>Amount in words:</strong><br/>
        ${invoice.amountInWords}
      </div>` : ''}
    </div>
  </div>

  <div class="footer-section">
    <div>
      Generated electronically via BillPro Software.
    </div>
    <div class="signature-box">
      <div style="font-size: 11px; color: #475569; font-weight: bold;">For ${company.tradeName || company.legalName}</div>
      <div class="signature-line">Authorized Signatory</div>
    </div>
  </div>

</body>
</html>
  `;

  // Launch Puppeteer headless browser
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
    
    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20px',
        bottom: '20px',
        left: '20px',
        right: '20px'
      }
    });
    return pdfBuffer;
  } finally {
    await browser.close();
  }
};

module.exports = {
  generateInvoicePDF,
};
