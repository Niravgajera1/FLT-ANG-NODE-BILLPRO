const {
  calculateLineItemGST,
  calculateBillTotals,
  validateGSTIN,
  validatePAN,
  getSupplyType,
  amountToWords,
} = require('../../src/utils/gstCalculator');

const { SUPPLY_TYPES, GST_TYPES } = require('../../src/config/constants');

describe('GST Calculator', () => {

  describe('calculateLineItemGST — Intra-state', () => {
    it('should split tax 50/50 into CGST and SGST for intra-state', () => {
      const result = calculateLineItemGST({
        quantity: 1, unitPrice: 1000, gstRate: 18,
        supplyType: SUPPLY_TYPES.INTRA_STATE,
      });
      expect(result.cgst).toBe(90);
      expect(result.sgst).toBe(90);
      expect(result.igst).toBe(0);
      expect(result.totalTax).toBe(180);
      expect(result.lineTotal).toBe(1180);
    });

    it('should apply IGST only for inter-state', () => {
      const result = calculateLineItemGST({
        quantity: 1, unitPrice: 1000, gstRate: 18,
        supplyType: SUPPLY_TYPES.INTER_STATE,
      });
      expect(result.cgst).toBe(0);
      expect(result.sgst).toBe(0);
      expect(result.igst).toBe(180);
      expect(result.totalTax).toBe(180);
    });

    it('should return zero tax for export invoices', () => {
      const result = calculateLineItemGST({
        quantity: 2, unitPrice: 500, gstRate: 12,
        supplyType: SUPPLY_TYPES.EXPORT,
      });
      expect(result.cgst).toBe(0);
      expect(result.igst).toBe(0);
      expect(result.totalTax).toBe(0);
      expect(result.lineTotal).toBe(1000);
    });
  });

  describe('calculateLineItemGST — Discounts', () => {
    it('should apply percentage discount before GST', () => {
      const result = calculateLineItemGST({
        quantity: 1, unitPrice: 1000, discountPercent: 10, gstRate: 18,
        supplyType: SUPPLY_TYPES.INTRA_STATE,
      });
      expect(result.taxableValue).toBe(900);
      expect(result.cgst).toBe(81);
      expect(result.sgst).toBe(81);
      expect(result.lineTotal).toBe(1062);
    });

    it('should apply flat discount', () => {
      const result = calculateLineItemGST({
        quantity: 1, unitPrice: 1000, discountFlat: 100, gstRate: 18,
        supplyType: SUPPLY_TYPES.INTRA_STATE,
      });
      expect(result.taxableValue).toBe(900);
      expect(result.totalTax).toBe(162);
    });

    it('should apply both percentage and flat discount', () => {
      const result = calculateLineItemGST({
        quantity: 1, unitPrice: 1000, discountPercent: 10, discountFlat: 50, gstRate: 18,
        supplyType: SUPPLY_TYPES.INTRA_STATE,
      });
      expect(result.discountAmount).toBe(150);
      expect(result.taxableValue).toBe(850);
    });
  });

  describe('calculateLineItemGST — Quantity', () => {
    it('should multiply correctly for quantity > 1', () => {
      const result = calculateLineItemGST({
        quantity: 5, unitPrice: 200, gstRate: 5,
        supplyType: SUPPLY_TYPES.INTRA_STATE,
      });
      expect(result.grossValue).toBe(1000);
      expect(result.taxableValue).toBe(1000);
      expect(result.totalTax).toBe(50);
      expect(result.lineTotal).toBe(1050);
    });
  });

  describe('calculateBillTotals', () => {
    it('should sum all line items correctly', () => {
      const items = [
        calculateLineItemGST({ quantity: 1, unitPrice: 1000, gstRate: 18, supplyType: SUPPLY_TYPES.INTRA_STATE }),
        calculateLineItemGST({ quantity: 2, unitPrice: 500,  gstRate: 12, supplyType: SUPPLY_TYPES.INTRA_STATE }),
      ];
      const totals = calculateBillTotals(items);
      expect(totals.subTotal).toBe(2000);
      expect(totals.totalTaxableValue).toBe(2000);
      expect(totals.totalCGST).toBe(90 + 60);
      expect(totals.totalSGST).toBe(90 + 60);
      expect(totals.grandTotal).toBe(2000 + 180 + 120);
    });
  });

  describe('validateGSTIN', () => {
    it('should validate a correct GSTIN', () => {
      expect(validateGSTIN('27AAAAA0000A1Z5')).toBe(true);
      expect(validateGSTIN('29ABCDE1234F1Z5')).toBe(true);
    });
    it('should reject invalid GSTINs', () => {
      expect(validateGSTIN('INVALID')).toBe(false);
      expect(validateGSTIN('123456789012345')).toBe(false);
      expect(validateGSTIN('')).toBe(false);
      expect(validateGSTIN(null)).toBe(false);
    });
  });

  describe('validatePAN', () => {
    it('should validate correct PAN', () => {
      expect(validatePAN('ABCDE1234F')).toBe(true);
    });
    it('should reject invalid PAN', () => {
      expect(validatePAN('ABCD1234F')).toBe(false);
      expect(validatePAN('abcde1234f')).toBe(false);
    });
  });

  describe('amountToWords', () => {
    it('should convert amounts correctly', () => {
      expect(amountToWords(1000)).toBe('Rupees One Thousand Only');
      expect(amountToWords(100000)).toBe('Rupees One Lakh Only');
      expect(amountToWords(1000000)).toBe('Rupees Ten Lakh Only');
      expect(amountToWords(10000000)).toBe('Rupees One Crore Only');
      expect(amountToWords(1180.50)).toContain('Fifty Paise');
    });
  });

});
