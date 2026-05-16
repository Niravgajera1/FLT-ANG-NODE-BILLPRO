const mongoose = require('mongoose');
const dayjs = require('dayjs');

/**
 * Counter schema for generating sequential bill numbers per financial year
 */
const counterSchema = new mongoose.Schema({
  _id: { type: String, required: true },  // e.g., "PB_2025-26_company123"
  seq: { type: Number, default: 0 },
}, { timestamps: false });

const Counter = mongoose.model('Counter', counterSchema);

/**
 * Get current financial year string based on company's FY start month
 * Default: April (Indian FY)
 * @param {number} fyStartMonth - 1=Jan, 4=April (default)
 * @returns {string} e.g., "2025-26"
 */
const getFinancialYear = (fyStartMonth = 4) => {
  const now = dayjs();
  const currentMonth = now.month() + 1; // dayjs months are 0-indexed
  const currentYear = now.year();

  let fyStartYear;
  if (currentMonth >= fyStartMonth) {
    fyStartYear = currentYear;
  } else {
    fyStartYear = currentYear - 1;
  }

  const fyEndYear = String(fyStartYear + 1).slice(-2);
  return `${fyStartYear}-${fyEndYear}`;
};

/**
 * Generate the next sequential bill number for a given module and company
 * @param {string} companyId
 * @param {string} prefix        - e.g., "PB", "INV", "CN", "DN"
 * @param {number} fyStartMonth  - Company's financial year start month (1-12)
 * @param {string} customPrefix  - Optional custom prefix configured by company
 * @returns {Promise<string>} e.g., "INV-2025-26-0001"
 */
const generateBillNumber = async (companyId, prefix, fyStartMonth = 4, customPrefix = null) => {
  const fy = getFinancialYear(fyStartMonth);
  const counterId = `${prefix}_${fy}_${companyId}`;

  const counter = await Counter.findByIdAndUpdate(
    counterId,
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );

  const paddedSeq = String(counter.seq).padStart(4, '0');
  const actualPrefix = customPrefix || prefix;
  return `${actualPrefix}-${fy}-${paddedSeq}`;
};

/**
 * Reset counter for a new FY (called by scheduled job)
 */
const resetFYCounters = async (companyId) => {
  const oldFY = getFinancialYear(); // Will work if called at year boundary
  const prefixes = ['PB', 'INV', 'CN', 'DN', 'EWB', 'QT', 'DC'];
  const deleteIds = prefixes.map(p => `${p}_${oldFY}_${companyId}`);
  await Counter.deleteMany({ _id: { $in: deleteIds } });
};

module.exports = { generateBillNumber, getFinancialYear, resetFYCounters };
