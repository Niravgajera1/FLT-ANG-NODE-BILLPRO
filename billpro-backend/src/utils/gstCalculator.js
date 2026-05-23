/**
 * BillPro GST Calculation Engine
 * Handles all GST scenarios: intra-state, inter-state, RCM, composition, export
 * All amounts rounded to 2 decimal places as per GST rules
 */

const { SUPPLY_TYPES, GST_TYPES } = require('../config/constants');

/**
 * Determine supply type based on seller and buyer state
 */
const getSupplyType = (sellerStateCode, buyerStateCode, isExport = false) => {
  if (isExport) return SUPPLY_TYPES.EXPORT;
  if (sellerStateCode === buyerStateCode) return SUPPLY_TYPES.INTRA_STATE;
  return SUPPLY_TYPES.INTER_STATE;
};

/**
 * Round to 2 decimal places (banker's rounding not used — GST uses standard rounding)
 */
const round2 = (value) => Math.round(value * 100) / 100;

/**
 * Calculate GST for a single line item
 * @param {Object} params
 * @param {number} params.quantity
 * @param {number} params.unitPrice        - Exclusive of tax
 * @param {number} params.discountPercent  - Discount percentage (0-100)
 * @param {number} params.discountFlat     - Flat discount amount
 * @param {number} params.gstRate          - GST rate percentage (0, 5, 12, 18, 28)
 * @param {number} params.cessRate         - Cess rate (for tobacco, luxury goods etc.)
 * @param {string} params.supplyType       - 'intra_state' | 'inter_state' | 'export'
 * @param {string} params.gstType          - 'regular' | 'composition' | 'unregistered'
 * @param {boolean} params.isRCM           - Reverse Charge Mechanism
 * @returns {Object} Calculated tax breakdown
 */
const calculateLineItemGST = ({
  quantity = 1,
  unitPrice = 0,
  discountPercent = 0,
  discountFlat = 0,
  gstRate = 0,
  cessRate = 0,
  supplyType = SUPPLY_TYPES.INTRA_STATE,
  gstType = GST_TYPES.REGULAR,
  isRCM = false,
}) => {
  const grossValue = round2(quantity * unitPrice);

  // Apply discount (percentage first, then flat on discounted value)
  const discountByPercent = round2(grossValue * discountPercent / 100);
  const totalDiscount = round2(discountByPercent + discountFlat);
  const taxableValue = round2(grossValue - totalDiscount);

  let cgst = 0, sgst = 0, igst = 0, cess = 0;

  // Composition scheme: no input tax credit, simplified rate
  if (gstType === GST_TYPES.COMPOSITION) {
    const compositionRate = 1; // 1% typically — configurable
    const compositionTax = round2(taxableValue * compositionRate / 100);
    return {
      grossValue,
      discountAmount: totalDiscount,
      taxableValue,
      cgst: round2(compositionTax / 2),
      sgst: round2(compositionTax / 2),
      igst: 0,
      cess: 0,
      totalTax: compositionTax,
      lineTotal: round2(taxableValue + compositionTax),
      supplyType,
      gstRate: compositionRate,
      isRCM,
    };
  }

  // Export: zero-rated (no GST charged)
  if (supplyType === SUPPLY_TYPES.EXPORT) {
    return {
      grossValue,
      discountAmount: totalDiscount,
      taxableValue,
      cgst: 0, sgst: 0, igst: 0, cess: 0,
      totalTax: 0,
      lineTotal: taxableValue,
      supplyType,
      gstRate,
      isRCM,
    };
  }

  const taxAmount = round2(taxableValue * gstRate / 100);
  const cessAmount = cessRate > 0 ? round2(taxableValue * cessRate / 100) : 0;

  if (supplyType === SUPPLY_TYPES.INTRA_STATE) {
    cgst = round2(taxAmount / 2);
    sgst = round2(taxAmount - cgst); // Assign remainder to SGST to handle odd paise
  } else {
    igst = taxAmount;
  }

  cess = cessAmount;
  const totalTax = round2(cgst + sgst + igst + cess);

  return {
    grossValue,
    discountAmount: totalDiscount,
    taxableValue,
    cgst,
    sgst,
    igst,
    cess,
    totalTax,
    lineTotal: round2(taxableValue + totalTax),
    supplyType,
    gstRate,
    cessRate,
    isRCM,
  };
};

/**
 * Calculate bill/invoice totals from an array of line items
 * @param {Array} lineItems - Array of calculated line items (output of calculateLineItemGST)
 * @returns {Object} Bill totals summary
 */
