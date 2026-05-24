const nodemailer = require('nodemailer');
const logger = require('./logger');

// Create a transporter using environment variables or fallback to generic SMTP settings
let transporter;

const initializeTransporter = async () => {
  try {
    if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
      // Generate a test ethereal account for local development if no SMTP is provided
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
      logger.info('Ethereal Mail (Test Account) initialized for development emails.');
    } else if (process.env.SMTP_HOST) {
      // Production / Configured SMTP
      transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT, 10) || 587,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
      logger.info('SMTP transporter successfully initialized.');
    }
  } catch (err) {
    logger.warn('Failed to initialize local/fallback SMTP transporter:', err.message);
  }
};

initializeTransporter();

const { getOTPEmailTemplate } = require('../templates/emails/otpTemplate');

/**
 * Send an OTP via Email
 */
const sendOTPEmail = async (email, otp, purpose = 'registration') => {
  try {
    const expiryMinutes = process.env.OTP_EXPIRY_MINUTES || 10;

    // Select custom subject line based on purpose
    const subject = purpose === 'registration' ? `${otp} is your BillQube verification code` :
      purpose === 'login' ? `${otp} is your BillQube login code` :
        purpose === 'password_reset' ? `${otp} is your BillQube password reset code` :
          `${otp} is your BillQube code`;

    const htmlContent = getOTPEmailTemplate(otp, purpose, expiryMinutes);

    if (!transporter) {
      throw new Error('SMTP transporter is not initialized.');
    }

    // Send standard SMTP email using Nodemailer
    const info = await transporter.sendMail({
      from: `"${process.env.EMAIL_FROM_NAME || 'BillQube Team'}" <${process.env.EMAIL_FROM || 'noreply@billqube.in'}>`,
      to: email,
      subject,
      html: htmlContent,
    });

    if (process.env.NODE_ENV === 'development' && !process.env.SMTP_HOST) {
      logger.info(`[DEV] Email sent to ${email}. Preview URL: ${nodemailer.getTestMessageUrl(info)}`);
    } else {
      logger.info(`Email OTP sent to ${email} via Nodemailer`);
    }

    return true;
  } catch (err) {
    logger.error('Failed to send email OTP:', err.message || err);
    return false;
  }
};

module.exports = { sendOTPEmail };
