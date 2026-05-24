const crypto = require('crypto');
const { setOTP, getOTP, deleteOTP } = require('../config/redis');
const logger = require('./logger');

/**
 * Generate a cryptographically secure OTP
 */
const generateOTP = (length = 6) => {
  const digits = '0123456789';
  const bytes = crypto.randomBytes(length);
  return Array.from(bytes, (b) => digits[b % 10]).join('');
};

/**
 * Store OTP in Redis with expiry
 */
const storeOTP = async (identifier, purpose = 'verify') => {
  const otp = generateOTP(parseInt(process.env.OTP_LENGTH) || 6);
  const expirySeconds = (parseInt(process.env.OTP_EXPIRY_MINUTES) || 10) * 60;
  const key = `${purpose}:${identifier}`;
  await setOTP(key, otp, expirySeconds);
  logger.info(`OTP generated for ${purpose}:${identifier}`);
  return otp;
};

/**
 * Verify OTP — single-use, deleted on match
 */
const verifyOTP = async (identifier, otp, purpose = 'verify') => {
  const key = `${purpose}:${identifier}`;
  const stored = await getOTP(key);
  if (!stored) return { valid: false, reason: 'OTP expired or not found' };
  if (stored !== otp) return { valid: false, reason: 'Invalid OTP' };
  await deleteOTP(key);
  return { valid: true };
};

/**
 * Send OTP via SMS (MSG91)
 */
const sendOTPViaSMS = async (mobile, otp) => {
  if (process.env.NODE_ENV === 'development') {
    logger.info(`[DEV] SMS OTP for ${mobile}: ${otp}`);
    return true;
  }

  try {
    const axios = require('axios');
    await axios.get('https://api.msg91.com/api/sendotp.php', {
      params: {
        authkey: process.env.MSG91_AUTH_KEY,
        mobile: `91${mobile}`,
        message: `Your BillQube OTP is ${otp}. Valid for ${process.env.OTP_EXPIRY_MINUTES || 10} minutes.`,
        sender: process.env.MSG91_SENDER_ID,
        otp,
        template_id: process.env.MSG91_TEMPLATE_ID,
      },
    });
    return true;
  } catch (err) {
    logger.error('SMS OTP send failed:', err.message);
    return false;
  }
};

module.exports = { generateOTP, storeOTP, verifyOTP, sendOTPViaSMS };
