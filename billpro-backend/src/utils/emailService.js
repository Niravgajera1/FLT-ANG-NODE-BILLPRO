const nodemailer = require('nodemailer');
const axios = require('axios');
const logger = require('./logger');

// Create a transporter using environment variables or fallback to generic SMTP settings
let transporter;

const initializeTransporter = async () => {
  if (process.env.BREVO_API_KEY) {
    logger.info('Brevo HTTPS REST API configured. SMTP transporter initialization skipped.');
    return;
  }

  try {
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
    } else if (process.env.SMTP_HOST) {
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
    const subject = purpose === 'registration' ? `${otp} is your BillPro verification code` :
      purpose === 'login' ? `${otp} is your BillPro login code` :
      purpose === 'password_reset' ? `${otp} is your BillPro password reset code` :
      `${otp} is your BillPro code`;

    const htmlContent = getOTPEmailTemplate(otp, purpose, expiryMinutes);

    // If Brevo API Key is configured, use Brevo REST API (HTTPS port 443)
    if (process.env.BREVO_API_KEY) {
      const response = await axios.post('https://api.brevo.com/v3/smtp/email', {
        sender: {
          name: process.env.EMAIL_FROM_NAME || "BillPro Team",
          email: process.env.EMAIL_FROM || "noreply@billpro.in"
        },
        to: [
          {
            email: email
          }
        ],
        subject: subject,
        htmlContent: htmlContent
      }, {
        headers: {
          'api-key': process.env.BREVO_API_KEY,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });

      logger.info(`Email OTP successfully sent to ${email} via Brevo REST API. Message ID: ${response.data.messageId}`);
      return true;
    }

    if (!transporter) {
      throw new Error('SMTP transporter is not initialized.');
    }

    // Fallback to standard Nodemailer transport (for local Ethereal dev or production SMTP)
    const info = await transporter.sendMail({
      from: `"${process.env.EMAIL_FROM_NAME || 'BillPro Team'}" <${process.env.EMAIL_FROM || 'noreply@billpro.in'}>`,
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
    if (err.response) {
      logger.error('Failed to send email OTP via Brevo REST API:', {
        message: err.message,
        data: err.response.data
      });
    } else {
      logger.error('Failed to send email OTP:', err.message || err);
    }
    return false;
  }
};

module.exports = { sendOTPEmail };
