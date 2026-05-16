const nodemailer = require('nodemailer');
const logger = require('./logger');

// Create a transporter using environment variables or fallback to generic SMTP settings
let transporter;

const initializeTransporter = async () => {
  if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
    // Generate a test ethereal account for local development if no SMTP is provided
    const testAccount = await nodemailer.createTestAccount();
    transporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: testAccount.user, // generated ethereal user
        pass: testAccount.pass, // generated ethereal password
      },
    });
    logger.info('Ethereal Mail (Test Account) initialized for development emails.');
  } else {
    // Production / Configured SMTP
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }
};

initializeTransporter();

const { getOTPEmailTemplate } = require('../templates/emails/otpTemplate');

/**
 * Send an OTP via Email
 */
const sendOTPEmail = async (email, otp, purpose = 'registration') => {
  try {
    const purposeStr = purpose === 'registration' ? 'creating your account' :
      purpose === 'login' ? 'logging into your account' :
        'verifying your request';
    const expiryMinutes = process.env.OTP_EXPIRY_MINUTES || 10;

    const info = await transporter.sendMail({
      from: `"BillPro Team" <${process.env.EMAIL_FROM || 'noreply@billpro.in'}>`,
      to: email,
      subject: `${otp} is your BillPro Verification Code`,
      html: getOTPEmailTemplate(otp, purposeStr, expiryMinutes),
    });

    if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
      logger.info(`[DEV] Email sent to ${email}. Preview URL: ${nodemailer.getTestMessageUrl(info)}`);
    } else {
      logger.info(`Email OTP sent to ${email}`);
    }
    
    return true;
  } catch (err) {
    logger.error('Failed to send email OTP:', err);
    return false;
  }
};

module.exports = { sendOTPEmail };
