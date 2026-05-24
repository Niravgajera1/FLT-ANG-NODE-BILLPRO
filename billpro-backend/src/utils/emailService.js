const nodemailer = require('nodemailer');
const axios = require('axios');
const logger = require('./logger');

// Create a transporter using environment variables or fallback to generic SMTP settings
let transporter;

const initializeTransporter = async () => {
  try {
    const hasPass = !!process.env.SMTP_PASS;
    logger.info('Initializing mail transporter...', {
      SMTP_HOST: process.env.SMTP_HOST,
      SMTP_PORT: process.env.SMTP_PORT,
      SMTP_SECURE: process.env.SMTP_SECURE,
      SMTP_USER: process.env.SMTP_USER,
      EMAIL_FROM: process.env.EMAIL_FROM,
      EMAIL_FROM_NAME: process.env.EMAIL_FROM_NAME,
      hasPasswordConfigured: hasPass,
      NODE_ENV: process.env.NODE_ENV
    });

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
      logger.info(`SMTP transporter successfully initialized for host: ${process.env.SMTP_HOST}`);
    } else {
      logger.warn('SMTP_HOST environment variable is not defined, and NODE_ENV is not development. Mail transporter will remain uninitialized!');
    }
  } catch (err) {
    logger.error('Failed to initialize local/fallback SMTP transporter:', {
      error: err.message,
      stack: err.stack
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
    const expiryMinutes = process.env.OTP_EXPIRY_MINUTES || 10;

    // Select custom subject line based on purpose
    const subject = purpose === 'registration' ? `${otp} is your BillQube verification code` :
      purpose === 'login' ? `${otp} is your BillQube login code` :
        purpose === 'password_reset' ? `${otp} is your BillQube password reset code` :
          `${otp} is your BillQube code`;

    const htmlContent = getOTPEmailTemplate(otp, purpose, expiryMinutes);
    const fromName = process.env.EMAIL_FROM_NAME || 'BillQube Team';
    const fromEmail = process.env.EMAIL_FROM || 'noreply@billqube.in';

    // 1. Check if HTTP API Provider is configured (Highly recommended to bypass SMTP port blocks on Render Free tier)
    const apiProvider = (process.env.EMAIL_API_PROVIDER || '').toLowerCase();

    if (apiProvider === 'resend' || process.env.RESEND_API_KEY) {
      const apiKey = process.env.RESEND_API_KEY;
      if (!apiKey) {
        throw new Error('Resend API key is missing (RESEND_API_KEY).');
      }
      logger.info(`Sending OTP email to ${email} via Resend HTTP API...`);

      const response = await axios.post('https://api.resend.com/emails', {
        from: `"${fromName}" <${fromEmail}>`,
        to: [email],
        subject,
        html: htmlContent
      }, {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      logger.info(`Email successfully sent to ${email} via Resend HTTP API. ID: ${response.data.id}`);
      return true;
    }

    if (apiProvider === 'brevo' || process.env.BREVO_API_KEY) {
      const apiKey = process.env.BREVO_API_KEY;
      if (!apiKey) {
        throw new Error('Brevo API key is missing (BREVO_API_KEY).');
      }
      logger.info(`Sending OTP email to ${email} via Brevo HTTP API...`);

      const response = await axios.post('https://api.brevo.com/v3/smtp/email', {
        sender: { name: fromName, email: fromEmail },
        to: [{ email }],
        subject,
        htmlContent: htmlContent
      }, {
        headers: {
          'api-key': apiKey,
          'Content-Type': 'application/json'
        }
      });

      logger.info(`Email successfully sent to ${email} via Brevo HTTP API. Message ID: ${response.data.messageId}`);
      return true;
    }

    // 2. Fallback to standard SMTP / Nodemailer (Note: fails on Render Free tier due to network block)
    if (!transporter) {
      throw new Error('SMTP transporter is not initialized and no HTTP API provider is configured.');
    }

    logger.info(`Sending OTP email to ${email} via standard SMTP...`);
    // Send standard SMTP email using Nodemailer
    const info = await transporter.sendMail({
      from: `"${fromName}" <${fromEmail}>`,
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
    const httpResponseData = err.response?.data;
    logger.error('Failed to send email OTP:', {
      errorMessage: err.message,
      httpResponse: httpResponseData,
      stack: err.stack,
      smtpCode: err.code,
      smtpResponseCode: err.responseCode,
      smtpCommand: err.command,
      smtpResponse: err.response,
      recipientEmail: email,
      otpPurpose: purpose
    });
    return false;
  }
};

module.exports = { sendOTPEmail };
