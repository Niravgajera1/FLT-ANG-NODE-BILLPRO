const nodemailer = require('nodemailer');
const axios = require('axios');
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
    }
  } catch (err) {
    logger.error('Failed to initialize nodemailer transporter:', err);
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

    // If Resend API Key is configured, use the Resend HTTP API (avoids Render SMTP port blocking)
    if (process.env.RESEND_API_KEY) {
      const fromEmail = process.env.EMAIL_FROM || 'onboarding@resend.dev';
      const fromName = process.env.EMAIL_FROM_NAME || 'BillPro';

      await axios.post(
        'https://api.resend.com/emails',
        {
          from: `"${fromName}" <${fromEmail}>`,
          to: [email],
          subject,
          html: htmlContent,
        },
        {
          headers: {
            Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );

      logger.info(`Email OTP sent to ${email} via Resend`);
      return true;
    }

    // Fallback: SMTP / Nodemailer
    if (!transporter) {
      throw new Error('Nodemailer transporter is not initialized and RESEND_API_KEY is not set');
    }

    const info = await transporter.sendMail({
      from: `"BillPro Team" <${process.env.EMAIL_FROM || 'noreply@billpro.in'}>`,
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
    logger.error('Failed to send email OTP:', err);
    return false;
  }
};

module.exports = { sendOTPEmail };