const calculateBillTotals = (lineItems) => {
  const totals = lineItems.reduce((acc, item) => {
    acc.subTotal += item.grossValue;
    acc.totalDiscount += item.discountAmount;
    acc.totalTaxableValue += item.taxableValue;
    acc.totalCGST += item.cgst;
    acc.totalSGST += item.sgst;
    acc.totalIGST += item.igst;
    acc.totalCess += item.cess;
    acc.totalTax += item.totalTax;
    acc.grandTotal += item.lineTotal;
    return acc;
  }, {
    subTotal: 0,
    totalDiscount: 0,
    totalTaxableValue: 0,
    totalCGST: 0,
    totalSGST: 0,
    totalIGST: 0,
    totalCess: 0,
    totalTax: 0,
    grandTotal: 0,
  });

  // Round all to 2 decimal places
  Object.keys(totals).forEach(k => { totals[k] = round2(totals[k]); });

  // Round-off calculation (nearest rupee for display)
  const roundedTotal = Math.round(totals.grandTotal);
  totals.roundOff = round2(roundedTotal - totals.grandTotal);
  totals.payableAmount = round2(totals.grandTotal + totals.roundOff);

  return totals;
};

/**
 * GST Tax Rate Breakup — for GSTR filing (group by HSN + GST rate)
 * @param {Array} lineItems - Line items with hsnCode and gstRate
 * @returns {Array} HSN-wise tax summary
 */
const getHSNSummary = (lineItems) => {
  const hsnMap = {};

  lineItems.forEach(item => {
    const key = `${item.hsnCode || 'NA'}_${item.gstRate}`;
    if (!hsnMap[key]) {
      hsnMap[key] = {
        hsnCode: item.hsnCode || 'NA',
        gstRate: item.gstRate,
        taxableValue: 0,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
        totalTax: 0,
      };
    }
    hsnMap[key].taxableValue = round2(hsnMap[key].taxableValue + item.taxableValue);
    hsnMap[key].cgst = round2(hsnMap[key].cgst + item.cgst);
    hsnMap[key].sgst = round2(hsnMap[key].sgst + item.sgst);
    hsnMap[key].igst = round2(hsnMap[key].igst + item.igst);
    hsnMap[key].cess = round2(hsnMap[key].cess + item.cess);
    hsnMap[key].totalTax = round2(hsnMap[key].totalTax + item.totalTax);
  });

  return Object.values(hsnMap);
};

/**
 * Validate GST rate
 */
const isValidGSTRate = (rate) => [0, 5, 12, 18, 28].includes(Number(rate));

/**
 * Validate GSTIN format (15-char alphanumeric)
 * Format: 2-digit state code + 10-char PAN + 1 entity number + Z + 1 checksum
 */
const validateGSTIN = (gstin) => {
  if (!gstin) return false;
  const gstinRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
  return gstinRegex.test(gstin.toUpperCase());
};

/**
 * Validate PAN format
 */
const validatePAN = (pan) => {
  if (!pan) return false;
  return /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(pan.toUpperCase());
};

/**
 * Extract state code from GSTIN
 */
const getStateCodeFromGSTIN = (gstin) => {
  if (!validateGSTIN(gstin)) return null;
  return gstin.substring(0, 2);
};

/**
 * Convert amount to words (Indian numbering system)
 */
const amountToWords = (amount) => {
  const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'];
  const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  const numToWords = (n) => {
    if (n < 20) return ones[n];
    if (n < 100) return tens[Math.floor(n / 10)] + (n % 10 ? ' ' + ones[n % 10] : '');
    if (n < 1000) return ones[Math.floor(n / 100)] + ' Hundred' + (n % 100 ? ' ' + numToWords(n % 100) : '');
    if (n < 100000) return numToWords(Math.floor(n / 1000)) + ' Thousand' + (n % 1000 ? ' ' + numToWords(n % 1000) : '');
    if (n < 10000000) return numToWords(Math.floor(n / 100000)) + ' Lakh' + (n % 100000 ? ' ' + numToWords(n % 100000) : '');
    return numToWords(Math.floor(n / 10000000)) + ' Crore' + (n % 10000000 ? ' ' + numToWords(n % 10000000) : '');
  };

  const rupees = Math.floor(amount);
  const paise = Math.round((amount - rupees) * 100);

  let words = 'Rupees ' + numToWords(rupees);
  if (paise > 0) words += ' and ' + numToWords(paise) + ' Paise';
  words += ' Only';
  return words;
};

module.exports = {
  getSupplyType,
  calculateLineItemGST,
  calculateBillTotals,
  getHSNSummary,
  isValidGSTRate,
  validateGSTIN,
  validatePAN,
  getStateCodeFromGSTIN,
  amountToWords,
  round2,
};
